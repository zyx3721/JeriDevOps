-- ============================================
-- 数据库表结构与 Go Model 一致性修复脚本
-- 创建时间：2026-04-14
-- 作者：Claude Opus 4.6
--
-- 警告：执行前请务必备份数据库！
-- 使用方法：mysql -u root -p devops < fix_db_consistency.sql
-- ============================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 第一部分：严重问题修复（Critical Issues）
-- ============================================

-- 1. 修复 k8s_clusters 表
-- 问题：字段不匹配，SQL 中有 api_server/token/ca_cert，Model 中使用 kubeconfig
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

-- 2. 重建 feishu_requests 表
-- 问题：字段完全不匹配，需要重建
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

-- 3. 修复 application_envs 表
-- 问题：字段名不一致，缺少 branch 字段
ALTER TABLE `application_envs`
  CHANGE COLUMN `env` `env_name` varchar(50) NOT NULL COMMENT '环境名称';

ALTER TABLE `application_envs`
  DROP COLUMN IF EXISTS `jenkins_instance_id`,
  DROP COLUMN IF EXISTS `k8s_cluster_id`;

ALTER TABLE `application_envs`
  ADD COLUMN IF NOT EXISTS `branch` varchar(100) DEFAULT '' COMMENT 'Git 分支' AFTER `env_name`;

-- 4. 修复 artifact_repositories 表
-- 问题：监控相关字段不匹配
ALTER TABLE `artifact_repositories`
  DROP COLUMN IF EXISTS `check_status`,
  DROP COLUMN IF EXISTS `check_message`,
  DROP COLUMN IF EXISTS `check_latency_ms`,
  DROP COLUMN IF EXISTS `total_images`,
  DROP COLUMN IF EXISTS `total_size_bytes`;

ALTER TABLE `artifact_repositories`
  ADD COLUMN IF NOT EXISTS `connection_status` varchar(20) DEFAULT 'unknown' COMMENT '连接状态: connected/disconnected/checking/unknown' AFTER `enabled`,
  ADD COLUMN IF NOT EXISTS `last_error` text COMMENT '最后错误信息' AFTER `last_check_at`,
  ADD COLUMN IF NOT EXISTS `enable_monitoring` tinyint(1) DEFAULT 1 COMMENT '是否启用监控' AFTER `last_error`,
  ADD COLUMN IF NOT EXISTS `check_interval` int DEFAULT 300 COMMENT '检查间隔(秒)' AFTER `enable_monitoring`;

CREATE INDEX IF NOT EXISTS `idx_connection_status` ON `artifact_repositories`(`connection_status`);
CREATE INDEX IF NOT EXISTS `idx_enable_monitoring` ON `artifact_repositories`(`enable_monitoring`);

-- 5. 修复 artifacts 表字段名
-- 问题：download_cnt -> download_count, latest_version -> latest_ver
ALTER TABLE `artifacts`
  CHANGE COLUMN `download_cnt` `download_count` bigint DEFAULT 0 COMMENT '下载次数',
  CHANGE COLUMN `latest_version` `latest_ver` varchar(100) DEFAULT NULL COMMENT '最新版本';

-- 6. 修复 artifact_versions 表字段名
-- 问题：download_cnt -> download_count
ALTER TABLE `artifact_versions`
  CHANGE COLUMN `download_cnt` `download_count` bigint DEFAULT 0 COMMENT '下载次数';

-- ============================================
-- 第二部分：中等问题修复（Medium Issues）
-- ============================================

-- 7. 修复 alert_histories 表
-- 问题：缺少大量字段
ALTER TABLE `alert_histories`
  DROP COLUMN IF EXISTS `config_name`,
  DROP COLUMN IF EXISTS `target`,
  DROP COLUMN IF EXISTS `details`,
  DROP COLUMN IF EXISTS `notified`,
  DROP COLUMN IF EXISTS `notified_at`;

