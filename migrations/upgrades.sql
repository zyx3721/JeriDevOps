-- 项目名称：devops
-- 文件名称：upgrades.sql
-- 作　　者：Jerion
-- 联系邮箱：416685476@qq.com
-- 功能描述：存量数据库升级补丁（仅对已有数据库执行，全新部署请使用 init_tables.sql）
-- 执行顺序：按章节顺序依次执行

-- ============================================
-- 1. 飞书相关补丁
-- ============================================

-- feishu_apps 补充 webhook 列（如列已存在可忽略报错）
ALTER TABLE `feishu_apps`
ADD COLUMN `webhook` varchar(500) DEFAULT '' COMMENT 'Webhook URL' AFTER `app_secret`;

-- 飞书消息发送记录表
CREATE TABLE IF NOT EXISTS `feishu_message_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `msg_type` varchar(50) NOT NULL COMMENT '消息类型: text/post/interactive',
  `receive_id` varchar(100) NOT NULL COMMENT '接收者ID',
  `receive_id_type` varchar(50) NOT NULL COMMENT 'ID类型: chat_id/open_id/user_id',
  `content` text COMMENT '消息内容',
  `title` varchar(200) DEFAULT '' COMMENT '卡片标题',
  `source` varchar(50) DEFAULT '' COMMENT '来源: manual/oa_sync',
  `status` varchar(20) DEFAULT 'success' COMMENT '状态: success/failed',
  `error_msg` text COMMENT '错误信息',
  `app_id` bigint unsigned DEFAULT NULL COMMENT '使用的飞书应用ID',
  PRIMARY KEY (`id`),
  KEY `idx_fml_msg_type` (`msg_type`),
  KEY `idx_fml_source` (`source`),
  KEY `idx_fml_status` (`status`),
  KEY `idx_fml_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书消息发送记录';