ALTER TABLE `alert_histories`
  ADD COLUMN IF NOT EXISTS `title` varchar(200) DEFAULT '' COMMENT '标题' AFTER `type`,
  ADD COLUMN IF NOT EXISTS `content` text COMMENT '内容' AFTER `title`,
  ADD COLUMN IF NOT EXISTS `level` varchar(20) DEFAULT 'warning' COMMENT '级别: info/warning/error/critical' AFTER `content`,
  ADD COLUMN IF NOT EXISTS `ack_status` varchar(20) DEFAULT 'pending' COMMENT '确认状态: pending/acked/resolved' AFTER `status`,
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

-- 8. 修复 dingtalk_bots 表
-- 问题：有多余字段
ALTER TABLE `dingtalk_bots`
  DROP COLUMN IF EXISTS `project`,
  DROP COLUMN IF EXISTS `message_template_id`;

-- 9. 修复 wechat_work_bots 表
-- 问题：缺少索引
CREATE INDEX IF NOT EXISTS `idx_wwb_created_by` ON `wechat_work_bots`(`created_by`);

-- 10. 修复 feishu_apps 表
-- 问题：字段类型不匹配
ALTER TABLE `feishu_apps`
  MODIFY COLUMN `project` varchar(100) NOT NULL COMMENT '所属项目',
  MODIFY COLUMN `description` text COMMENT '描述',
  MODIFY COLUMN `status` varchar(20) NOT NULL COMMENT '状态: active/inactive';

-- 11. 修复 feishu_bots 表
-- 问题：secret 字段长度不一致
ALTER TABLE `feishu_bots`
  MODIFY COLUMN `secret` varchar(100) DEFAULT '' COMMENT '签名密钥';

-- ============================================
-- 第三部分：创建缺失的表（Missing Tables）
-- ============================================

-- 12. 创建 pipeline_runs 表
CREATE TABLE IF NOT EXISTS `pipeline_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pipeline_id` bigint unsigned NOT NULL COMMENT '流水线ID',
  `pipeline_name` varchar(100) DEFAULT '' COMMENT '流水线名称',
  `status` varchar(20) NOT NULL COMMENT '状态: pending/running/success/failed/cancelled',
  `trigger_type` varchar(20) NOT NULL COMMENT '触发类型: manual/scheduled/webhook',
  `trigger_by` varchar(100) DEFAULT '' COMMENT '触发者',
  `parameters_json` text COMMENT '参数 JSON',
  `git_commit` varchar(100) DEFAULT '' COMMENT 'Git 提交 SHA',
  `git_branch` varchar(100) DEFAULT '' COMMENT 'Git 分支',
  `git_message` text COMMENT 'Git 提交信息',
  `workspace_id` bigint unsigned DEFAULT NULL COMMENT '工作空间ID',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `duration` int DEFAULT 0 COMMENT '执行时长(秒)',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pr_pipeline` (`pipeline_id`),
  KEY `idx_pr_status` (`status`),
  KEY `idx_pr_created_at` (`created_at`),
  KEY `idx_pr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水线执行记录';

-- 13. 创建 stage_runs 表
CREATE TABLE IF NOT EXISTS `stage_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pipeline_run_id` bigint unsigned NOT NULL COMMENT '流水线运行ID',
  `stage_id` varchar(50) NOT NULL COMMENT '阶段ID',
  `stage_name` varchar(100) DEFAULT '' COMMENT '阶段名称',
  `status` varchar(20) NOT NULL COMMENT '状态: pending/running/success/failed/cancelled',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `duration` int DEFAULT 0 COMMENT '执行时长(秒)',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sr_pipeline_run` (`pipeline_run_id`),
  KEY `idx_sr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='阶段执行记录';

-- 14. 创建 step_runs 表
CREATE TABLE IF NOT EXISTS `step_runs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `stage_run_id` bigint unsigned NOT NULL COMMENT '阶段运行ID',
  `step_id` varchar(50) NOT NULL COMMENT '步骤ID',
  `step_name` varchar(100) DEFAULT '' COMMENT '步骤名称',
  `step_type` varchar(50) DEFAULT '' COMMENT '步骤类型',
  `build_job_id` bigint unsigned DEFAULT NULL COMMENT '构建任务ID',
  `status` varchar(20) NOT NULL COMMENT '状态: pending/running/success/failed/cancelled',
  `logs` longtext COMMENT '日志',
  `exit_code` int DEFAULT NULL COMMENT '退出码',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `duration` int DEFAULT 0 COMMENT '执行时长(秒)',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sr_stage_run` (`stage_run_id`),
  KEY `idx_sr_build_job` (`build_job_id`),
  KEY `idx_sr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='步骤执行记录';

-- 15. 创建 pipeline_credentials 表
CREATE TABLE IF NOT EXISTS `pipeline_credentials` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '凭证名称',
  `type` varchar(50) NOT NULL COMMENT '类型: username_password/ssh_key/docker_registry/kubeconfig',
  `description` text COMMENT '描述',
  `data_encrypted` text NOT NULL COMMENT '加密数据',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pc_name` (`name`),
  KEY `idx_pc_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水线凭证';

-- 16. 创建 pipeline_variables 表
CREATE TABLE IF NOT EXISTS `pipeline_variables` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '变量名',
  `value` text NOT NULL COMMENT '变量值',
  `is_secret` tinyint(1) DEFAULT 0 COMMENT '是否敏感',
  `scope` varchar(20) DEFAULT 'global' COMMENT '作用域: global/pipeline',
  `pipeline_id` bigint unsigned DEFAULT NULL COMMENT '流水线ID',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pv_scope` (`scope`),
  KEY `idx_pv_pipeline` (`pipeline_id`),
  KEY `idx_pv_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水线环境变量';

-- 17. 创建 git_repositories 表
CREATE TABLE IF NOT EXISTS `git_repositories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '仓库名称',
  `url` varchar(500) NOT NULL COMMENT '仓库 URL',
  `provider` varchar(50) DEFAULT '' COMMENT '提供商: github/gitlab/gitee/custom',
  `default_branch` varchar(100) DEFAULT 'main' COMMENT '默认分支',
  `credential_id` bigint unsigned DEFAULT NULL COMMENT '凭证ID',
  `webhook_secret` varchar(100) DEFAULT '' COMMENT 'Webhook 密钥',
  `webhook_url` varchar(500) DEFAULT '' COMMENT 'Webhook URL',
  `description` text COMMENT '描述',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_gr_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Git 仓库配置';

-- 18. 创建 build_jobs 表
CREATE TABLE IF NOT EXISTS `build_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pipeline_run_id` bigint unsigned NOT NULL COMMENT '流水线运行ID',
  `step_id` varchar(50) NOT NULL COMMENT '步骤ID',
  `step_name` varchar(100) DEFAULT '' COMMENT '步骤名称',
  `job_name` varchar(100) NOT NULL COMMENT 'Job 名称',
  `namespace` varchar(100) NOT NULL COMMENT '命名空间',
  `cluster_id` bigint unsigned NOT NULL COMMENT '集群ID',
  `image` varchar(500) NOT NULL COMMENT '镜像',
  `commands` text COMMENT '命令 JSON',
  `work_dir` varchar(200) DEFAULT '/workspace' COMMENT '工作目录',
  `env_vars` text COMMENT '环境变量 JSON',
  `resources` text COMMENT '资源配置 JSON',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态: pending/running/success/failed/cancelled',
  `pod_name` varchar(100) DEFAULT '' COMMENT 'Pod 名称',
  `node_name` varchar(100) DEFAULT '' COMMENT '节点名称',
  `exit_code` int DEFAULT NULL COMMENT '退出码',
  `error_message` text COMMENT '错误信息',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_bj_pipeline_run` (`pipeline_run_id`),
  KEY `idx_bj_cluster` (`cluster_id`),
  KEY `idx_bj_status` (`status`),
  KEY `idx_bj_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='构建任务';