-- 飞书用户令牌表
CREATE TABLE IF NOT EXISTS `feishu_user_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `app_id` varchar(100) NOT NULL COMMENT '飞书 App ID',
  `access_token` text COMMENT '访问令牌',
  `refresh_token` text COMMENT '刷新令牌',
  `expires_at` datetime(3) DEFAULT NULL COMMENT '过期时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_fut_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书用户OAuth令牌';


-- ============================================
-- 2. 流水线模板补丁（fix_pipeline_templates_columns.sql）
-- ============================================

-- 检查并添加 language 列
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'pipeline_templates'
  AND COLUMN_NAME = 'language';
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE pipeline_templates ADD COLUMN language VARCHAR(50) COMMENT \'编程语言: java, go, nodejs, python\' AFTER category',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 检查并添加 framework 列
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'pipeline_templates'
  AND COLUMN_NAME = 'framework';
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE pipeline_templates ADD COLUMN framework VARCHAR(50) COMMENT \'框架: spring, gin, express, django\' AFTER language',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 检查并添加 idx_language 索引
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'pipeline_templates'
  AND INDEX_NAME = 'idx_language';
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE pipeline_templates ADD INDEX idx_language (language)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================
-- 3. 负载均衡 hash_key 字段修复（fix_loadbalance_hash_key.sql）
-- ============================================

ALTER TABLE `traffic_loadbalance_config`
MODIFY COLUMN `hash_key` VARCHAR(20) DEFAULT NULL COMMENT '哈希键类型(header/cookie/source_ip/query_param)';

-- ============================================
-- 4. 制品仓库监控补丁（artifact_registry_monitoring.sql）
-- ============================================

-- 为 artifact_repositories 添加监控字段（如列已存在可忽略报错）
ALTER TABLE `artifact_repositories`
ADD COLUMN `connection_status` varchar(20) DEFAULT 'unknown' COMMENT '连接状态: connected/disconnected/checking/unknown' AFTER `enabled`,
ADD COLUMN `last_check_at` datetime(3) DEFAULT NULL COMMENT '最后检查时间' AFTER `connection_status`,
ADD COLUMN `last_error` text COMMENT '最后错误信息' AFTER `last_check_at`,
ADD COLUMN `enable_monitoring` tinyint(1) DEFAULT 1 COMMENT '是否启用监控' AFTER `last_error`,
ADD COLUMN `check_interval` int DEFAULT 300 COMMENT '检查间隔(秒)' AFTER `enable_monitoring`;

CREATE INDEX IF NOT EXISTS `idx_connection_status` ON `artifact_repositories`(`connection_status`);
CREATE INDEX IF NOT EXISTS `idx_enable_monitoring` ON `artifact_repositories`(`enable_monitoring`);

-- 创建统计视图
CREATE OR REPLACE VIEW `v_registry_connection_stats` AS
SELECT
  ar.id, ar.name, ar.type, ar.connection_status,
  ar.last_check_at, ar.enable_monitoring,
  COUNT(CASE WHEN arch.status = 'ok' THEN 1 END) AS success_count,
  COUNT(CASE WHEN arch.status = 'error' THEN 1 END) AS failed_count,
  ROUND(COUNT(CASE WHEN arch.status = 'ok' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS success_rate,
  AVG(arch.latency_ms) AS avg_response_time
FROM `artifact_repositories` ar
LEFT JOIN `artifact_registry_connection_history` arch
  ON ar.id = arch.registry_id
  AND arch.check_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY ar.id, ar.name, ar.type, ar.connection_status, ar.last_check_at, ar.enable_monitoring;

-- 触发器：连接状态变化时自动记录历史
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS `after_registry_status_update`
AFTER UPDATE ON `artifact_repositories`
FOR EACH ROW
BEGIN
  IF OLD.connection_status != NEW.connection_status THEN
    INSERT INTO `artifact_registry_connection_history` (
      `registry_id`, `status`, `message`, `check_time`
    ) VALUES (
      NEW.id,
      CASE WHEN NEW.connection_status = 'connected' THEN 'ok' ELSE 'error' END,
      NEW.last_error,
      NEW.last_check_at
    );
  END IF;
END$$

-- 定期清理连接历史（保留最近 30 天）
CREATE EVENT IF NOT EXISTS `cleanup_registry_connection_history`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
  DELETE FROM `artifact_registry_connection_history`
  WHERE `check_time` < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

DELIMITER ;

-- ============================================
-- 5. 告警日志静默字段补丁（add_log_alert_silence_fields.sql）
-- ============================================

-- 为 log_alert_history 添加静默字段（如列已存在可忽略报错）
ALTER TABLE `log_alert_history`
ADD COLUMN `silenced` tinyint(1) DEFAULT 0 COMMENT '是否被静默';

ALTER TABLE `log_alert_history`
ADD COLUMN `silence_id` int unsigned DEFAULT NULL COMMENT '静默规则ID';

CREATE INDEX IF NOT EXISTS `idx_log_alert_history_silenced` ON `log_alert_history`(`silenced`);
CREATE INDEX IF NOT EXISTS `idx_log_alert_history_silence_id` ON `log_alert_history`(`silence_id`);

-- ============================================
-- 6. system_configs 补充 deleted_at 字段
-- ============================================

ALTER TABLE `system_configs`
ADD COLUMN `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;

CREATE INDEX IF NOT EXISTS `idx_sc_deleted_at` ON `system_configs`(`deleted_at`);

-- ============================================
-- 7. message_templates 补充 deleted_at 字段
-- ============================================

ALTER TABLE `message_templates`
ADD COLUMN `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间' AFTER `updated_at`;

CREATE INDEX IF NOT EXISTS `idx_mt_deleted_at` ON `message_templates`(`deleted_at`);

-- ============================================
-- 8. message_templates 列名与 Go 模型对齐
-- ============================================

-- 将 msg_type 重命名为 type
ALTER TABLE `message_templates`
  CHANGE COLUMN `msg_type` `type` varchar(50) NOT NULL DEFAULT 'text' COMMENT '模板类型: text/markdown/card';

-- 添加 is_active 字段
ALTER TABLE `message_templates`
  ADD COLUMN `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否激活' AFTER `description`;

-- 删除不再使用的字段（platform / title / variables）
ALTER TABLE `message_templates`
  DROP COLUMN IF EXISTS `platform`,
  DROP COLUMN IF EXISTS `title`,
  DROP COLUMN IF EXISTS `variables`;

-- 修正 created_by 允许 NULL（模型为 *uint）
ALTER TABLE `message_templates`
  MODIFY COLUMN `created_by` bigint unsigned DEFAULT NULL;

-- ============================================
-- 9. 数据库表结构与 Go Model 一致性修复补丁
-- ============================================
-- 注意：以下补丁已合并到 init_tables.sql（2026-04-14）
-- 全新部署无需执行此节，仅对存量数据库执行

-- 9.1 修复 k8s_clusters 表字段
ALTER TABLE `k8s_clusters`
  DROP COLUMN IF EXISTS `api_server`,
  DROP COLUMN IF EXISTS `token`,
  DROP COLUMN IF EXISTS `ca_cert`;

ALTER TABLE `k8s_clusters`
  ADD COLUMN IF NOT EXISTS `namespace` varchar(100) DEFAULT 'default' NOT NULL COMMENT '默认命名空间' AFTER `kubeconfig`,
  ADD COLUMN IF NOT EXISTS `registry` varchar(500) DEFAULT '' COMMENT '镜像仓库地址' AFTER `namespace`,
  ADD COLUMN IF NOT EXISTS `repository` varchar(200) DEFAULT '' COMMENT '镜像仓库名称' AFTER `registry`,
  ADD COLUMN IF NOT EXISTS `insecure_skip_tls` tinyint(1) DEFAULT 0 COMMENT '跳过 TLS 证书验证' AFTER `is_default`,
  ADD COLUMN IF NOT EXISTS `check_timeout` int DEFAULT 180 NOT NULL COMMENT '健康检查超时时间(秒)' AFTER `insecure_skip_tls`,
  ADD COLUMN IF NOT EXISTS `updated_by` bigint unsigned DEFAULT NULL COMMENT '更新者ID' AFTER `created_by`;

CREATE INDEX IF NOT EXISTS `idx_k8s_updated_by` ON `k8s_clusters`(`updated_by`);

-- 9.2 重建 feishu_requests 表
DROP TABLE IF EXISTS `feishu_requests`;
CREATE TABLE `feishu_requests` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `request_id` varchar(100) NOT NULL COMMENT '请求ID',
  `original_request` text COMMENT '原始请求内容',
  `disabled_actions` text COMMENT '禁用的操作',
  `action_counts` text COMMENT '操作计数',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_fr_request_id` (`request_id`),
  KEY `idx_fr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书请求记录';

-- 9.3 修复 application_envs 表
ALTER TABLE `application_envs`
  CHANGE COLUMN `env` `env_name` varchar(50) NOT NULL COMMENT '环境名称';

ALTER TABLE `application_envs`
  DROP COLUMN IF EXISTS `jenkins_instance_id`,
  DROP COLUMN IF EXISTS `k8s_cluster_id`;

ALTER TABLE `application_envs`
  ADD COLUMN IF NOT EXISTS `branch` varchar(100) DEFAULT '' COMMENT 'Git 分支' AFTER `env_name`;

-- 9.4 修复 artifact_repositories 表
ALTER TABLE `artifact_repositories`
  DROP COLUMN IF EXISTS `check_status`,
  DROP COLUMN IF EXISTS `check_message`,
  DROP COLUMN IF EXISTS `check_latency_ms`,
  DROP COLUMN IF EXISTS `total_images`,
  DROP COLUMN IF EXISTS `total_size_bytes`;

ALTER TABLE `artifact_repositories`
  ADD COLUMN IF NOT EXISTS `connection_status` varchar(20) DEFAULT 'unknown' COMMENT '连接状态' AFTER `enabled`,
  ADD COLUMN IF NOT EXISTS `last_error` text COMMENT '最后错误信息' AFTER `last_check_at`,
  ADD COLUMN IF NOT EXISTS `enable_monitoring` tinyint(1) DEFAULT 1 COMMENT '是否启用监控' AFTER `last_error`,
  ADD COLUMN IF NOT EXISTS `check_interval` int DEFAULT 300 COMMENT '检查间隔(秒)' AFTER `enable_monitoring`;

CREATE INDEX IF NOT EXISTS `idx_connection_status` ON `artifact_repositories`(`connection_status`);
CREATE INDEX IF NOT EXISTS `idx_enable_monitoring` ON `artifact_repositories`(`enable_monitoring`);

-- 9.5 修复 artifacts 表字段名
ALTER TABLE `artifacts`
  CHANGE COLUMN `download_cnt` `download_count` bigint DEFAULT 0 COMMENT '下载次数',
  CHANGE COLUMN `latest_version` `latest_ver` varchar(100) DEFAULT NULL COMMENT '最新版本';