-- 19. 创建 build_workspaces 表
CREATE TABLE IF NOT EXISTS `build_workspaces` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pipeline_run_id` bigint unsigned NOT NULL COMMENT '流水线运行ID',
  `cluster_id` bigint unsigned NOT NULL COMMENT '集群ID',
  `namespace` varchar(100) NOT NULL COMMENT '命名空间',
  `pvc_name` varchar(100) NOT NULL COMMENT 'PVC 名称',
  `storage_size` varchar(20) DEFAULT '10Gi' COMMENT '存储大小',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态: pending/bound/released',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_bw_pipeline_run` (`pipeline_run_id`),
  KEY `idx_bw_status` (`status`),
  KEY `idx_bw_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='构建工作空间';

-- 20. 创建 webhook_logs 表
CREATE TABLE IF NOT EXISTS `webhook_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `git_repo_id` bigint unsigned NOT NULL COMMENT 'Git 仓库ID',
  `provider` varchar(50) NOT NULL COMMENT '提供商: github/gitlab/gitee',
  `event` varchar(50) NOT NULL COMMENT '事件类型: push/pull_request/tag',
  `ref` varchar(200) DEFAULT '' COMMENT '引用: refs/heads/main',
  `commit_sha` varchar(100) DEFAULT '' COMMENT '提交 SHA',
  `payload` longtext COMMENT '请求体',
  `status` varchar(20) NOT NULL COMMENT '状态: success/failed',
  `pipeline_run_id` bigint unsigned DEFAULT 0 COMMENT '触发的流水线运行ID',
  `error_msg` text COMMENT '错误信息',
  `received_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '接收时间',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_wl_git_repo` (`git_repo_id`),
  KEY `idx_wl_status` (`status`),
  KEY `idx_wl_pipeline_run` (`pipeline_run_id`),
  KEY `idx_wl_received_at` (`received_at`),
  KEY `idx_wl_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Webhook 日志';

-- 21. 创建 artifact_registries 表（流水线用）
CREATE TABLE IF NOT EXISTS `artifact_registries` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '名称',
  `type` varchar(50) NOT NULL COMMENT '类型: harbor/nexus/dockerhub/acr/ecr/gcr/custom',
  `url` varchar(500) NOT NULL COMMENT 'URL',
  `username` varchar(100) DEFAULT '' COMMENT '用户名',
  `password` varchar(500) DEFAULT '' COMMENT '密码',
  `description` text COMMENT '描述',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认',
  `status` varchar(20) DEFAULT 'unknown' COMMENT '状态: active/inactive/unknown',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ar_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='制品库配置';

-- 22. 创建 ai_message_feedbacks 表
CREATE TABLE IF NOT EXISTS `ai_message_feedbacks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `message_id` varchar(36) NOT NULL COMMENT '消息ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `rating` varchar(20) NOT NULL COMMENT '评分: like/dislike',
  `feedback_text` text COMMENT '反馈文本',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_amf_message_id` (`message_id`),
  KEY `idx_amf_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI消息反馈';

-- ============================================
-- 第四部分：补充缺失的索引
-- ============================================

-- 为 pipelines 表添加缺失的索引
CREATE INDEX IF NOT EXISTS `idx_pipelines_deleted_at` ON `pipelines`(`deleted_at`);

-- 为 health_check_configs 表添加缺失的索引
CREATE INDEX IF NOT EXISTS `idx_hcc_deleted_at` ON `health_check_configs`(`deleted_at`);

-- 为 health_check_histories 表添加缺失的索引
CREATE INDEX IF NOT EXISTS `idx_hch_deleted_at` ON `health_check_histories`(`deleted_at`);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- 修复完成
-- ============================================