-- 9.6 修复 artifact_versions 表字段名
ALTER TABLE `artifact_versions`
  CHANGE COLUMN `download_cnt` `download_count` bigint DEFAULT 0 COMMENT '下载次数';

-- 9.7 修复 alert_histories 表
ALTER TABLE `alert_histories`
  DROP COLUMN IF EXISTS `config_name`,
  DROP COLUMN IF EXISTS `target`,
  DROP COLUMN IF EXISTS `details`,
  DROP COLUMN IF EXISTS `notified`,
  DROP COLUMN IF EXISTS `notified_at`;

ALTER TABLE `alert_histories`
  ADD COLUMN IF NOT EXISTS `title` varchar(200) DEFAULT '' COMMENT '标题' AFTER `type`,
  ADD COLUMN IF NOT EXISTS `content` text COMMENT '内容' AFTER `title`,
  ADD COLUMN IF NOT EXISTS `level` varchar(20) DEFAULT 'warning' COMMENT '级别' AFTER `content`,
  ADD COLUMN IF NOT EXISTS `ack_status` varchar(20) DEFAULT 'pending' COMMENT '确认状态' AFTER `status`,
  ADD COLUMN IF NOT EXISTS `ack_by` bigint unsigned DEFAULT NULL COMMENT '确认人ID' AFTER `ack_status`,
  ADD COLUMN IF NOT EXISTS `ack_at` datetime(3) DEFAULT NULL COMMENT '确认时间' AFTER `ack_by`,
  ADD COLUMN IF NOT EXISTS `resolved_by` bigint unsigned DEFAULT NULL COMMENT '解决人ID' AFTER `ack_at`,
  ADD COLUMN IF NOT EXISTS `resolved_at` datetime(3) DEFAULT NULL COMMENT '解决时间' AFTER `resolved_by`,
  ADD COLUMN IF NOT EXISTS `resolve_comment` text COMMENT '解决备注' AFTER `resolved_at`,
  ADD COLUMN IF NOT EXISTS `silenced` tinyint(1) DEFAULT 0 COMMENT '是否被静默' AFTER `resolve_comment`,
  ADD COLUMN IF NOT EXISTS `silence_id` bigint unsigned DEFAULT NULL COMMENT '静默规则ID' AFTER `silenced`,
  ADD COLUMN IF NOT EXISTS `escalated` tinyint(1) DEFAULT 0 COMMENT '是否已升级' AFTER `silence_id`,
  ADD COLUMN IF NOT EXISTS `escalation_id` bigint unsigned DEFAULT NULL COMMENT '升级规则ID' AFTER `escalated`,
  ADD COLUMN IF NOT EXISTS `error_msg` text COMMENT '错误信息' AFTER `escalation_id`,
  ADD COLUMN IF NOT EXISTS `source_id` varchar(100) DEFAULT '' COMMENT '来源ID' AFTER `error_msg`,
  ADD COLUMN IF NOT EXISTS `source_url` varchar(500) DEFAULT '' COMMENT '来源URL' AFTER `source_id`;

-- 9.8 修复其他表
ALTER TABLE `dingtalk_bots`
  DROP COLUMN IF EXISTS `project`,
  DROP COLUMN IF EXISTS `message_template_id`;

CREATE INDEX IF NOT EXISTS `idx_wwb_created_by` ON `wechat_work_bots`(`created_by`);

ALTER TABLE `feishu_apps`
  MODIFY COLUMN `project` varchar(100) NOT NULL COMMENT '所属项目',
  MODIFY COLUMN `description` text COMMENT '描述',
  MODIFY COLUMN `status` varchar(20) NOT NULL COMMENT '状态: active/inactive';

ALTER TABLE `feishu_bots`
  MODIFY COLUMN `secret` varchar(100) DEFAULT '' COMMENT '签名密钥';

-- 9.9 创建缺失的流水线相关表
CREATE TABLE IF NOT EXISTS `pipeline_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `pipeline_id` bigint unsigned NOT NULL COMMENT '流水线ID',
  `run_number` int NOT NULL COMMENT '运行编号',
  `status` varchar(50) DEFAULT 'pending' COMMENT '状态: pending/running/success/failed/cancelled',
  `trigger_type` varchar(50) DEFAULT 'manual' COMMENT '触发类型: manual/webhook/schedule',
  `trigger_user` varchar(100) DEFAULT NULL COMMENT '触发用户',
  `start_time` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime(3) DEFAULT NULL COMMENT '结束时间',
  `duration` int DEFAULT 0 COMMENT '持续时间(秒)',
  PRIMARY KEY (`id`),
  KEY `idx_pr_pipeline_id` (`pipeline_id`),
  KEY `idx_pr_status` (`status`),
  KEY `idx_pr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水线运行记录';

CREATE TABLE IF NOT EXISTS `pipeline_variables` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `pipeline_id` bigint unsigned NOT NULL COMMENT '流水线ID',
  `key` varchar(100) NOT NULL COMMENT '变量名',
  `value` text COMMENT '变量值',
  `is_secret` tinyint(1) DEFAULT 0 COMMENT '是否为敏感信息',
  `description` text COMMENT '描述',
  PRIMARY KEY (`id`),
  KEY `idx_pv_pipeline_id` (`pipeline_id`),
  KEY `idx_pv_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水线变量';

CREATE TABLE IF NOT EXISTS `stage_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `pipeline_run_id` bigint unsigned NOT NULL COMMENT '流水线运行ID',
  `stage_name` varchar(100) NOT NULL COMMENT '阶段名称',
  `status` varchar(50) DEFAULT 'pending' COMMENT '状态',
  `start_time` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime(3) DEFAULT NULL COMMENT '结束时间',
  `duration` int DEFAULT 0 COMMENT '持续时间(秒)',
  PRIMARY KEY (`id`),
  KEY `idx_sr_pipeline_run_id` (`pipeline_run_id`),
  KEY `idx_sr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='阶段运行记录';

CREATE TABLE IF NOT EXISTS `step_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `stage_run_id` bigint unsigned NOT NULL COMMENT '阶段运行ID',
  `step_name` varchar(100) NOT NULL COMMENT '步骤名称',
  `status` varchar(50) DEFAULT 'pending' COMMENT '状态',
  `start_time` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime(3) DEFAULT NULL COMMENT '结束时间',
  `duration` int DEFAULT 0 COMMENT '持续时间(秒)',
  `logs` longtext COMMENT '日志',
  PRIMARY KEY (`id`),
  KEY `idx_sr_stage_run_id` (`stage_run_id`),
  KEY `idx_sr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='步骤运行记录';

CREATE TABLE IF NOT EXISTS `webhook_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `webhook_id` bigint unsigned NOT NULL COMMENT 'Webhook ID',
  `request_method` varchar(20) NOT NULL COMMENT '请求方法',
  `request_headers` text COMMENT '请求头',
  `request_body` longtext COMMENT '请求体',
  `response_status` int DEFAULT NULL COMMENT '响应状态码',
  `response_body` text COMMENT '响应体',
  `error_message` text COMMENT '错误信息',
  PRIMARY KEY (`id`),
  KEY `idx_wl_webhook_id` (`webhook_id`),
  KEY `idx_wl_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Webhook日志';

-- 9.2 为现有表添加缺失字段

-- alert_histories 表
ALTER TABLE `alert_histories` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_ah_deleted_at` ON `alert_histories`(`deleted_at`);

-- artifacts 表
ALTER TABLE `artifacts` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_artifacts_deleted_at` ON `artifacts`(`deleted_at`);

-- pipelines 表
ALTER TABLE `pipelines` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_pipelines_deleted_at` ON `pipelines`(`deleted_at`);

-- health_check_configs 表
ALTER TABLE `health_check_configs` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_hcc_deleted_at` ON `health_check_configs`(`deleted_at`);

-- health_check_histories 表
ALTER TABLE `health_check_histories` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_hch_deleted_at` ON `health_check_histories`(`deleted_at`);

-- app_retry_rules 表
ALTER TABLE `app_retry_rules` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_arr_deleted_at` ON `app_retry_rules`(`deleted_at`);

-- app_timeout_rules 表
ALTER TABLE `app_timeout_rules` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_atr_deleted_at` ON `app_timeout_rules`(`deleted_at`);

-- app_circuit_breaker_rules 表
ALTER TABLE `app_circuit_breaker_rules` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_acbr_deleted_at` ON `app_circuit_breaker_rules`(`deleted_at`);

-- app_rate_limit_rules 表
ALTER TABLE `app_rate_limit_rules` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_arlr_deleted_at` ON `app_rate_limit_rules`(`deleted_at`);

-- app_mirror_rules 表
ALTER TABLE `app_mirror_rules` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_amr_deleted_at` ON `app_mirror_rules`(`deleted_at`);

-- app_fault_rules 表
ALTER TABLE `app_fault_rules` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_afr_deleted_at` ON `app_fault_rules`(`deleted_at`);

-- cost_alerts 表
ALTER TABLE `cost_alerts` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_ca_deleted_at` ON `cost_alerts`(`deleted_at`);

-- cost_budgets 表
ALTER TABLE `cost_budgets` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_cb_deleted_at` ON `cost_budgets`(`deleted_at`);

-- cost_suggestions 表
ALTER TABLE `cost_suggestions` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_cs_deleted_at` ON `cost_suggestions`(`deleted_at`);

-- cost_summaries 表
ALTER TABLE `cost_summaries` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_cost_summaries_deleted_at` ON `cost_summaries`(`deleted_at`);

-- resource_costs 表
ALTER TABLE `resource_costs` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_rc_deleted_at` ON `resource_costs`(`deleted_at`);

-- resource_activities 表
ALTER TABLE `resource_activities` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_ra_deleted_at` ON `resource_activities`(`deleted_at`);

-- image_registries 表
ALTER TABLE `image_registries` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_ir_deleted_at` ON `image_registries`(`deleted_at`);

-- image_scans 表
ALTER TABLE `image_scans` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_is_deleted_at` ON `image_scans`(`deleted_at`);

-- security_audit_logs 表
ALTER TABLE `security_audit_logs` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_sal_deleted_at` ON `security_audit_logs`(`deleted_at`);

-- security_reports 表
ALTER TABLE `security_reports` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_sr_deleted_at` ON `security_reports`(`deleted_at`);

-- compliance_rules 表
ALTER TABLE `compliance_rules` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_cr_deleted_at` ON `compliance_rules`(`deleted_at`);

-- config_checks 表
ALTER TABLE `config_checks` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_cc_deleted_at` ON `config_checks`(`deleted_at`);

-- encryption_keys 表
ALTER TABLE `encryption_keys` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_ek_deleted_at` ON `encryption_keys`(`deleted_at`);

-- feishu_requests 表
ALTER TABLE `feishu_requests` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_fr_deleted_at` ON `feishu_requests`(`deleted_at`);

-- k8s_clusters 表
ALTER TABLE `k8s_clusters` ADD COLUMN IF NOT EXISTS `deleted_at` datetime(3) DEFAULT NULL COMMENT '软删除时间';
CREATE INDEX IF NOT EXISTS `idx_kc_deleted_at` ON `k8s_clusters`(`deleted_at`);

-- 9.10 补充缺失字段（2026-04-14）

-- health_check_configs 表补充字段
ALTER TABLE `health_check_configs`
  ADD COLUMN IF NOT EXISTS `last_status` varchar(20) DEFAULT 'unknown' COMMENT '最后检查状态' AFTER `enabled`,
  ADD COLUMN IF NOT EXISTS `last_checked_at` datetime(3) DEFAULT NULL COMMENT '最后检查时间' AFTER `last_status`;

CREATE INDEX IF NOT EXISTS `idx_hcc_last_status` ON `health_check_configs`(`last_status`);

-- resource_costs 表补充字段
ALTER TABLE `resource_costs`
  ADD COLUMN IF NOT EXISTS `total_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '总成本' AFTER `cost`,
  ADD COLUMN IF NOT EXISTS `cpu_request` decimal(10,2) DEFAULT 0.00 COMMENT 'CPU 请求量(核)' AFTER `cpu_cost`,
  ADD COLUMN IF NOT EXISTS `memory_request` decimal(10,2) DEFAULT 0.00 COMMENT '内存请求量(GB)' AFTER `memory_cost`;

-- cost_suggestions 表补充字段
ALTER TABLE `cost_suggestions`
  ADD COLUMN IF NOT EXISTS `savings` decimal(14,4) DEFAULT 0.0000 COMMENT '预计节省金额' AFTER `estimated_saving`;

-- cost_budgets 表补充字段
ALTER TABLE `cost_budgets`
  ADD COLUMN IF NOT EXISTS `monthly_budget` decimal(14,4) DEFAULT 0.0000 COMMENT '月度预算' AFTER `amount`,
  ADD COLUMN IF NOT EXISTS `current_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '当前花费' AFTER `monthly_budget`;

-- resource_activities 表补充字段
ALTER TABLE `resource_activities`
  ADD COLUMN IF NOT EXISTS `is_zombie` tinyint(1) DEFAULT 0 COMMENT '是否为僵尸资源' AFTER `operator`,
  ADD COLUMN IF NOT EXISTS `last_active_at` datetime(3) DEFAULT NULL COMMENT '最后活跃时间' AFTER `is_zombie`;

CREATE INDEX IF NOT EXISTS `idx_ra_is_zombie` ON `resource_activities`(`is_zombie`);

-- image_scans 表补充字段
ALTER TABLE `image_scans`
  ADD COLUMN IF NOT EXISTS `status` varchar(20) DEFAULT 'pending' COMMENT '扫描状态' AFTER `scan_status`;

CREATE INDEX IF NOT EXISTS `idx_is_status` ON `image_scans`(`status`);

-- config_checks 表补充字段
ALTER TABLE `config_checks`
  ADD COLUMN IF NOT EXISTS `critical_count` int DEFAULT 0 COMMENT '严重问题数' AFTER `status`,
  ADD COLUMN IF NOT EXISTS `high_count` int DEFAULT 0 COMMENT '高危问题数' AFTER `critical_count`,
  ADD COLUMN IF NOT EXISTS `medium_count` int DEFAULT 0 COMMENT '中危问题数' AFTER `high_count`,
  ADD COLUMN IF NOT EXISTS `low_count` int DEFAULT 0 COMMENT '低危问题数' AFTER `medium_count`,
  ADD COLUMN IF NOT EXISTS `passed_count` int DEFAULT 0 COMMENT '通过数' AFTER `low_count`;

CREATE INDEX IF NOT EXISTS `idx_cc_checked_at` ON `config_checks`(`checked_at`);

-- ============================================
-- 10. 修复 test.log 中的字段缺失问题（2026-04-14）
-- ============================================

-- 10.1 health_check_configs 表补充字段
ALTER TABLE `health_check_configs`
  ADD COLUMN IF NOT EXISTS `type` varchar(50) DEFAULT 'http' COMMENT '检查类型: http/tcp/ssl_cert/dns' AFTER `name`,
  ADD COLUMN IF NOT EXISTS `target_id` bigint unsigned DEFAULT 0 COMMENT '目标资源ID' AFTER `type`,
  ADD COLUMN IF NOT EXISTS `target_name` varchar(200) DEFAULT '' COMMENT '目标名称' AFTER `target_id`,
  ADD COLUMN IF NOT EXISTS `retry_count` int DEFAULT 3 COMMENT '重试次数' AFTER `timeout`,
  ADD COLUMN IF NOT EXISTS `alert_enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用告警' AFTER `enabled`,
  ADD COLUMN IF NOT EXISTS `alert_platform` varchar(50) DEFAULT '' COMMENT '告警平台' AFTER `alert_enabled`,
  ADD COLUMN IF NOT EXISTS `alert_bot_id` bigint unsigned DEFAULT NULL COMMENT '告警机器人ID' AFTER `alert_platform`,
  ADD COLUMN IF NOT EXISTS `last_check_at` datetime(3) DEFAULT NULL COMMENT '最后检查时间' AFTER `alert_bot_id`,
  ADD COLUMN IF NOT EXISTS `last_error` text COMMENT '最后错误信息' AFTER `last_status`,
  ADD COLUMN IF NOT EXISTS `cert_expiry_date` datetime(3) DEFAULT NULL COMMENT '证书过期时间' AFTER `last_error`,
  ADD COLUMN IF NOT EXISTS `cert_days_remaining` int DEFAULT NULL COMMENT 'SSL证书剩余天数' AFTER `cert_expiry_date`,
  ADD COLUMN IF NOT EXISTS `cert_issuer` varchar(500) DEFAULT '' COMMENT '证书颁发者' AFTER `cert_days_remaining`,
  ADD COLUMN IF NOT EXISTS `cert_subject` varchar(500) DEFAULT '' COMMENT '证书主题' AFTER `cert_issuer`,
  ADD COLUMN IF NOT EXISTS `cert_serial_number` varchar(100) DEFAULT '' COMMENT '证书序列号' AFTER `cert_subject`,
  ADD COLUMN IF NOT EXISTS `critical_days` int DEFAULT 7 COMMENT '严重告警阈值（天）' AFTER `cert_serial_number`,
  ADD COLUMN IF NOT EXISTS `warning_days` int DEFAULT 30 COMMENT '警告告警阈值（天）' AFTER `critical_days`,
  ADD COLUMN IF NOT EXISTS `notice_days` int DEFAULT 60 COMMENT '提醒告警阈值（天）' AFTER `warning_days`,
  ADD COLUMN IF NOT EXISTS `last_alert_level` varchar(20) DEFAULT NULL COMMENT '最后告警级别: info/warning/error/critical' AFTER `notice_days`,
  ADD COLUMN IF NOT EXISTS `last_alert_at` datetime(3) DEFAULT NULL COMMENT '最后告警时间' AFTER `last_alert_level`;

CREATE INDEX IF NOT EXISTS `idx_hcc_type` ON `health_check_configs`(`type`);
CREATE INDEX IF NOT EXISTS `idx_hcc_target_id` ON `health_check_configs`(`target_id`);
CREATE INDEX IF NOT EXISTS `idx_hcc_alert_bot_id` ON `health_check_configs`(`alert_bot_id`);
CREATE INDEX IF NOT EXISTS `idx_hcc_cert_days` ON `health_check_configs`(`cert_days_remaining`);
CREATE INDEX IF NOT EXISTS `idx_hcc_alert_level` ON `health_check_configs`(`last_alert_level`);

-- 10.2 log_saved_queries 表补充字段
ALTER TABLE `log_saved_queries`
  ADD COLUMN IF NOT EXISTS `is_shared` tinyint(1) DEFAULT 0 COMMENT '是否共享给团队' AFTER `is_public`;

CREATE INDEX IF NOT EXISTS `idx_lsq_is_shared` ON `log_saved_queries`(`is_shared`);

-- 10.3 resource_costs 表补充字段
ALTER TABLE `resource_costs`
  ADD COLUMN IF NOT EXISTS `recorded_at` datetime(3) DEFAULT NULL COMMENT '成本记录时间' AFTER `period_end`,
  ADD COLUMN IF NOT EXISTS `app_name` varchar(100) DEFAULT '' COMMENT '应用名称' AFTER `resource_name`,
  ADD COLUMN IF NOT EXISTS `team_name` varchar(100) DEFAULT '' COMMENT '团队名称' AFTER `app_name`,
  ADD COLUMN IF NOT EXISTS `cpu_usage` decimal(10,2) DEFAULT 0.00 COMMENT 'CPU 实际使用量(核)' AFTER `cpu_request`,
  ADD COLUMN IF NOT EXISTS `cpu_limit` decimal(10,2) DEFAULT 0.00 COMMENT 'CPU 限制量(核)' AFTER `cpu_usage`,
  ADD COLUMN IF NOT EXISTS `memory_usage` decimal(10,2) DEFAULT 0.00 COMMENT '内存实际使用量(GB)' AFTER `memory_request`,
  ADD COLUMN IF NOT EXISTS `memory_limit` decimal(10,2) DEFAULT 0.00 COMMENT '内存限制量(GB)' AFTER `memory_usage`,
  ADD COLUMN IF NOT EXISTS `storage_size` decimal(10,2) DEFAULT 0.00 COMMENT '存储大小(GB)' AFTER `memory_limit`;

CREATE INDEX IF NOT EXISTS `idx_rc_recorded_at` ON `resource_costs`(`recorded_at`);
CREATE INDEX IF NOT EXISTS `idx_rc_app_name` ON `resource_costs`(`app_name`);
CREATE INDEX IF NOT EXISTS `idx_rc_team_name` ON `resource_costs`(`team_name`);

-- 10.4 为现有数据初始化字段值
UPDATE `health_check_configs`
SET `type` = CASE
  WHEN `url` LIKE 'https://%' OR `url` LIKE 'http://%' THEN 'http'
  WHEN `url` LIKE 'tcp://%' THEN 'tcp'
  ELSE 'http'
END
WHERE `type` IS NULL OR `type` = '';

UPDATE `resource_costs`
SET `recorded_at` = `created_at`
WHERE `recorded_at` IS NULL;
