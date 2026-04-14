/*
项目名称：devops
文件名称：init_tables_v2.sql
创建时间：2026-04-14 17:19:19
系统用户：jerion
作　　者：Jerion
联系邮箱：416685476@qq.com
功能描述：全量建表 SQL（已合并 fix_db_consistency.sql 的所有修复内容），全新部署时执行
*/

-- ============================================
-- 基础表
-- ============================================

-- 1. 用户表
CREATE TABLE IF NOT EXISTS `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT '',
  `role` varchar(20) DEFAULT 'user' NOT NULL,
  `status` varchar(20) DEFAULT 'active' NOT NULL,
  `last_login_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_users_username` (`username`),
  UNIQUE KEY `idx_users_email` (`email`),
  KEY `idx_users_deleted_at` (`deleted_at`),
  KEY `idx_users_last_login_at` (`last_login_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 2. 审计日志表
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tenant_id` int unsigned DEFAULT NULL COMMENT '租户ID',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `user_id` bigint unsigned DEFAULT NULL COMMENT '用户ID',
  `username` varchar(100) DEFAULT '',
  `action` varchar(50) NOT NULL COMMENT '操作类型: create/update/delete',
  `resource_type` varchar(50) NOT NULL COMMENT '资源类型',
  `resource_id` bigint unsigned DEFAULT NULL COMMENT '资源ID',
  `resource_name` varchar(255) DEFAULT '' COMMENT '资源名称',
  `old_value` json DEFAULT NULL COMMENT '变更前的值',
  `new_value` json DEFAULT NULL COMMENT '变更后的值',
  `detail` text COMMENT '详情JSON',
  `ip_address` varchar(50) DEFAULT '' COMMENT '客户端IP',
  `user_agent` varchar(500) DEFAULT '' COMMENT 'User-Agent',
  `request_id` varchar(50) DEFAULT NULL COMMENT '请求ID',
  `trace_id` varchar(50) DEFAULT NULL COMMENT '追踪ID',
  `duration` bigint DEFAULT NULL COMMENT '操作耗时(ms)',
  `status` varchar(20) DEFAULT 'success' COMMENT '状态',
  `error_message` text COMMENT '错误信息',
  PRIMARY KEY (`id`),
  KEY `idx_audit_user` (`user_id`),
  KEY `idx_audit_action` (`action`),
  KEY `idx_audit_resource` (`resource_type`),
  KEY `idx_audit_created` (`created_at`),
  KEY `idx_audit_tenant_id` (`tenant_id`),
  KEY `idx_audit_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作审计日志';

-- ============================================
-- Jenkins 相关表
-- ============================================

-- 3. Jenkins 实例表
CREATE TABLE IF NOT EXISTS `jenkins_instances` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `url` varchar(500) NOT NULL,
  `username` varchar(100) DEFAULT '',
  `api_token` varchar(500) DEFAULT '',
  `description` text,
  `status` varchar(20) DEFAULT 'active' NOT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_jenkins_deleted_at` (`deleted_at`),
  KEY `idx_jenkins_created_by` (`created_by`),
  KEY `idx_jenkins_updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Jenkins实例';

-- 4. Jenkins 构建记录表
CREATE TABLE IF NOT EXISTS `jenkins_builds` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `instance_id` bigint unsigned NOT NULL COMMENT 'Jenkins实例ID',
  `job_name` varchar(200) NOT NULL COMMENT 'Job名称',
  `build_number` int NOT NULL COMMENT '构建号',
  `status` varchar(20) DEFAULT 'running' COMMENT '状态: running/success/failed/aborted',
  `duration` int DEFAULT 0 COMMENT '耗时(秒)',
  `triggered_by` varchar(100) DEFAULT '' COMMENT '触发人',
  `parameters` json DEFAULT NULL COMMENT '构建参数',
  `log_url` varchar(500) DEFAULT '' COMMENT '日志URL',
  `started_at` datetime(3) DEFAULT NULL,
  `finished_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_jb_instance` (`instance_id`),
  KEY `idx_jb_job` (`job_name`),
  KEY `idx_jb_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Jenkins构建记录';

-- ============================================
-- K8s 相关表
-- ============================================

-- 5. K8s 集群表
CREATE TABLE IF NOT EXISTS `k8s_clusters` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `kubeconfig` text COMMENT 'KubeConfig内容',
  `namespace` varchar(100) DEFAULT 'default' NOT NULL COMMENT '默认命名空间',
  `registry` varchar(500) DEFAULT '' COMMENT '镜像仓库地址',
  `repository` varchar(200) DEFAULT '' COMMENT '镜像仓库名称',
  `description` text,
  `status` varchar(20) DEFAULT 'active' NOT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `insecure_skip_tls` tinyint(1) DEFAULT 0 COMMENT '跳过 TLS 证书验证',
  `check_timeout` int DEFAULT 180 NOT NULL COMMENT '健康检查超时时间(秒)',
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL COMMENT '更新者ID',
  PRIMARY KEY (`id`),
  KEY `idx_k8s_deleted_at` (`deleted_at`),
  KEY `idx_k8s_updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K8s集群';

-- 6. CronHPA 表
CREATE TABLE IF NOT EXISTS `cron_hpa` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cluster_id` bigint unsigned NOT NULL,
  `name` varchar(100) NOT NULL,
  `namespace` varchar(100) NOT NULL,
  `target_kind` varchar(50) NOT NULL,
  `target_name` varchar(100) NOT NULL,
  `enabled` tinyint(1) DEFAULT 1,
  `schedules` json NOT NULL,
  `created_by` varchar(100) DEFAULT '',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_cron_hpa_cluster_ns_name` (`cluster_id`, `namespace`, `name`),
  KEY `idx_cron_hpa_cluster_enabled` (`cluster_id`, `enabled`),
  KEY `idx_cron_hpa_namespace` (`namespace`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CronHPA';

-- ============================================
-- 通知相关表
-- ============================================

-- 7. 飞书应用表
CREATE TABLE IF NOT EXISTS `feishu_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '应用名称',
  `app_id` varchar(100) NOT NULL COMMENT '飞书 App ID',
  `app_secret` varchar(200) NOT NULL COMMENT '飞书 App Secret',
  `webhook` varchar(500) DEFAULT '' COMMENT 'Webhook URL',
  `project` varchar(100) NOT NULL COMMENT '所属项目',
  `description` text COMMENT '描述',
  `status` varchar(20) NOT NULL COMMENT '状态: active/inactive',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_fa_app_id` (`app_id`),
  KEY `idx_fa_status` (`status`),
  KEY `idx_fa_is_default` (`is_default`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书应用配置';

-- 8. 飞书机器人表
CREATE TABLE IF NOT EXISTS `feishu_bots` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '机器人名称',
  `webhook_url` varchar(500) NOT NULL COMMENT 'Webhook URL',
  `project` varchar(100) DEFAULT '' COMMENT '所属项目',
  `secret` varchar(100) DEFAULT '' COMMENT '签名密钥',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `message_template_id` bigint unsigned DEFAULT NULL COMMENT '消息模板ID',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_fb_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书机器人配置';

-- 9. 飞书消息发送记录表
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

-- 10. 飞书用户令牌表
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

-- 11. 飞书请求记录表
CREATE TABLE IF NOT EXISTS `feishu_requests` (
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

-- 12. 钉钉机器人表
CREATE TABLE IF NOT EXISTS `dingtalk_bots` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '机器人名称',
  `webhook_url` varchar(500) NOT NULL COMMENT 'Webhook URL',
  `secret` varchar(200) DEFAULT '' COMMENT '签名密钥',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_dtb_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='钉钉机器人配置';


-- ============================================
-- 13. 钉钉应用表
-- ============================================
CREATE TABLE IF NOT EXISTS `dingtalk_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '应用名称',
  `app_key` varchar(200) NOT NULL COMMENT '钉钉 App Key',
  `app_secret` varchar(200) NOT NULL COMMENT '钉钉 App Secret',
  `agent_id` bigint DEFAULT NULL COMMENT '钉钉 Agent ID',
  `project` varchar(100) DEFAULT '' COMMENT '关联项目',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `description` varchar(500) DEFAULT '',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认应用',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_dingtalk_apps_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='钉钉应用';

-- ============================================
-- 14. 钉钉消息记录表
-- ============================================
CREATE TABLE IF NOT EXISTS `dingtalk_message_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `msg_type` varchar(50) NOT NULL COMMENT '消息类型',
  `target` varchar(200) DEFAULT '' COMMENT '发送目标',
  `content` text COMMENT '消息内容',
  `title` varchar(200) DEFAULT '' COMMENT '标题',
  `source` varchar(50) DEFAULT '' COMMENT '来源',
  `status` varchar(20) DEFAULT 'success' COMMENT '状态: success/failed',
  `error_msg` text COMMENT '错误信息',
  `app_id` bigint unsigned DEFAULT NULL COMMENT '关联钉钉应用ID',
  PRIMARY KEY (`id`),
  KEY `idx_dtl_status` (`status`),
  KEY `idx_dtl_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='钉钉消息发送记录';

-- ============================================
-- 15. 企业微信应用表
-- ============================================
CREATE TABLE IF NOT EXISTS `wechat_work_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '应用名称',
  `corp_id` varchar(200) NOT NULL COMMENT '企业ID',
  `agent_id` bigint DEFAULT NULL COMMENT '应用 Agent ID',
  `secret` varchar(200) NOT NULL COMMENT '应用密钥',
  `project` varchar(100) DEFAULT '' COMMENT '关联项目',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `description` varchar(500) DEFAULT '',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认应用',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_ww_apps_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业微信应用';

-- ============================================
-- 16. 企业微信机器人表
-- ============================================
CREATE TABLE IF NOT EXISTS `wechat_work_bots` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '机器人名称',
  `webhook_url` varchar(500) NOT NULL COMMENT 'Webhook URL',
  `description` varchar(500) DEFAULT '',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_ww_bots_status` (`status`),
  KEY `idx_wwb_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业微信机器人';

-- ============================================
-- 17. 企业微信消息记录表
-- ============================================
CREATE TABLE IF NOT EXISTS `wechat_work_message_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `msg_type` varchar(50) NOT NULL COMMENT '消息类型',
  `to_user` varchar(500) DEFAULT '' COMMENT '接收用户',
  `to_party` varchar(500) DEFAULT '' COMMENT '接收部门',
  `to_tag` varchar(500) DEFAULT '' COMMENT '接收标签',
  `content` text COMMENT '消息内容',
  `title` varchar(200) DEFAULT '' COMMENT '标题',
  `source` varchar(50) DEFAULT '' COMMENT '来源',
  `status` varchar(20) DEFAULT 'success' COMMENT '状态: success/failed',
  `error_msg` text COMMENT '错误信息',
  `app_id` bigint unsigned DEFAULT NULL COMMENT '关联企业微信应用ID',
  PRIMARY KEY (`id`),
  KEY `idx_wwl_status` (`status`),
  KEY `idx_wwl_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业微信消息发送记录';

-- 18. 消息模板表
CREATE TABLE IF NOT EXISTS `message_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '模板名称',
  `type` varchar(50) NOT NULL COMMENT '模板类型: text/markdown/card',
  `content` text COMMENT '模板内容',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否激活',
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_mt_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息模板';

-- ============================================
-- OA 审批相关表
-- ============================================

-- 19. OA 配置表
CREATE TABLE IF NOT EXISTS `oa_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `platform` varchar(50) NOT NULL COMMENT '平台: feishu/dingtalk',
  `app_id` varchar(100) DEFAULT '' COMMENT '应用ID',
  `app_secret` varchar(200) DEFAULT '' COMMENT '应用密钥',
  `approval_code` varchar(100) DEFAULT '' COMMENT '审批模板Code',
  `enabled` tinyint(1) DEFAULT 1,
  `description` varchar(500) DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `idx_oa_platform` (`platform`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OA审批配置';

-- 20. OA 审批记录表
CREATE TABLE IF NOT EXISTS `oa_approval_records` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `platform` varchar(50) NOT NULL COMMENT '平台: feishu/dingtalk',
  `instance_code` varchar(200) DEFAULT '' COMMENT '审批实例Code',
  `approval_code` varchar(100) DEFAULT '' COMMENT '审批模板Code',
  `applicant_id` varchar(100) DEFAULT '' COMMENT '申请人ID',
  `applicant_name` varchar(100) DEFAULT '' COMMENT '申请人姓名',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态: pending/approved/rejected/cancelled',
  `form_data` text COMMENT '表单数据JSON',
  `related_type` varchar(50) DEFAULT '' COMMENT '关联类型: deploy',
  `related_id` bigint unsigned DEFAULT 0 COMMENT '关联ID',
  `approved_at` datetime(3) DEFAULT NULL,
  `rejected_at` datetime(3) DEFAULT NULL,
  `comment` text COMMENT '审批意见',
  PRIMARY KEY (`id`),
  KEY `idx_oa_instance` (`instance_code`),
  KEY `idx_oa_status` (`status`),
  KEY `idx_oa_related` (`related_type`, `related_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OA审批记录';

-- ============================================
-- 系统配置相关表
-- ============================================

-- 21. 系统配置表
CREATE TABLE IF NOT EXISTS `system_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `key` varchar(100) NOT NULL COMMENT '配置键',
  `value` text COMMENT '配置值',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `group` varchar(50) DEFAULT 'default' COMMENT '分组',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_sc_key` (`key`),
  KEY `idx_sc_group` (`group`),
  KEY `idx_sc_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置';

-- 22. 系统消息模板表
CREATE TABLE IF NOT EXISTS `sys_message_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `template_type` varchar(20) DEFAULT 'text' COMMENT '模板类型: text/card',
  `title` varchar(200) DEFAULT NULL,
  `content` text,
  `variables` text COMMENT '模板变量列表JSON',
  `description` varchar(255) DEFAULT NULL,
  `created_by` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_name` (`name`),
  KEY `idx_sys_message_templates_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统消息模板';

-- ============================================
-- 告警相关表
-- ============================================

-- 23. 告警配置表
CREATE TABLE IF NOT EXISTS `alert_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '告警名称',
  `type` varchar(50) NOT NULL COMMENT '告警类型: jenkins/k8s/healthcheck/custom',
  `target` varchar(255) DEFAULT '' COMMENT '监控目标',
  `condition_expr` varchar(500) DEFAULT '' COMMENT '告警条件',
  `threshold` varchar(100) DEFAULT '' COMMENT '阈值',
  `severity` varchar(20) DEFAULT 'warning' COMMENT '严重级别: info/warning/critical',
  `notify_channels` varchar(500) DEFAULT '' COMMENT '通知渠道: feishu,dingtalk,wechatwork',
  `notify_users` varchar(500) DEFAULT '' COMMENT '通知用户ID列表',
  `platform` varchar(50) DEFAULT '' COMMENT '通知平台',
  `bot_id` bigint unsigned DEFAULT NULL COMMENT '机器人ID',
  `feishu_bot_id` bigint unsigned DEFAULT NULL COMMENT '飞书机器人ID',
  `dingtalk_bot_id` bigint unsigned DEFAULT NULL COMMENT '钉钉机器人ID',
  `wechatwork_bot_id` bigint unsigned DEFAULT NULL COMMENT '企业微信机器人ID',
  `template_id` bigint unsigned DEFAULT NULL COMMENT '消息模板ID',
  `channels` text DEFAULT NULL COMMENT '通知渠道配置JSON',
  `conditions` text DEFAULT NULL COMMENT '告警条件配置JSON',
  `enabled` tinyint(1) DEFAULT 1,
  `description` varchar(500) DEFAULT '',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_alert_type` (`type`),
  KEY `idx_alert_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警配置';

-- 24. 告警历史表
CREATE TABLE IF NOT EXISTS `alert_histories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `config_id` bigint unsigned NOT NULL COMMENT '告警配置ID',
  `type` varchar(50) NOT NULL COMMENT '告警类型',
  `title` varchar(200) DEFAULT '' COMMENT '标题',
  `content` text COMMENT '内容',
  `level` varchar(20) DEFAULT 'warning' COMMENT '级别: info/warning/error/critical',
  `severity` varchar(20) DEFAULT 'warning' COMMENT '严重级别',
  `message` text COMMENT '告警消息',
  `status` varchar(20) DEFAULT 'firing' COMMENT '状态: firing/resolved',
  `ack_status` varchar(20) DEFAULT 'pending' COMMENT '确认状态: pending/acked/resolved',
  `ack_by` bigint unsigned DEFAULT NULL COMMENT '确认人ID',
  `ack_at` datetime(3) DEFAULT NULL COMMENT '确认时间',
  `resolved_by` bigint unsigned DEFAULT NULL COMMENT '解决人ID',
  `resolved_at` datetime(3) DEFAULT NULL COMMENT '解决时间',
  `resolve_comment` text COMMENT '解决备注',
  `silenced` tinyint(1) DEFAULT 0 COMMENT '是否被静默',
  `silence_id` bigint unsigned DEFAULT NULL COMMENT '静默规则ID',
  `escalated` tinyint(1) DEFAULT 0 COMMENT '是否已升级',
  `escalation_id` bigint unsigned DEFAULT NULL COMMENT '升级规则ID',
  `error_msg` text COMMENT '错误信息',
  `source_id` varchar(100) DEFAULT '' COMMENT '来源ID',
  `source_url` varchar(500) DEFAULT '' COMMENT '来源URL',
  PRIMARY KEY (`id`),
  KEY `idx_alert_history_config` (`config_id`),
  KEY `idx_alert_history_status` (`status`),
  KEY `idx_alert_history_created` (`created_at`),
  KEY `idx_ah_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警历史';

-- 25. 日志告警历史表
CREATE TABLE IF NOT EXISTS `log_alert_history` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `rule_id` bigint unsigned NOT NULL COMMENT '告警规则ID',
  `rule_name` varchar(100) DEFAULT '' COMMENT '规则名称',
  `severity` varchar(20) DEFAULT 'warning' COMMENT '严重级别',
  `message` text COMMENT '告警消息',
  `count` int DEFAULT 1 COMMENT '触发次数',
  `status` varchar(20) DEFAULT 'firing' COMMENT '状态: firing/resolved',
  `notified` tinyint(1) DEFAULT 0,
  `notified_at` datetime(3) DEFAULT NULL,
  `resolved_at` datetime(3) DEFAULT NULL,
  `silenced` boolean DEFAULT FALSE COMMENT '是否被静默',
  `silence_id` int unsigned NULL COMMENT '静默规则ID',
  PRIMARY KEY (`id`),
  KEY `idx_lah_rule_id` (`rule_id`),
  KEY `idx_lah_status` (`status`),
  KEY `idx_lah_silenced` (`silenced`),
  KEY `idx_lah_silence_id` (`silence_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志告警历史';

-- ============================================
-- 应用与部署相关表
-- ============================================

-- 26. 应用表
CREATE TABLE IF NOT EXISTS `applications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '应用名称',
  `display_name` varchar(200) DEFAULT '' COMMENT '显示名称',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `git_repo` varchar(500) DEFAULT '' COMMENT '代码仓库地址',
  `team` varchar(100) DEFAULT '' COMMENT '所属团队',
  `owner` varchar(100) DEFAULT '' COMMENT '负责人',
  `language` varchar(50) DEFAULT '' COMMENT '开发语言',
  `framework` varchar(50) DEFAULT '' COMMENT '框架',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive/archived',
  `jenkins_instance_id` bigint unsigned DEFAULT NULL COMMENT 'Jenkins实例ID',
  `jenkins_job_name` varchar(200) DEFAULT '' COMMENT 'Jenkins Job名称',
  `k8s_cluster_id` bigint unsigned DEFAULT NULL COMMENT 'K8s集群ID',
  `k8s_namespace` varchar(100) DEFAULT '' COMMENT 'K8s命名空间',
  `k8s_deployment` varchar(200) DEFAULT '' COMMENT 'K8s Deployment名称',
  `notify_platform` varchar(50) DEFAULT '' COMMENT '通知平台',
  `notify_app_id` bigint unsigned DEFAULT NULL COMMENT '通知应用ID',
  `notify_receive_id` varchar(200) DEFAULT '' COMMENT '通知接收ID',
  `notify_receive_type` varchar(50) DEFAULT '' COMMENT '通知接收类型',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_app_name` (`name`),
  KEY `idx_app_team` (`team`),
  KEY `idx_app_status` (`status`),
  KEY `idx_jenkins_instance` (`jenkins_instance_id`),
  KEY `idx_k8s_cluster` (`k8s_cluster_id`),
  KEY `idx_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用管理';

-- 27. 应用环境配置表
CREATE TABLE IF NOT EXISTS `application_envs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `env_name` varchar(50) NOT NULL COMMENT '环境名称',
  `branch` varchar(100) DEFAULT '' COMMENT 'Git 分支',
  `jenkins_job` varchar(200) DEFAULT '' COMMENT 'Jenkins Job名称',
  `k8s_namespace` varchar(100) DEFAULT '' COMMENT 'K8s命名空间',
  `k8s_deployment` varchar(200) DEFAULT '' COMMENT 'K8s Deployment名称',
  `replicas` int DEFAULT 1 COMMENT '副本数',
  `config` text COMMENT '其他配置JSON',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_app_env` (`app_id`, `env_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用环境配置';

-- 28. 部署记录表
CREATE TABLE IF NOT EXISTS `deploy_records` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `app_id` bigint unsigned DEFAULT 0 COMMENT '应用ID(旧)',
  `application_id` bigint unsigned DEFAULT 0 COMMENT '应用ID',
  `app_name` varchar(100) DEFAULT '' COMMENT '应用名称',
  `env` varchar(50) DEFAULT '' COMMENT '环境(旧)',
  `env_name` varchar(50) DEFAULT '' COMMENT '环境名称',
  `version` varchar(100) DEFAULT '' COMMENT '版本号',
  `branch` varchar(100) DEFAULT '' COMMENT 'Git分支',
  `commit_id` varchar(100) DEFAULT '' COMMENT 'Git Commit ID',
  `commit_message` varchar(500) DEFAULT '' COMMENT 'Commit消息',
  `deploy_type` varchar(50) DEFAULT 'deploy' COMMENT '部署类型: deploy/rollback/restart/scale',
  `deploy_method` varchar(50) DEFAULT 'jenkins' COMMENT '部署方式: jenkins/k8s',
  `image` varchar(500) DEFAULT '' COMMENT '镜像地址(旧)',
  `image_tag` varchar(200) DEFAULT '' COMMENT '镜像标签',
  `jenkins_build_id` bigint unsigned DEFAULT 0 COMMENT 'Jenkins构建ID',
  `jenkins_build_number` int DEFAULT 0 COMMENT 'Jenkins构建号(旧)',
  `jenkins_build` int DEFAULT 0 COMMENT 'Jenkins构建号',
  `jenkins_url` varchar(500) DEFAULT '' COMMENT 'Jenkins构建URL',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态: pending/approved/rejected/running/success/failed/cancelled',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '结束时间',
  `duration` int DEFAULT 0 COMMENT '耗时(秒)',
  `error_msg` text COMMENT '错误信息',
  `deployed_by` bigint unsigned DEFAULT 0 COMMENT '部署人ID(旧)',
  `deployed_by_name` varchar(100) DEFAULT '' COMMENT '部署人(旧)',
  `operator` varchar(100) DEFAULT '' COMMENT '操作人',
  `operator_id` bigint unsigned DEFAULT 0 COMMENT '操作人ID',
  `need_approval` tinyint(1) DEFAULT 0 COMMENT '是否需要审批',
  `approval_chain_id` bigint unsigned DEFAULT NULL COMMENT '审批链ID',
  `approver_id` bigint unsigned DEFAULT NULL COMMENT '审批人ID',
  `approver_name` varchar(100) DEFAULT '' COMMENT '审批人',
  `approved_at` datetime(3) DEFAULT NULL COMMENT '审批时间',
  `reject_reason` text COMMENT '拒绝原因',
  `rollback_from` bigint unsigned DEFAULT 0 COMMENT '回滚来源记录ID',
  `remark` varchar(500) DEFAULT '' COMMENT '备注(旧)',
  `description` text COMMENT '发布说明',
  PRIMARY KEY (`id`),
  KEY `idx_deploy_app` (`app_id`),
  KEY `idx_deploy_application` (`application_id`),
  KEY `idx_deploy_env` (`env`),
  KEY `idx_deploy_env_name` (`env_name`),
  KEY `idx_deploy_status` (`status`),
  KEY `idx_deploy_operator` (`operator_id`),
  KEY `idx_deploy_approval_chain` (`approval_chain_id`),
  KEY `idx_deploy_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部署记录';

-- 29. 发布锁表
CREATE TABLE IF NOT EXISTS `deploy_locks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `application_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `env_name` varchar(50) NOT NULL COMMENT '环境',
  `record_id` bigint unsigned NOT NULL COMMENT '关联的部署记录ID',
  `locked_by` bigint unsigned NOT NULL COMMENT '锁定人ID',
  `locked_by_name` varchar(100) DEFAULT '' COMMENT '锁定人',
  `expires_at` datetime(3) NOT NULL COMMENT '过期时间',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/released/expired',
  `released_at` datetime(3) DEFAULT NULL COMMENT '释放时间',
  `released_by` bigint unsigned DEFAULT NULL COMMENT '释放人ID',
  `release_reason` varchar(200) DEFAULT '' COMMENT '释放原因',
  PRIMARY KEY (`id`),
  KEY `idx_lock_app` (`application_id`),
  KEY `idx_lock_record` (`record_id`),
  KEY `idx_lock_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发布锁';

-- 30. 审批记录表
CREATE TABLE IF NOT EXISTS `approval_records` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `record_id` bigint unsigned NOT NULL COMMENT '关联的部署记录ID',
  `approver_id` bigint unsigned NOT NULL COMMENT '审批人ID',
  `approver_name` varchar(100) DEFAULT '' COMMENT '审批人',
  `action` varchar(20) NOT NULL COMMENT '操作: approve/reject',
  `comment` text COMMENT '审批意见',
  PRIMARY KEY (`id`),
  KEY `idx_approval_record` (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批记录';

-- ============================================
-- 健康检查相关表
-- ============================================

-- 31. 健康检查配置表
CREATE TABLE IF NOT EXISTS `health_check_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '检查名称',
  `type` varchar(50) DEFAULT 'http' COMMENT '检查类型: http/tcp/ssl_cert/dns',
  `url` varchar(500) NOT NULL COMMENT '检查URL',
  `method` varchar(10) DEFAULT 'GET' COMMENT '请求方法',
  `headers` text COMMENT '请求头JSON',
  `body` text COMMENT '请求体',
  `expected_status` int DEFAULT 200 COMMENT '期望状态码',
  `expected_body` varchar(500) DEFAULT '' COMMENT '期望响应体包含',
  `timeout` int DEFAULT 10 COMMENT '超时时间(秒)',
  `interval` int DEFAULT 60 COMMENT '检查间隔(秒)',
  `enabled` tinyint(1) DEFAULT 1,
  `last_status` varchar(20) DEFAULT 'unknown' COMMENT '最后检查状态',
  `last_checked_at` datetime(3) DEFAULT NULL COMMENT '最后检查时间',
  `cert_days_remaining` int DEFAULT NULL COMMENT 'SSL证书剩余天数',
  `last_alert_level` varchar(20) DEFAULT NULL COMMENT '最后告警级别: info/warning/error/critical',
  `alert_config_id` bigint unsigned DEFAULT NULL COMMENT '告警配置ID',
  `description` varchar(500) DEFAULT '',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_hcc_enabled` (`enabled`),
  KEY `idx_hcc_type` (`type`),
  KEY `idx_hcc_last_status` (`last_status`),
  KEY `idx_hcc_cert_days` (`cert_days_remaining`),
  KEY `idx_hcc_alert_level` (`last_alert_level`),
  KEY `idx_hcc_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='健康检查配置';

-- 32. 健康检查历史表
CREATE TABLE IF NOT EXISTS `health_check_histories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `config_id` bigint unsigned NOT NULL COMMENT '检查配置ID',
  `status` varchar(20) DEFAULT 'success' COMMENT '状态: success/failed',
  `status_code` int DEFAULT 0 COMMENT '响应状态码',
  `response_time` int DEFAULT 0 COMMENT '响应时间(ms)',
  `error_msg` text COMMENT '错误信息',
  `checked_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '检查时间',
  PRIMARY KEY (`id`),
  KEY `idx_hch_config` (`config_id`),
  KEY `idx_hch_status` (`status`),
  KEY `idx_hch_checked` (`checked_at`),
  KEY `idx_hch_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='健康检查历史';

-- ============================================
-- RBAC 权限相关表
-- ============================================

-- 33. 角色表
CREATE TABLE IF NOT EXISTS `roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(50) NOT NULL COMMENT '角色名称',
  `display_name` varchar(100) DEFAULT '' COMMENT '显示名称',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `is_system` tinyint(1) DEFAULT 0 COMMENT '是否系统内置角色',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_role_name` (`name`),
  KEY `idx_role_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色';

-- 34. 权限表
CREATE TABLE IF NOT EXISTS `permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '权限名称',
  `display_name` varchar(200) DEFAULT '' COMMENT '显示名称',
  `resource` varchar(100) NOT NULL COMMENT '资源',
  `action` varchar(50) NOT NULL COMMENT '操作: read/write/delete/admin',
  `description` varchar(500) DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_perm_name` (`name`),
  KEY `idx_perm_resource` (`resource`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限';

-- 35. 角色权限关联表
CREATE TABLE IF NOT EXISTS `role_permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `role_id` bigint unsigned NOT NULL COMMENT '角色ID',
  `permission_id` bigint unsigned NOT NULL COMMENT '权限ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_rp_role_perm` (`role_id`, `permission_id`),
  KEY `idx_rp_permission` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联';

-- 36. 用户角色关联表
CREATE TABLE IF NOT EXISTS `user_roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `role_id` bigint unsigned NOT NULL COMMENT '角色ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_ur_user_role` (`user_id`, `role_id`),
  KEY `idx_ur_role` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色关联';

-- ============================================
-- 审批规则与审批链相关表
-- ============================================

-- 37. 审批规则表
CREATE TABLE IF NOT EXISTS `approval_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `app_id` bigint unsigned DEFAULT 0 COMMENT '应用ID，0表示全局规则',
  `env` varchar(50) NOT NULL COMMENT '环境: dev/test/staging/prod/*',
  `need_approval` tinyint(1) DEFAULT 1 COMMENT '是否需要审批',
  `approvers` varchar(500) DEFAULT '' COMMENT '审批人ID列表，逗号分隔',
  `timeout_minutes` int DEFAULT 30 COMMENT '审批超时时间(分钟)',
  `enabled` tinyint(1) DEFAULT 1,
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_rule_app_env` (`app_id`, `env`),
  KEY `idx_rule_env` (`env`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批规则';

-- 38. 发布窗口表
CREATE TABLE IF NOT EXISTS `deploy_windows` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `app_id` bigint unsigned DEFAULT 0 COMMENT '应用ID，0表示全局',
  `env` varchar(50) NOT NULL COMMENT '环境',
  `weekdays` varchar(50) DEFAULT '1,2,3,4,5' COMMENT '允许发布的星期，1-7',
  `start_time` varchar(10) DEFAULT '10:00' COMMENT '开始时间',
  `end_time` varchar(10) DEFAULT '18:00' COMMENT '结束时间',
  `allow_emergency` tinyint(1) DEFAULT 1 COMMENT '是否允许紧急发布',
  `enabled` tinyint(1) DEFAULT 1,
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_window_app_env` (`app_id`, `env`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='发布窗口';

-- 39. 审批链表
CREATE TABLE IF NOT EXISTS `approval_chains` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '审批链名称',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `app_id` bigint unsigned DEFAULT 0 COMMENT '应用ID，0表示全局',
  `env` varchar(50) DEFAULT '*' COMMENT '环境，*表示所有环境',
  `priority` int DEFAULT 0 COMMENT '优先级，数值越大优先级越高',
  `timeout_minutes` int DEFAULT 60 COMMENT '默认超时时间(分钟)',
  `timeout_action` varchar(20) DEFAULT 'auto_cancel' COMMENT '超时策略: auto_approve/auto_reject/auto_cancel',
  `allow_emergency` tinyint(1) DEFAULT 1 COMMENT '是否允许紧急跳过',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_chain_app_env` (`app_id`, `env`),
  KEY `idx_chain_enabled` (`enabled`),
  KEY `idx_chain_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批链';

-- 40. 审批节点表
CREATE TABLE IF NOT EXISTS `approval_nodes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `chain_id` bigint unsigned NOT NULL COMMENT '审批链ID',
  `name` varchar(100) NOT NULL COMMENT '节点名称',
  `node_order` int NOT NULL COMMENT '节点顺序，从1开始',
  `approve_mode` varchar(20) DEFAULT 'any' COMMENT '审批模式: any/all/count',
  `approve_count` int DEFAULT 1 COMMENT '当mode=count时，需要的审批人数',
  `approver_type` varchar(20) DEFAULT 'user' COMMENT '审批人类型: user/role/app_owner/team_leader',
  `approvers` varchar(500) DEFAULT '' COMMENT '审批人ID列表或角色名，逗号分隔',
  `timeout_minutes` int DEFAULT 0 COMMENT '节点超时时间，0表示继承链配置',
  `timeout_action` varchar(20) DEFAULT 'auto_reject' COMMENT '超时动作: auto_approve/auto_reject/auto_cancel',
  `reject_on_any` tinyint(1) DEFAULT 1 COMMENT '任一人拒绝是否立即拒绝整个节点',
  PRIMARY KEY (`id`),
  KEY `idx_node_chain` (`chain_id`),
  KEY `idx_node_order` (`chain_id`, `node_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批节点';

-- 41. 审批实例表
CREATE TABLE IF NOT EXISTS `approval_instances` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `record_id` bigint unsigned NOT NULL COMMENT '部署记录ID',
  `chain_id` bigint unsigned NOT NULL COMMENT '审批链ID',
  `chain_name` varchar(100) DEFAULT '' COMMENT '审批链名称（冗余）',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态: pending/approved/rejected/cancelled',
  `current_node_order` int DEFAULT 1 COMMENT '当前执行的节点顺序',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `cancel_reason` varchar(500) DEFAULT '' COMMENT '取消原因',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_instance_record` (`record_id`),
  KEY `idx_instance_status` (`status`),
  KEY `idx_instance_chain` (`chain_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批实例';

-- 42. 节点实例表
CREATE TABLE IF NOT EXISTS `approval_node_instances` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `instance_id` bigint unsigned NOT NULL COMMENT '审批实例ID',
  `node_id` bigint unsigned NOT NULL COMMENT '审批节点ID',
  `node_name` varchar(100) DEFAULT '' COMMENT '节点名称（冗余）',
  `node_order` int NOT NULL COMMENT '节点顺序',
  `approve_mode` varchar(20) DEFAULT 'any' COMMENT '审批模式',
  `approve_count` int DEFAULT 1 COMMENT '需要的审批人数',
  `approver_type` varchar(20) DEFAULT 'user' COMMENT '审批人类型: user/role/app_owner/team_leader',
  `approvers` varchar(500) DEFAULT '' COMMENT '审批人ID列表（实际解析后）',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态: pending/active/approved/rejected/timeout',
  `approved_count` int DEFAULT 0 COMMENT '已通过人数',
  `rejected_count` int DEFAULT 0 COMMENT '已拒绝人数',
  `reject_on_any` tinyint(1) DEFAULT 1 COMMENT '任一人拒绝是否立即拒绝',
  `timeout_action` varchar(20) DEFAULT 'auto_reject' COMMENT '超时动作: auto_approve/auto_reject/auto_cancel',
  `activated_at` datetime(3) DEFAULT NULL COMMENT '激活时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `timeout_at` datetime(3) DEFAULT NULL COMMENT '超时时间',
  PRIMARY KEY (`id`),
  KEY `idx_node_instance` (`instance_id`),
  KEY `idx_node_status` (`status`),
  KEY `idx_node_timeout` (`timeout_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='节点实例';

-- 43. 审批动作表
CREATE TABLE IF NOT EXISTS `approval_actions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `node_instance_id` bigint unsigned NOT NULL COMMENT '节点实例ID',
  `user_id` bigint unsigned NOT NULL COMMENT '操作人ID',
  `user_name` varchar(100) DEFAULT '' COMMENT '操作人姓名',
  `action` varchar(20) NOT NULL COMMENT '动作: approve/reject/transfer',
  `comment` text COMMENT '审批意见',
  `transfer_to` bigint unsigned DEFAULT NULL COMMENT '转交目标用户ID',
  `transfer_to_name` varchar(100) DEFAULT '' COMMENT '转交目标用户姓名',
  PRIMARY KEY (`id`),
  KEY `idx_action_node` (`node_instance_id`),
  KEY `idx_action_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批动作';

-- ============================================
-- 流水线模板相关表
-- ============================================

-- 44. 流水线模板表
CREATE TABLE IF NOT EXISTS `pipeline_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '模板名称',
  `description` varchar(500) DEFAULT NULL COMMENT '模板描述',
  `category` varchar(50) DEFAULT NULL COMMENT '模板分类: build, deploy, test, release',
  `language` varchar(50) DEFAULT NULL COMMENT '编程语言: java, go, nodejs, python',
  `framework` varchar(50) DEFAULT NULL COMMENT '框架: spring, gin, express, django',
  `config_json` json NOT NULL COMMENT '流水线配置',
  `icon_url` varchar(500) DEFAULT NULL COMMENT '图标URL',
  `is_builtin` tinyint(1) DEFAULT 0 COMMENT '是否内置模板',
  `is_public` tinyint(1) DEFAULT 1 COMMENT '是否公开',
  `usage_count` int DEFAULT 0 COMMENT '使用次数',
  `rating` decimal(3,2) DEFAULT 0 COMMENT '评分',
  `rating_count` int DEFAULT 0 COMMENT '评分人数',
  `created_by` varchar(100) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_name` (`name`),
  KEY `idx_category` (`category`),
  KEY `idx_language` (`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水线模板表';

-- 45. 模板评分表
CREATE TABLE IF NOT EXISTS `pipeline_template_ratings` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `template_id` bigint unsigned NOT NULL COMMENT '模板ID',
  `user_id` int unsigned NOT NULL COMMENT '用户ID',
  `rating` tinyint NOT NULL COMMENT '评分(1-5)',
  `comment` varchar(500) DEFAULT NULL COMMENT '评价',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_user` (`template_id`, `user_id`),
  KEY `idx_template_id` (`template_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='模板评分表';

-- 46. 阶段模板表
CREATE TABLE IF NOT EXISTS `pipeline_stage_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '阶段名称',
  `description` varchar(500) DEFAULT NULL COMMENT '阶段描述',
  `category` varchar(50) DEFAULT NULL COMMENT '分类: source, build, test, deploy, notify',
  `icon_name` varchar(50) DEFAULT NULL COMMENT '图标名称',
  `color` varchar(20) DEFAULT NULL COMMENT '颜色',
  `config_json` json DEFAULT NULL COMMENT '默认配置',
  `is_builtin` tinyint(1) DEFAULT 1 COMMENT '是否内置',
  `sort_order` int DEFAULT 0 COMMENT '排序',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='阶段模板表';

-- 47. 步骤模板表
CREATE TABLE IF NOT EXISTS `pipeline_step_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '步骤名称',
  `description` varchar(500) DEFAULT NULL COMMENT '步骤描述',
  `step_type` varchar(50) NOT NULL COMMENT '步骤类型: git, shell, docker_build, k8s_deploy',
  `category` varchar(50) DEFAULT NULL COMMENT '分类',
  `icon_name` varchar(50) DEFAULT NULL COMMENT '图标名称',
  `config_schema` json DEFAULT NULL COMMENT '配置Schema',
  `default_json` json DEFAULT NULL COMMENT '默认配置',
  `is_builtin` tinyint(1) DEFAULT 1 COMMENT '是否内置',
  `sort_order` int DEFAULT 0 COMMENT '排序',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_step_type` (`step_type`),
  KEY `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='步骤模板表';

-- ============================================
-- 构建优化与制品管理相关表
-- ============================================

-- 48. 构建缓存表
CREATE TABLE IF NOT EXISTS `build_caches` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pipeline_id` bigint unsigned NOT NULL COMMENT '流水线ID',
  `cache_key` varchar(255) NOT NULL COMMENT '缓存键',
  `cache_type` varchar(50) DEFAULT NULL COMMENT '缓存类型: maven, npm, go, pip, docker_layer',
  `cache_path` varchar(500) DEFAULT NULL COMMENT '缓存路径',
  `size_bytes` bigint DEFAULT 0 COMMENT '缓存大小(字节)',
  `hit_count` int DEFAULT 0 COMMENT '命中次数',
  `last_hit_at` datetime(3) DEFAULT NULL COMMENT '最后命中时间',
  `expire_at` datetime(3) DEFAULT NULL COMMENT '过期时间',
  `storage_type` varchar(50) DEFAULT 'local' COMMENT '存储类型: local, s3, oss',
  `storage_url` varchar(500) DEFAULT NULL COMMENT '存储URL',
  `checksum` varchar(64) DEFAULT NULL COMMENT '校验和',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cache_key` (`cache_key`),
  KEY `idx_pipeline_id` (`pipeline_id`),
  KEY `idx_expire_at` (`expire_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='构建缓存表';

-- 49. 构建资源配额表
CREATE TABLE IF NOT EXISTS `build_resource_quotas` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '配额名称',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `project_id` bigint unsigned DEFAULT NULL COMMENT '项目ID(空表示全局)',
  `max_cpu` varchar(20) DEFAULT '2' COMMENT '最大CPU',
  `max_memory` varchar(20) DEFAULT '4Gi' COMMENT '最大内存',
  `max_storage` varchar(20) DEFAULT '10Gi' COMMENT '最大存储',
  `max_concurrent` int DEFAULT 5 COMMENT '最大并发构建数',
  `max_duration` int DEFAULT 3600 COMMENT '最大构建时长(秒)',
  `priority` int DEFAULT 0 COMMENT '优先级',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认配额',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_name` (`name`),
  KEY `idx_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='构建资源配额表';

-- 50. 构建资源使用记录表
CREATE TABLE IF NOT EXISTS `build_resource_usages` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pipeline_id` bigint unsigned NOT NULL COMMENT '流水线ID',
  `run_id` bigint unsigned NOT NULL COMMENT '执行ID',
  `quota_id` bigint unsigned DEFAULT NULL COMMENT '配额ID',
  `cpu_used` varchar(20) DEFAULT NULL COMMENT 'CPU使用量',
  `memory_used` varchar(20) DEFAULT NULL COMMENT '内存使用量',
  `storage_used` varchar(20) DEFAULT NULL COMMENT '存储使用量',
  `duration_sec` int DEFAULT NULL COMMENT '构建时长(秒)',
  `cache_hit` tinyint(1) DEFAULT 0 COMMENT '是否命中缓存',
  `cache_saved` bigint DEFAULT 0 COMMENT '缓存节省时间(秒)',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `completed_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_pipeline_id` (`pipeline_id`),
  KEY `idx_run_id` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='构建资源使用记录表';

-- 51. 并行构建配置表
CREATE TABLE IF NOT EXISTS `parallel_build_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pipeline_id` bigint unsigned NOT NULL COMMENT '流水线ID',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用并行构建',
  `max_parallel` int DEFAULT 3 COMMENT '最大并行数',
  `fail_fast` tinyint(1) DEFAULT 1 COMMENT '快速失败',
  `parallel_stages` json DEFAULT NULL COMMENT '可并行的阶段',
  `dependency_graph` json DEFAULT NULL COMMENT '依赖图',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pipeline_id` (`pipeline_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='并行构建配置表';

-- 52. 制品仓库表
CREATE TABLE IF NOT EXISTS `artifact_repositories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT '仓库名称',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `type` varchar(50) NOT NULL COMMENT '仓库类型: docker, maven, npm, pypi, generic',
  `url` varchar(500) NOT NULL COMMENT '仓库地址',
  `username` varchar(100) DEFAULT NULL COMMENT '用户名',
  `password` varchar(500) DEFAULT NULL COMMENT '密码(加密)',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认仓库',
  `is_public` tinyint(1) DEFAULT 0 COMMENT '是否公开',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `connection_status` varchar(20) DEFAULT 'unknown' COMMENT '连接状态: connected/disconnected/checking/unknown',
  `created_by` varchar(100) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `last_check_at` datetime(3) DEFAULT NULL COMMENT '最后检查时间',
  `last_error` text COMMENT '最后错误信息',
  `enable_monitoring` tinyint(1) DEFAULT 1 COMMENT '是否启用监控',
  `check_interval` int DEFAULT 300 COMMENT '检查间隔(秒)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_name` (`name`),
  KEY `idx_type` (`type`),
  KEY `idx_connection_status` (`connection_status`),
  KEY `idx_enable_monitoring` (`enable_monitoring`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='制品仓库表';

-- 53. 制品仓库连接历史表
CREATE TABLE IF NOT EXISTS `artifact_registry_connection_history` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `registry_id` bigint unsigned NOT NULL COMMENT '仓库ID',
  `check_time` datetime(3) NOT NULL COMMENT '检查时间',
  `status` varchar(20) NOT NULL COMMENT '状态: ok/error/timeout',
  `latency_ms` int DEFAULT NULL COMMENT '延迟(ms)',
  `message` varchar(500) DEFAULT NULL COMMENT '消息',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_registry_id` (`registry_id`),
  KEY `idx_check_time` (`check_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='制品仓库连接历史';

-- 54. 制品表
CREATE TABLE IF NOT EXISTS `artifacts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `repository_id` bigint unsigned NOT NULL COMMENT '仓库ID',
  `name` varchar(200) NOT NULL COMMENT '制品名称',
  `group_id` varchar(200) DEFAULT NULL COMMENT '组ID(Maven)',
  `artifact_id` varchar(200) DEFAULT NULL COMMENT '制品ID(Maven)',
  `type` varchar(50) DEFAULT NULL COMMENT '制品类型: jar, war, docker, npm, wheel',
  `description` varchar(500) DEFAULT NULL COMMENT '描述',
  `latest_ver` varchar(100) DEFAULT NULL COMMENT '最新版本',
  `download_count` bigint DEFAULT 0 COMMENT '下载次数',
  `tags` varchar(500) DEFAULT NULL COMMENT '标签(逗号分隔)',
  `created_by` varchar(100) DEFAULT NULL COMMENT '创建人',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_repository_id` (`repository_id`),
  KEY `idx_name` (`name`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_artifact_id` (`artifact_id`),
  KEY `idx_artifacts_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='制品表';

-- 55. 制品版本表
CREATE TABLE IF NOT EXISTS `artifact_versions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `artifact_id` bigint unsigned NOT NULL COMMENT '制品ID',
  `version` varchar(100) NOT NULL COMMENT '版本号',
  `size_bytes` bigint DEFAULT 0 COMMENT '大小(字节)',
  `checksum` varchar(64) DEFAULT NULL COMMENT 'SHA256校验和',
  `download_url` varchar(500) DEFAULT NULL COMMENT '下载地址',
  `metadata` json DEFAULT NULL COMMENT '元数据',
  `pipeline_id` bigint unsigned DEFAULT NULL COMMENT '来源流水线ID',
  `run_id` bigint unsigned DEFAULT NULL COMMENT '来源执行ID',
  `git_commit` varchar(64) DEFAULT NULL COMMENT 'Git提交',
  `git_branch` varchar(100) DEFAULT NULL COMMENT 'Git分支',
  `build_number` int DEFAULT NULL COMMENT '构建号',
  `download_count` bigint DEFAULT 0 COMMENT '下载次数',
  `scan_status` varchar(20) DEFAULT 'pending' COMMENT '扫描状态: pending/scanning/passed/failed',
  `scan_result` json DEFAULT NULL COMMENT '扫描结果',
  `is_release` tinyint(1) DEFAULT 0 COMMENT '是否正式版本',
  `released_at` datetime(3) DEFAULT NULL COMMENT '发布时间',
  `released_by` varchar(100) DEFAULT NULL COMMENT '发布人',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_artifact_id` (`artifact_id`),
  KEY `idx_version` (`version`),
  KEY `idx_pipeline_id` (`pipeline_id`),
  KEY `idx_run_id` (`run_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='制品版本表';

-- 56. 制品扫描结果表
CREATE TABLE IF NOT EXISTS `artifact_scan_results` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `version_id` bigint unsigned NOT NULL COMMENT '版本ID',
  `scan_type` varchar(50) NOT NULL COMMENT '扫描类型: vulnerability, license, quality',
  `scanner` varchar(50) DEFAULT NULL COMMENT '扫描器: trivy, sonarqube',
  `status` varchar(20) DEFAULT NULL COMMENT '状态: passed, failed, warning',
  `critical_count` int DEFAULT 0 COMMENT '严重漏洞数',
  `high_count` int DEFAULT 0 COMMENT '高危漏洞数',
  `medium_count` int DEFAULT 0 COMMENT '中危漏洞数',
  `low_count` int DEFAULT 0 COMMENT '低危漏洞数',
  `details` json DEFAULT NULL COMMENT '详细结果',
  `report_url` varchar(500) DEFAULT NULL COMMENT '报告URL',
  `scanned_at` datetime(3) DEFAULT NULL COMMENT '扫描时间',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_version_id` (`version_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='制品扫描结果表';

-- 57. 制品晋级记录表
CREATE TABLE IF NOT EXISTS `artifact_promotions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `version_id` bigint unsigned NOT NULL COMMENT '版本ID',
  `from_repo_id` bigint unsigned DEFAULT NULL COMMENT '源仓库ID',
  `to_repo_id` bigint unsigned DEFAULT NULL COMMENT '目标仓库ID',
  `from_env` varchar(50) DEFAULT NULL COMMENT '源环境: dev, test, staging',
  `to_env` varchar(50) DEFAULT NULL COMMENT '目标环境: test, staging, prod',
  `status` varchar(20) DEFAULT NULL COMMENT '状态: pending, approved, rejected, completed',
  `approval_id` bigint unsigned DEFAULT NULL COMMENT '审批ID',
  `promoted_by` varchar(100) DEFAULT NULL COMMENT '晋级人',
  `promoted_at` datetime(3) DEFAULT NULL COMMENT '晋级时间',
  `comment` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_version_id` (`version_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='制品晋级记录表';

-- ============================================
-- 流量治理相关表
-- ============================================

-- 58. 限流规则表
CREATE TABLE IF NOT EXISTS `traffic_ratelimit_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `name` varchar(100) NOT NULL COMMENT '规则名称',
  `description` varchar(500) DEFAULT NULL COMMENT '规则描述',
  `resource_type` enum('api','service','method') DEFAULT 'api' COMMENT '资源类型',
  `resource` varchar(500) NOT NULL COMMENT '资源标识',
  `method` varchar(10) DEFAULT NULL COMMENT '请求方法',
  `strategy` enum('qps','concurrent','token_bucket','leaky_bucket') DEFAULT 'qps' COMMENT '限流策略',
  `threshold` int NOT NULL DEFAULT 100 COMMENT '阈值',
  `burst` int DEFAULT 10 COMMENT '突发容量(令牌桶)',
  `queue_size` int DEFAULT 100 COMMENT '队列大小(漏桶)',
  `control_behavior` enum('reject','warm_up','queue','warm_up_queue') DEFAULT 'reject' COMMENT '超限行为',
  `warm_up_period` int DEFAULT 10 COMMENT '预热时长(秒)',
  `max_queue_time` int DEFAULT 500 COMMENT '最大排队时间(毫秒)',
  `limit_dimensions` json DEFAULT NULL COMMENT '限流维度',
  `limit_header` varchar(100) DEFAULT NULL COMMENT '限流Header名',
  `rejected_code` int DEFAULT 429 COMMENT '拒绝状态码',
  `rejected_message` varchar(500) DEFAULT 'Too Many Requests' COMMENT '拒绝消息',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `priority` int DEFAULT 100 COMMENT '优先级',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_resource` (`resource`(100)),
  KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='限流规则表';

-- 59. 熔断规则表
CREATE TABLE IF NOT EXISTS `traffic_circuitbreaker_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `name` varchar(100) NOT NULL COMMENT '规则名称',
  `resource` varchar(500) NOT NULL COMMENT '资源标识',
  `strategy` enum('slow_request','error_ratio','error_count') DEFAULT 'slow_request' COMMENT '熔断策略',
  `slow_rt_threshold` int DEFAULT 1000 COMMENT '慢调用RT阈值(毫秒)',
  `threshold` decimal(5,2) NOT NULL COMMENT '阈值',
  `stat_interval` int DEFAULT 10 COMMENT '统计窗口(秒)',
  `min_request_amount` int DEFAULT 5 COMMENT '最小请求数',
  `recovery_timeout` int DEFAULT 30 COMMENT '熔断时长(秒)',
  `probe_num` int DEFAULT 3 COMMENT '半开探测请求数',
  `fallback_strategy` enum('return_error','return_default','call_fallback') DEFAULT 'return_error' COMMENT '降级策略',
  `fallback_value` text DEFAULT NULL COMMENT '降级返回值(JSON)',
  `fallback_service` varchar(200) DEFAULT NULL COMMENT '降级服务地址',
  `circuit_status` enum('closed','open','half_open') DEFAULT 'closed' COMMENT '熔断状态',
  `last_open_time` datetime(3) DEFAULT NULL COMMENT '上次熔断时间',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_resource` (`resource`(100)),
  KEY `idx_status` (`circuit_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='熔断规则表';

-- 60. 流量路由规则表
CREATE TABLE IF NOT EXISTS `traffic_routing_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `name` varchar(100) NOT NULL COMMENT '规则名称',
  `description` varchar(500) DEFAULT NULL COMMENT '规则描述',
  `priority` int DEFAULT 100 COMMENT '优先级',
  `route_type` enum('weight','header','cookie','param') DEFAULT 'weight' COMMENT '路由类型',
  `destinations` json DEFAULT NULL COMMENT '目标配置',
  `match_key` varchar(100) DEFAULT NULL COMMENT '匹配键',
  `match_operator` enum('exact','prefix','regex','present') DEFAULT 'exact' COMMENT '匹配方式',
  `match_value` varchar(500) DEFAULT NULL COMMENT '匹配值',
  `target_subset` varchar(100) DEFAULT NULL COMMENT '目标子集/版本',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_priority` (`priority`),
  KEY `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流量路由规则表';

-- 61. 负载均衡配置表
CREATE TABLE IF NOT EXISTS `traffic_loadbalance_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL UNIQUE COMMENT '应用ID',
  `lb_policy` enum('round_robin','random','least_request','consistent_hash','passthrough') DEFAULT 'round_robin' COMMENT '负载均衡算法',
  `hash_key` varchar(20) DEFAULT NULL COMMENT '哈希键类型',
  `hash_key_name` varchar(100) DEFAULT NULL COMMENT '哈希键名称',
  `ring_size` int DEFAULT 1024 COMMENT '一致性哈希环大小',
  `choice_count` int DEFAULT 2 COMMENT '最少请求选择数量',
  `warmup_duration` varchar(20) DEFAULT '60s' COMMENT '预热时间',
  `health_check_enabled` tinyint(1) DEFAULT 0 COMMENT '是否启用健康检查',
  `health_check_path` varchar(200) DEFAULT '/health' COMMENT '健康检查路径',
  `health_check_interval` varchar(20) DEFAULT '10s' COMMENT '检查间隔',
  `health_check_timeout` varchar(20) DEFAULT '5s' COMMENT '检查超时',
  `healthy_threshold` int DEFAULT 2 COMMENT '健康阈值',
  `unhealthy_threshold` int DEFAULT 3 COMMENT '不健康阈值',
  `http_max_connections` int DEFAULT 1024 COMMENT 'HTTP最大连接数',
  `http_max_requests_per_conn` int DEFAULT 0 COMMENT '每连接最大请求数',
  `http_max_pending_requests` int DEFAULT 1024 COMMENT '最大等待请求数',
  `http_max_retries` int DEFAULT 3 COMMENT '最大重试次数',
  `http_idle_timeout` varchar(20) DEFAULT '1h' COMMENT 'HTTP空闲超时',
  `tcp_max_connections` int DEFAULT 1024 COMMENT 'TCP最大连接数',
  `tcp_connect_timeout` varchar(20) DEFAULT '10s' COMMENT 'TCP连接超时',
  `tcp_keepalive_enabled` tinyint(1) DEFAULT 1 COMMENT 'TCP Keepalive',
  `tcp_keepalive_interval` varchar(20) DEFAULT '60s' COMMENT 'Keepalive间隔',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='负载均衡配置表';

-- 62. 超时重试配置表
CREATE TABLE IF NOT EXISTS `traffic_timeout_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL UNIQUE COMMENT '应用ID',
  `timeout` varchar(20) DEFAULT '30s' COMMENT '请求超时',
  `retries` int DEFAULT 3 COMMENT '重试次数',
  `per_try_timeout` varchar(20) DEFAULT '10s' COMMENT '单次重试超时',
  `retry_on` json DEFAULT NULL COMMENT '重试条件',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='超时重试配置表';

-- 63. 流量镜像规则表
CREATE TABLE IF NOT EXISTS `traffic_mirror_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `target_service` varchar(200) NOT NULL COMMENT '目标服务',
  `target_subset` varchar(100) DEFAULT NULL COMMENT '目标子集',
  `percentage` int DEFAULT 100 COMMENT '镜像比例(1-100)',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流量镜像规则表';

-- 64. 故障注入规则表
CREATE TABLE IF NOT EXISTS `traffic_fault_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `type` enum('delay','abort') DEFAULT 'delay' COMMENT '故障类型',
  `path` varchar(500) DEFAULT '/' COMMENT '接口路径',
  `delay_duration` varchar(20) DEFAULT '5s' COMMENT '延迟时间',
  `abort_code` int DEFAULT 500 COMMENT 'HTTP状态码',
  `abort_message` varchar(500) DEFAULT NULL COMMENT '错误消息',
  `percentage` int DEFAULT 10 COMMENT '影响比例(1-100)',
  `enabled` tinyint(1) DEFAULT 0 COMMENT '是否启用',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='故障注入规则表';

-- 65. 流量治理操作日志表
CREATE TABLE IF NOT EXISTS `traffic_operation_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `app_id` bigint NOT NULL COMMENT '应用ID',
  `rule_type` varchar(50) NOT NULL COMMENT '规则类型',
  `rule_id` bigint DEFAULT NULL COMMENT '规则ID',
  `operation` varchar(50) NOT NULL COMMENT '操作类型',
  `operator` varchar(100) DEFAULT NULL COMMENT '操作人',
  `old_value` json DEFAULT NULL COMMENT '旧值',
  `new_value` json DEFAULT NULL COMMENT '新值',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_rule_type` (`rule_type`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流量治理操作日志表';

-- ============================================
-- 流量监控与灰度发布相关表
-- ============================================

-- 66. 流量统计表
CREATE TABLE IF NOT EXISTS `traffic_statistics` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `timestamp` datetime NOT NULL COMMENT '统计时间',
  `total_requests` bigint DEFAULT 0 COMMENT '总请求数',
  `success_requests` bigint DEFAULT 0 COMMENT '成功请求数',
  `failed_requests` bigint DEFAULT 0 COMMENT '失败请求数',
  `rate_limited_count` bigint DEFAULT 0 COMMENT '限流次数',
  `circuit_break_count` bigint DEFAULT 0 COMMENT '熔断次数',
  `avg_latency_ms` double DEFAULT 0 COMMENT '平均延迟(ms)',
  `p50_latency_ms` double DEFAULT 0 COMMENT 'P50延迟(ms)',
  `p90_latency_ms` double DEFAULT 0 COMMENT 'P90延迟(ms)',
  `p99_latency_ms` double DEFAULT 0 COMMENT 'P99延迟(ms)',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_timestamp` (`app_id`,`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流量统计表';

-- 67. 规则版本表
CREATE TABLE IF NOT EXISTS `traffic_rule_versions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `rule_type` varchar(50) NOT NULL COMMENT '规则类型',
  `rule_id` bigint unsigned NOT NULL COMMENT '规则ID',
  `version` int NOT NULL COMMENT '版本号',
  `content` json NOT NULL COMMENT '规则内容',
  `operator` varchar(100) DEFAULT NULL COMMENT '操作人',
  `description` varchar(500) DEFAULT NULL COMMENT '版本描述',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_rule` (`rule_type`,`rule_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='规则版本表';

-- 68. 金丝雀发布配置表
CREATE TABLE IF NOT EXISTS `canary_releases` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `name` varchar(100) NOT NULL COMMENT '发布名称',
  `env_name` varchar(50) DEFAULT '' COMMENT '环境名称',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态',
  `stable_version` varchar(100) DEFAULT NULL COMMENT '稳定版本',
  `canary_version` varchar(100) DEFAULT NULL COMMENT '金丝雀版本',
  `current_weight` int DEFAULT 0 COMMENT '当前金丝雀权重',
  `target_weight` int DEFAULT 100 COMMENT '目标权重',
  `weight_increment` int DEFAULT 10 COMMENT '权重增量',
  `interval_seconds` int DEFAULT 60 COMMENT '增量间隔(秒)',
  `success_threshold` double DEFAULT 95 COMMENT '成功率阈值',
  `latency_threshold` int DEFAULT 500 COMMENT '延迟阈值(ms)',
  `auto_rollback` tinyint(1) DEFAULT 1 COMMENT '自动回滚',
  `started_at` datetime DEFAULT NULL COMMENT '开始时间',
  `completed_at` datetime DEFAULT NULL COMMENT '完成时间',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_status` (`status`),
  KEY `idx_env_name` (`env_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='金丝雀发布配置表';

-- 69. 蓝绿部署配置表
CREATE TABLE IF NOT EXISTS `blue_green_deployments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `name` varchar(100) NOT NULL COMMENT '部署名称',
  `env_name` varchar(50) DEFAULT '' COMMENT '环境名称',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态',
  `blue_version` varchar(100) DEFAULT NULL COMMENT '蓝版本',
  `green_version` varchar(100) DEFAULT NULL COMMENT '绿版本',
  `active_color` varchar(10) DEFAULT 'blue' COMMENT '当前活跃: blue/green',
  `replicas` int DEFAULT 2 COMMENT '副本数',
  `warmup_seconds` int DEFAULT 30 COMMENT '预热时间(秒)',
  `switched_at` datetime DEFAULT NULL COMMENT '切换时间',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_app_id` (`app_id`),
  KEY `idx_status` (`status`),
  KEY `idx_env_name` (`env_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='蓝绿部署配置表';

-- ============================================
-- AI Copilot 相关表
-- ============================================

-- 70. AI 会话表
CREATE TABLE IF NOT EXISTS `ai_conversations` (
  `id` varchar(36) NOT NULL COMMENT '会话UUID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `title` varchar(255) DEFAULT '' COMMENT '会话标题',
  `context` json DEFAULT NULL COMMENT '页面上下文JSON',
  `message_count` int DEFAULT 0 COMMENT '消息数量',
  `last_message_at` datetime(3) DEFAULT NULL COMMENT '最后消息时间',
  `deleted_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_ai_conv_user_id` (`user_id`),
  KEY `idx_ai_conv_deleted_at` (`deleted_at`),
  KEY `idx_ai_conv_last_message` (`last_message_at`),
  CONSTRAINT `fk_ai_conv_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI会话表';

-- 71. AI 消息表
CREATE TABLE IF NOT EXISTS `ai_messages` (
  `id` varchar(36) NOT NULL COMMENT '消息UUID',
  `conversation_id` varchar(36) NOT NULL COMMENT '会话ID',
  `role` enum('user','assistant','system','tool') NOT NULL COMMENT '消息角色',
  `content` text NOT NULL COMMENT '消息内容',
  `tool_calls` json DEFAULT NULL COMMENT '工具调用信息JSON',
  `tool_call_id` varchar(100) DEFAULT '' COMMENT '工具调用ID',
  `token_count` int DEFAULT 0 COMMENT 'Token数量',
  `status` varchar(20) DEFAULT 'complete' COMMENT '状态: pending/streaming/complete/error',
  `error_msg` text COMMENT '错误信息',
  `feedback_rating` varchar(20) DEFAULT NULL COMMENT '反馈评分: like/dislike',
  `feedback_comment` text COMMENT '反馈评论',
  `feedback_at` datetime(3) DEFAULT NULL COMMENT '反馈时间',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_ai_msg_conversation` (`conversation_id`),
  KEY `idx_ai_msg_created` (`created_at`),
  KEY `idx_ai_msg_role` (`role`),
  KEY `idx_ai_msg_feedback` (`feedback_rating`),
  CONSTRAINT `fk_ai_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `ai_conversations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI消息表';

-- 72. AI 知识库表
CREATE TABLE IF NOT EXISTS `ai_knowledge` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL COMMENT '知识标题',
  `content` text NOT NULL COMMENT '知识内容(Markdown)',
  `category` varchar(50) NOT NULL COMMENT '分类',
  `tags` json DEFAULT NULL COMMENT '标签列表JSON',
  `embedding` blob DEFAULT NULL COMMENT '向量嵌入',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `view_count` int DEFAULT 0 COMMENT '查看次数',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  `updated_by` bigint unsigned DEFAULT NULL COMMENT '更新人ID',
  `deleted_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_ai_knowledge_category` (`category`),
  KEY `idx_ai_knowledge_deleted_at` (`deleted_at`),
  KEY `idx_ai_knowledge_active` (`is_active`),
  FULLTEXT KEY `idx_ai_knowledge_fulltext` (`title`,`content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI知识库表';

-- 73. AI 操作审计日志表
CREATE TABLE IF NOT EXISTS `ai_operation_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `username` varchar(100) DEFAULT '' COMMENT '用户名',
  `conversation_id` varchar(36) DEFAULT NULL COMMENT '会话ID',
  `message_id` varchar(36) DEFAULT NULL COMMENT '消息ID',
  `action` varchar(50) NOT NULL COMMENT '操作类型',
  `action_name` varchar(100) DEFAULT '' COMMENT '操作名称',
  `target_type` varchar(50) DEFAULT '' COMMENT '目标类型',
  `target_id` varchar(100) DEFAULT '' COMMENT '目标ID',
  `target_name` varchar(200) DEFAULT '' COMMENT '目标名称',
  `params` json DEFAULT NULL COMMENT '操作参数JSON',
  `result` json DEFAULT NULL COMMENT '操作结果JSON',
  `success` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否成功',
  `error_msg` text COMMENT '错误信息',
  `duration_ms` int DEFAULT 0 COMMENT '执行耗时(毫秒)',
  `ip_address` varchar(50) DEFAULT '' COMMENT '客户端IP',
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_ai_op_user_id` (`user_id`),
  KEY `idx_ai_op_conversation` (`conversation_id`),
  KEY `idx_ai_op_action` (`action`),
  KEY `idx_ai_op_target` (`target_type`,`target_id`),
  KEY `idx_ai_op_created` (`created_at`),
  CONSTRAINT `fk_ai_op_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI操作审计日志表';
-- 74. AI LLM 配置表
CREATE TABLE IF NOT EXISTS `ai_llm_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL COMMENT '配置名称',
  `provider` varchar(50) NOT NULL COMMENT '提供商: openai/azure/qwen/zhipu/ollama',
  `api_url` varchar(255) NOT NULL COMMENT 'API地址',
  `api_key_encrypted` varchar(512) NOT NULL COMMENT '加密的API密钥',
  `model_name` varchar(100) NOT NULL COMMENT '模型名称',
  `max_tokens` int DEFAULT 4096 COMMENT '最大Token数',
  `temperature` decimal(3,2) DEFAULT 0.70 COMMENT '温度参数',
  `timeout_seconds` int DEFAULT 60 COMMENT '请求超时时间(秒)',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认配置',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  `updated_by` bigint unsigned DEFAULT NULL COMMENT '更新人ID',
  `deleted_at` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_ai_llm_name` (`name`),
  KEY `idx_ai_llm_provider` (`provider`),
  KEY `idx_ai_llm_default` (`is_default`),
  KEY `idx_ai_llm_active` (`is_active`),
  KEY `idx_ai_llm_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI LLM配置表';

-- 75. AI 消息反馈表
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
-- 初始化数据
-- ============================================

-- 插入默认管理员用户 (密码: admin123)
INSERT IGNORE INTO `users` (`username`, `password`, `email`, `role`, `status`)
VALUES ('admin', '$2a$10$kyspA5uyJRME400vCfvk4uhFJ7eDSRhFUcFnvieKTRqCm6LXJjsVS', 'admin@example.com', 'super_admin', 'active');

-- 插入默认角色
INSERT IGNORE INTO `roles` (`name`, `display_name`, `description`, `is_system`, `status`) VALUES
('super_admin', '超级管理员', '拥有所有权限，不可被修改或删除', 1, 'active'),
('admin', '管理员', '拥有大部分管理权限', 1, 'active'),
('operator', '运维人员', '可以操作 Jenkins、K8s 等资源', 1, 'active'),
('developer', '开发者', '开发人员，可以查看和部署应用', 1, 'active'),
('viewer', '只读用户', '只能查看资源', 1, 'active'),
('user', '普通用户', '查看和基本操作权限', 1, 'active'),
('guest', '访客', '只有查看权限', 1, 'active');

-- 插入默认审批规则（生产环境需要审批）
INSERT IGNORE INTO `approval_rules` (`app_id`, `env`, `need_approval`, `approvers`, `timeout_minutes`, `enabled`, `created_by`) VALUES
(0, 'prod', 1, '', 30, 1, 1),
(0, 'production', 1, '', 30, 1, 1);

-- 插入默认发布窗口（工作日 10:00-18:00）
INSERT IGNORE INTO `deploy_windows` (`app_id`, `env`, `weekdays`, `start_time`, `end_time`, `allow_emergency`, `enabled`, `created_by`) VALUES
(0, 'prod', '1,2,3,4,5', '10:00', '18:00', 1, 1, 1),
(0, 'production', '1,2,3,4,5', '10:00', '18:00', 1, 1, 1);

-- 插入权限
INSERT IGNORE INTO `permissions` (`name`, `display_name`, `resource`, `action`, `description`, `created_at`) VALUES
('user:view', '查看用户', 'user', 'view', '查看用户列表和详情', NOW()),
('user:create', '创建用户', 'user', 'create', '创建新用户', NOW()),
('user:update', '更新用户', 'user', 'update', '更新用户信息', NOW()),
('user:delete', '删除用户', 'user', 'delete', '删除用户', NOW()),
('user:role', '修改角色', 'user', 'role', '修改用户角色', NOW()),
('user:status', '修改状态', 'user', 'status', '启用/禁用用户', NOW()),
('app:view', '查看应用', 'app', 'view', '查看应用', NOW()),
('app:create', '创建应用', 'app', 'create', '创建应用', NOW()),
('app:update', '更新应用', 'app', 'update', '更新应用', NOW()),
('app:delete', '删除应用', 'app', 'delete', '删除应用', NOW()),
('app:deploy', '发布应用', 'app', 'deploy', '发布部署', NOW()),
('approval:view', '查看审批', 'approval', 'view', '查看审批', NOW()),
('approval:create', '创建审批', 'approval', 'create', '创建审批规则', NOW()),
('approval:update', '更新审批', 'approval', 'update', '更新审批配置', NOW()),
('approval:delete', '删除审批', 'approval', 'delete', '删除审批规则', NOW()),
('k8s:view', '查看K8s', 'k8s', 'view', '查看K8s资源', NOW()),
('k8s:create', '创建K8s', 'k8s', 'create', '创建K8s配置', NOW()),
('k8s:update', '更新K8s', 'k8s', 'update', '更新K8s配置', NOW()),
('k8s:delete', '删除K8s', 'k8s', 'delete', '删除K8s配置', NOW()),
('k8s:exec', 'K8s操作', 'k8s', 'exec', '重启/扩缩容等', NOW()),
('jenkins:view', '查看Jenkins', 'jenkins', 'view', '查看Jenkins', NOW()),
('jenkins:create', '创建Jenkins', 'jenkins', 'create', '创建Jenkins', NOW()),
('jenkins:update', '更新Jenkins', 'jenkins', 'update', '更新Jenkins', NOW()),
('jenkins:delete', '删除Jenkins', 'jenkins', 'delete', '删除Jenkins', NOW()),
('jenkins:trigger', '触发构建', 'jenkins', 'trigger', '触发构建', NOW()),
('system:view', '查看系统配置', 'system', 'view', '查看系统配置', NOW()),
('system:update', '更新系统配置', 'system', 'update', '更新系统配置', NOW()),
('alert:view', '查看告警', 'alert', 'view', '查看告警', NOW()),
('alert:create', '创建告警', 'alert', 'create', '创建告警配置', NOW()),
('alert:update', '更新告警', 'alert', 'update', '更新告警配置', NOW()),
('alert:delete', '删除告警', 'alert', 'delete', '删除告警配置', NOW());

-- 角色权限关联
-- 超级管理员 - 所有权限
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r, `permissions` p WHERE r.name = 'super_admin';

-- 管理员 - 除系统配置更新外的所有权限
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r, `permissions` p
WHERE r.name = 'admin' AND p.name != 'system:update';

-- 普通用户 - 查看 + 发布 + 触发构建
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r, `permissions` p
WHERE r.name = 'user' AND p.name IN (
  'app:view', 'app:deploy', 'approval:view',
  'k8s:view', 'jenkins:view', 'jenkins:trigger', 'alert:view'
);

-- 访客 - 只有查看权限
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r, `permissions` p
WHERE r.name = 'guest' AND p.action = 'view';

-- ============================================
-- 76. OA 数据表
-- ============================================
CREATE TABLE IF NOT EXISTS `oa_data` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `unique_id` varchar(100) NOT NULL COMMENT '唯一标识',
  `source` varchar(100) DEFAULT '' COMMENT '来源OA地址名称',
  `ip_address` varchar(50) DEFAULT '' COMMENT 'IP地址',
  `user_agent` varchar(500) DEFAULT '' COMMENT 'User Agent',
  `original_data` text COMMENT '原始数据JSON',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_oa_data_unique_id` (`unique_id`),
  KEY `idx_oa_data_source` (`source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OA同步数据';

-- ============================================
-- 77. OA 地址配置表
-- ============================================
CREATE TABLE IF NOT EXISTS `oa_addresses` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '名称',
  `url` varchar(500) NOT NULL COMMENT 'URL',
  `type` varchar(50) DEFAULT 'webhook' COMMENT '类型: webhook/callback/api',
  `description` text COMMENT '描述',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT '状态: active/inactive',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_oa_addr_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OA地址配置';

-- ============================================
-- 78. OA 通知配置表
-- ============================================
CREATE TABLE IF NOT EXISTS `oa_notify_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '配置名称',
  `app_id` bigint unsigned DEFAULT NULL COMMENT '飞书应用ID',
  `receive_id` varchar(100) NOT NULL COMMENT '接收者ID',
  `receive_id_type` varchar(50) NOT NULL COMMENT 'ID类型: chat_id/open_id/user_id',
  `description` text COMMENT '描述',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT '状态: active/inactive',
  `is_default` tinyint(1) DEFAULT 0 COMMENT '是否默认',
  PRIMARY KEY (`id`),
  KEY `idx_oa_notify_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OA通知配置';


-- ============================================
-- 79. 告警静默表
-- ============================================
CREATE TABLE IF NOT EXISTS `alert_silences` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '静默名称',
  `type` varchar(50) NOT NULL COMMENT '类型',
  `matchers` text COMMENT '匹配条件JSON',
  `start_time` datetime(3) NOT NULL COMMENT '开始时间',
  `end_time` datetime(3) NOT NULL COMMENT '结束时间',
  `reason` varchar(500) DEFAULT '' COMMENT '原因',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT '状态: active/expired/cancelled',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_as_type` (`type`),
  KEY `idx_as_status` (`status`),
  KEY `idx_as_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警静默规则';

-- ============================================
-- 80. 告警升级配置表
-- ============================================
CREATE TABLE IF NOT EXISTS `alert_escalations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '升级规则名称',
  `alert_config_id` bigint unsigned DEFAULT NULL COMMENT '关联告警配置ID',
  `level` varchar(20) NOT NULL COMMENT '升级级别',
  `delay_minutes` int NOT NULL DEFAULT 30 COMMENT '延迟分钟数',
  `platform` varchar(50) NOT NULL COMMENT '通知平台',
  `bot_id` bigint unsigned DEFAULT NULL COMMENT '机器人ID',
  `notify_users` text COMMENT '通知用户列表JSON',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `description` text COMMENT '描述',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_ae_alert_config_id` (`alert_config_id`),
  KEY `idx_ae_bot_id` (`bot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警升级配置';

-- ============================================
-- 81. 告警升级日志表
-- ============================================
CREATE TABLE IF NOT EXISTS `alert_escalation_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `alert_history_id` bigint unsigned NOT NULL COMMENT '告警历史ID',
  `escalation_id` bigint unsigned NOT NULL COMMENT '升级规则ID',
  `platform` varchar(50) NOT NULL COMMENT '通知平台',
  `bot_id` bigint unsigned DEFAULT NULL COMMENT '机器人ID',
  `status` varchar(20) DEFAULT 'sent' COMMENT '状态: sent/failed',
  `error_msg` text COMMENT '错误信息',
  PRIMARY KEY (`id`),
  KEY `idx_ael_alert_history_id` (`alert_history_id`),
  KEY `idx_ael_escalation_id` (`escalation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警升级日志';

-- ============================================
-- 82. 日志告警规则表
-- ============================================
CREATE TABLE IF NOT EXISTS `log_alert_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '规则名称',
  `cluster_id` bigint NOT NULL COMMENT 'K8s集群ID',
  `namespace` varchar(100) DEFAULT '' COMMENT '命名空间',
  `match_type` varchar(20) NOT NULL COMMENT '匹配类型',
  `match_value` varchar(500) NOT NULL COMMENT '匹配值',
  `level` varchar(20) NOT NULL DEFAULT 'warning' COMMENT '告警级别',
  `channels` json DEFAULT NULL COMMENT '通知渠道JSON',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `aggregate_min` int DEFAULT 5 COMMENT '聚合分钟数',
  `created_by` bigint DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_lar_cluster_id` (`cluster_id`),
  KEY `idx_lar_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志告警规则';

-- ============================================
-- 83. 日志高亮规则表
-- ============================================
CREATE TABLE IF NOT EXISTS `log_highlight_rules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `name` varchar(100) NOT NULL COMMENT '规则名称',
  `match_type` varchar(20) NOT NULL COMMENT '匹配类型',
  `match_value` varchar(500) NOT NULL COMMENT '匹配值',
  `fg_color` varchar(20) DEFAULT '' COMMENT '前景色',
  `bg_color` varchar(20) DEFAULT '' COMMENT '背景色',
  `priority` int DEFAULT 0 COMMENT '优先级',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `is_preset` tinyint(1) DEFAULT 0 COMMENT '是否预设',
  PRIMARY KEY (`id`),
  KEY `idx_lhr_user_id` (`user_id`),
  KEY `idx_lhr_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志高亮规则';

-- ============================================
-- 84. 日志解析模板表
-- ============================================
CREATE TABLE IF NOT EXISTS `log_parse_templates` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '模板名称',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `type` varchar(20) NOT NULL COMMENT '类型',
  `pattern` text COMMENT '匹配模式',
  `fields` json DEFAULT NULL COMMENT '字段定义JSON',
  `is_preset` tinyint(1) DEFAULT 0 COMMENT '是否预设',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `created_by` bigint DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_lpt_type` (`type`),
  KEY `idx_lpt_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志解析模板';

-- 85. 日志数据源表
CREATE TABLE IF NOT EXISTS `log_datasources` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '数据源名称',
  `type` varchar(50) NOT NULL COMMENT '类型: elasticsearch/loki/clickhouse',
  `address` varchar(500) NOT NULL COMMENT '连接地址',
  `username` varchar(100) DEFAULT '' COMMENT '用户名',
  `password` varchar(200) DEFAULT '' COMMENT '密码',
  `index_pattern` varchar(200) DEFAULT '' COMMENT '索引模式',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `description` text COMMENT '描述',
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_lds_deleted_at` (`deleted_at`),
  KEY `idx_lds_type` (`type`),
  KEY `idx_lds_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志数据源';

-- 86. 日志书签表
CREATE TABLE IF NOT EXISTS `log_bookmarks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '书签名称',
  `datasource_id` bigint unsigned DEFAULT NULL COMMENT '数据源ID',
  `query` text COMMENT '查询语句',
  `time_range` varchar(50) DEFAULT '' COMMENT '时间范围',
  `filters` text COMMENT '过滤条件 JSON',
  `user_id` bigint unsigned DEFAULT NULL COMMENT '创建用户ID',
  `is_public` tinyint(1) DEFAULT 0 COMMENT '是否公开',
  PRIMARY KEY (`id`),
  KEY `idx_lb_deleted_at` (`deleted_at`),
  KEY `idx_lb_user_id` (`user_id`),
  KEY `idx_lb_datasource_id` (`datasource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志书签';

-- 87. 日志保存查询表
CREATE TABLE IF NOT EXISTS `log_saved_queries` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '查询名称',
  `datasource_id` bigint unsigned DEFAULT NULL COMMENT '数据源ID',
  `query` text NOT NULL COMMENT '查询语句',
  `description` text COMMENT '描述',
  `tags` varchar(200) DEFAULT '' COMMENT '标签',
  `user_id` bigint unsigned DEFAULT NULL COMMENT '创建用户ID',
  `is_public` tinyint(1) DEFAULT 0 COMMENT '是否公开',
  `is_shared` tinyint(1) DEFAULT 0 COMMENT '是否共享给团队',
  `use_count` int DEFAULT 0 COMMENT '使用次数',
  PRIMARY KEY (`id`),
  KEY `idx_lsq_deleted_at` (`deleted_at`),
  KEY `idx_lsq_user_id` (`user_id`),
  KEY `idx_lsq_datasource_id` (`datasource_id`),
  KEY `idx_lsq_is_shared` (`is_shared`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志保存查询';

-- 88. K8s集群飞书应用关联表
CREATE TABLE IF NOT EXISTS `k8s_cluster_feishu_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `cluster_id` bigint unsigned NOT NULL COMMENT 'K8s集群ID',
  `app_id` bigint unsigned NOT NULL COMMENT '飞书应用ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_kcfa_cluster_app` (`cluster_id`, `app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K8s集群飞书应用关联';

-- 89. K8s集群钉钉应用关联表
CREATE TABLE IF NOT EXISTS `k8s_cluster_dingtalk_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `cluster_id` bigint unsigned NOT NULL COMMENT 'K8s集群ID',
  `app_id` bigint unsigned NOT NULL COMMENT '钉钉应用ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_kcda_cluster_app` (`cluster_id`, `app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K8s集群钉钉应用关联';

-- 90. K8s集群企业微信应用关联表
CREATE TABLE IF NOT EXISTS `k8s_cluster_wechat_work_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `cluster_id` bigint unsigned NOT NULL COMMENT 'K8s集群ID',
  `app_id` bigint unsigned NOT NULL COMMENT '企业微信应用ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_kcwwa_cluster_app` (`cluster_id`, `app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K8s集群企业微信应用关联';

-- 91. Jenkins飞书应用关联表
CREATE TABLE IF NOT EXISTS `jenkins_feishu_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `jenkins_id` bigint unsigned NOT NULL COMMENT 'Jenkins实例ID',
  `app_id` bigint unsigned NOT NULL COMMENT '飞书应用ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_jfa_jenkins_app` (`jenkins_id`, `app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Jenkins飞书应用关联';

-- 92. Jenkins钉钉应用关联表
CREATE TABLE IF NOT EXISTS `jenkins_dingtalk_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `jenkins_id` bigint unsigned NOT NULL COMMENT 'Jenkins实例ID',
  `app_id` bigint unsigned NOT NULL COMMENT '钉钉应用ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_jda_jenkins_app` (`jenkins_id`, `app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Jenkins钉钉应用关联';

-- 93. Jenkins企业微信应用关联表
CREATE TABLE IF NOT EXISTS `jenkins_wechat_work_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `jenkins_id` bigint unsigned NOT NULL COMMENT 'Jenkins实例ID',
  `app_id` bigint unsigned NOT NULL COMMENT '企业微信应用ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_jwwa_jenkins_app` (`jenkins_id`, `app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Jenkins企业微信应用关联';

-- 94. 资源成本表
CREATE TABLE IF NOT EXISTS `resource_costs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `namespace` varchar(100) DEFAULT '' COMMENT '命名空间',
  `resource_type` varchar(50) NOT NULL COMMENT '资源类型: pod/node/service',
  `resource_name` varchar(200) NOT NULL COMMENT '资源名称',
  `app_name` varchar(100) DEFAULT '' COMMENT '应用名称',
  `team_name` varchar(100) DEFAULT '' COMMENT '团队名称',
  `cpu_request` decimal(10,2) DEFAULT 0.00 COMMENT 'CPU 请求量(核)',
  `cpu_limit` decimal(10,2) DEFAULT 0.00 COMMENT 'CPU 限制量(核)',
  `cpu_usage` decimal(10,2) DEFAULT 0.00 COMMENT 'CPU 实际使用量(核)',
  `cpu_cost` decimal(12,4) DEFAULT 0.0000 COMMENT 'CPU成本',
  `memory_request` decimal(10,2) DEFAULT 0.00 COMMENT '内存请求量(GB)',
  `memory_limit` decimal(10,2) DEFAULT 0.00 COMMENT '内存限制量(GB)',
  `memory_usage` decimal(10,2) DEFAULT 0.00 COMMENT '内存实际使用量(GB)',
  `memory_cost` decimal(12,4) DEFAULT 0.0000 COMMENT '内存成本',
  `storage_size` decimal(10,2) DEFAULT 0.00 COMMENT '存储大小(GB)',
  `storage_cost` decimal(12,4) DEFAULT 0.0000 COMMENT '存储成本',
  `total_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '总成本',
  `recorded_at` datetime(3) DEFAULT NULL COMMENT '成本记录时间',
  PRIMARY KEY (`id`),
  KEY `idx_rc_deleted_at` (`deleted_at`),
  KEY `idx_rc_resource_type` (`resource_type`),
  KEY `idx_rc_cluster_id` (`cluster_id`),
  KEY `idx_rc_namespace` (`namespace`),
  KEY `idx_rc_app_name` (`app_name`),
  KEY `idx_rc_team_name` (`team_name`),
  KEY `idx_rc_recorded_at` (`recorded_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资源成本记录';

-- 95. 成本汇总表
CREATE TABLE IF NOT EXISTS `cost_summaries` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `namespace` varchar(100) DEFAULT '' COMMENT '命名空间',
  `period` varchar(20) NOT NULL COMMENT '统计周期: daily/weekly/monthly',
  `period_date` date NOT NULL COMMENT '统计日期',
  `total_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '总成本',
  `cpu_cost` decimal(14,4) DEFAULT 0.0000 COMMENT 'CPU成本',
  `memory_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '内存成本',
  `storage_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '存储成本',
  PRIMARY KEY (`id`),
  KEY `idx_cs_cluster_id` (`cluster_id`),
  KEY `idx_cs_period_date` (`period_date`),
  KEY `idx_cs_deleted_at` (`deleted_at`),
  UNIQUE KEY `idx_cs_unique` (`cluster_id`, `namespace`, `period`, `period_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成本汇总';

-- 96. 成本优化建议表
CREATE TABLE IF NOT EXISTS `cost_suggestions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `resource_type` varchar(50) DEFAULT '' COMMENT '资源类型',
  `resource_name` varchar(200) DEFAULT '' COMMENT '资源名称',
  `namespace` varchar(100) DEFAULT '' COMMENT '命名空间',
  `suggestion_type` varchar(50) NOT NULL COMMENT '建议类型: rightsizing/idle/reserved',
  `description` text COMMENT '建议描述',
  `estimated_saving` decimal(12,4) DEFAULT 0.0000 COMMENT '预估节省金额',
  `savings` decimal(14,4) DEFAULT 0.0000 COMMENT '预计节省金额',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态: pending/applied/dismissed',
  PRIMARY KEY (`id`),
  KEY `idx_csugg_deleted_at` (`deleted_at`),
  KEY `idx_csugg_cluster_id` (`cluster_id`),
  KEY `idx_csugg_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成本优化建议';

-- 97. 成本配置表
CREATE TABLE IF NOT EXISTS `cost_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `cpu_price` decimal(10,6) DEFAULT 0.000000 COMMENT 'CPU单价(每核/小时)',
  `memory_price` decimal(10,6) DEFAULT 0.000000 COMMENT '内存单价(每GB/小时)',
  `storage_price` decimal(10,6) DEFAULT 0.000000 COMMENT '存储单价(每GB/小时)',
  `currency` varchar(10) DEFAULT 'CNY' COMMENT '货币单位',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  PRIMARY KEY (`id`),
  KEY `idx_cc_cluster_id` (`cluster_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成本计费配置';

-- 98. 成本预算表
CREATE TABLE IF NOT EXISTS `cost_budgets` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '预算名称',
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `namespace` varchar(100) DEFAULT '' COMMENT '命名空间',
  `amount` decimal(14,4) NOT NULL COMMENT '预算金额',
  `monthly_budget` decimal(14,4) DEFAULT 0.0000 COMMENT '月度预算',
  `current_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '当前花费',
  `currency` varchar(10) DEFAULT 'CNY' COMMENT '货币单位',
  `period` varchar(20) NOT NULL COMMENT '预算周期: monthly/quarterly/yearly',
  `start_date` date NOT NULL COMMENT '开始日期',
  `end_date` date NOT NULL COMMENT '结束日期',
  `alert_threshold` int DEFAULT 80 COMMENT '告警阈值百分比',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态',
  PRIMARY KEY (`id`),
  KEY `idx_cb_deleted_at` (`deleted_at`),
  KEY `idx_cb_cluster_id` (`cluster_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成本预算';

-- 99. 成本告警表
CREATE TABLE IF NOT EXISTS `cost_alerts` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `budget_id` bigint unsigned NOT NULL COMMENT '预算ID',
  `alert_type` varchar(50) NOT NULL COMMENT '告警类型: threshold/anomaly',
  `current_cost` decimal(14,4) DEFAULT 0.0000 COMMENT '当前成本',
  `budget_amount` decimal(14,4) DEFAULT 0.0000 COMMENT '预算金额',
  `usage_percent` decimal(5,2) DEFAULT 0.00 COMMENT '使用百分比',
  `message` text COMMENT '告警消息',
  `status` varchar(20) DEFAULT 'firing' COMMENT '状态: firing/resolved',
  PRIMARY KEY (`id`),
  KEY `idx_ca_budget_id` (`budget_id`),
  KEY `idx_ca_status` (`status`),
  KEY `idx_ca_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='成本告警记录';

-- 100. 资源活动记录表
CREATE TABLE IF NOT EXISTS `resource_activities` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `resource_type` varchar(50) NOT NULL COMMENT '资源类型',
  `resource_name` varchar(200) NOT NULL COMMENT '资源名称',
  `namespace` varchar(100) DEFAULT '' COMMENT '命名空间',
  `action` varchar(50) NOT NULL COMMENT '操作: create/update/delete/scale',
  `operator` varchar(100) DEFAULT '' COMMENT '操作人',
  `is_zombie` tinyint(1) DEFAULT 0 COMMENT '是否为僵尸资源',
  `last_active_at` datetime(3) DEFAULT NULL COMMENT '最后活跃时间',
  `detail` text COMMENT '操作详情 JSON',
  PRIMARY KEY (`id`),
  KEY `idx_ra_cluster_id` (`cluster_id`),
  KEY `idx_ra_resource_type` (`resource_type`),
  KEY `idx_ra_is_zombie` (`is_zombie`),
  KEY `idx_ra_created_at` (`created_at`),
  KEY `idx_ra_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资源活动记录';

-- 101. 流量规则模板表
CREATE TABLE IF NOT EXISTS `traffic_rule_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '模板名称',
  `rule_type` varchar(50) NOT NULL COMMENT '规则类型: ratelimit/circuitbreaker/routing',
  `content` text NOT NULL COMMENT '模板内容 JSON',
  `description` text COMMENT '描述',
  `is_builtin` tinyint(1) DEFAULT 0 COMMENT '是否内置',
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_trt_deleted_at` (`deleted_at`),
  KEY `idx_trt_rule_type` (`rule_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流量规则模板';

-- 102. 应用限流规则表
CREATE TABLE IF NOT EXISTS `app_ratelimit_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `rule_id` bigint unsigned NOT NULL COMMENT '限流规则ID',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  PRIMARY KEY (`id`),
  KEY `idx_arr_deleted_at` (`deleted_at`),
  UNIQUE KEY `idx_arr_app_rule` (`app_id`, `rule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用限流规则关联';

-- 103. 应用镜像规则表
CREATE TABLE IF NOT EXISTS `app_mirror_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `rule_id` bigint unsigned NOT NULL COMMENT '镜像规则ID',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  PRIMARY KEY (`id`),
  KEY `idx_amr_deleted_at` (`deleted_at`),
  UNIQUE KEY `idx_amr_app_rule` (`app_id`, `rule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用镜像规则关联';

-- 104. 应用故障注入规则表
CREATE TABLE IF NOT EXISTS `app_fault_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `rule_id` bigint unsigned NOT NULL COMMENT '故障注入规则ID',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  PRIMARY KEY (`id`),
  KEY `idx_afr_deleted_at` (`deleted_at`),
  UNIQUE KEY `idx_afr_app_rule` (`app_id`, `rule_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用故障注入规则关联';

-- 105. 镜像仓库表
CREATE TABLE IF NOT EXISTS `image_registries` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '仓库名称',
  `type` varchar(50) NOT NULL COMMENT '类型: harbor/dockerhub/ecr/acr',
  `address` varchar(500) NOT NULL COMMENT '仓库地址',
  `username` varchar(100) DEFAULT '' COMMENT '用户名',
  `password` varchar(200) DEFAULT '' COMMENT '密码',
  `insecure` tinyint(1) DEFAULT 0 COMMENT '是否跳过TLS验证',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态',
  `description` text COMMENT '描述',
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ir_deleted_at` (`deleted_at`),
  KEY `idx_ir_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='镜像仓库';

-- 106. 镜像扫描结果表
CREATE TABLE IF NOT EXISTS `image_scans` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `registry_id` bigint unsigned DEFAULT NULL COMMENT '仓库ID',
  `image_name` varchar(300) NOT NULL COMMENT '镜像名称',
  `image_tag` varchar(100) DEFAULT '' COMMENT '镜像标签',
  `image_digest` varchar(200) DEFAULT '' COMMENT '镜像摘要',
  `scan_status` varchar(20) DEFAULT 'pending' COMMENT '扫描状态: pending/scanning/completed/failed',
  `status` varchar(20) DEFAULT 'pending' COMMENT '扫描状态',
  `critical_count` int DEFAULT 0 COMMENT '严重漏洞数',
  `high_count` int DEFAULT 0 COMMENT '高危漏洞数',
  `medium_count` int DEFAULT 0 COMMENT '中危漏洞数',
  `low_count` int DEFAULT 0 COMMENT '低危漏洞数',
  `scan_result` longtext COMMENT '扫描结果 JSON',
  `scanned_at` datetime(3) DEFAULT NULL COMMENT '扫描时间',
  PRIMARY KEY (`id`),
  KEY `idx_is_registry_id` (`registry_id`),
  KEY `idx_is_scan_status` (`scan_status`),
  KEY `idx_is_status` (`status`),
  KEY `idx_is_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='镜像扫描结果';

-- 107. 合规规则表
CREATE TABLE IF NOT EXISTS `compliance_rules` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '规则名称',
  `category` varchar(50) NOT NULL COMMENT '分类: security/network/resource',
  `severity` varchar(20) DEFAULT 'medium' COMMENT '严重级别: critical/high/medium/low',
  `description` text COMMENT '规则描述',
  `check_script` text COMMENT '检查脚本',
  `remediation` text COMMENT '修复建议',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `is_builtin` tinyint(1) DEFAULT 0 COMMENT '是否内置',
  PRIMARY KEY (`id`),
  KEY `idx_cr_deleted_at` (`deleted_at`),
  KEY `idx_cr_category` (`category`),
  KEY `idx_cr_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='合规检查规则';

-- 108. 配置检查记录表
CREATE TABLE IF NOT EXISTS `config_checks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `rule_id` bigint unsigned NOT NULL COMMENT '合规规则ID',
  `resource_type` varchar(50) DEFAULT '' COMMENT '资源类型',
  `resource_name` varchar(200) DEFAULT '' COMMENT '资源名称',
  `namespace` varchar(100) DEFAULT '' COMMENT '命名空间',
  `status` varchar(20) NOT NULL COMMENT '检查状态: pass/fail/skip',
  `critical_count` int DEFAULT 0 COMMENT '严重问题数',
  `high_count` int DEFAULT 0 COMMENT '高危问题数',
  `medium_count` int DEFAULT 0 COMMENT '中危问题数',
  `low_count` int DEFAULT 0 COMMENT '低危问题数',
  `passed_count` int DEFAULT 0 COMMENT '通过数',
  `message` text COMMENT '检查消息',
  `checked_at` datetime(3) DEFAULT NULL COMMENT '检查时间',
  PRIMARY KEY (`id`),
  KEY `idx_cc_cluster_id` (`cluster_id`),
  KEY `idx_cc_rule_id` (`rule_id`),
  KEY `idx_cc_status` (`status`),
  KEY `idx_cc_checked_at` (`checked_at`),
  KEY `idx_cc_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='配置合规检查记录';

-- 109. 安全审计日志表
CREATE TABLE IF NOT EXISTS `security_audit_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `user_id` bigint unsigned DEFAULT NULL COMMENT '操作用户ID',
  `username` varchar(100) DEFAULT '' COMMENT '用户名',
  `action` varchar(100) NOT NULL COMMENT '操作动作',
  `resource_type` varchar(50) DEFAULT '' COMMENT '资源类型',
  `resource_id` varchar(100) DEFAULT '' COMMENT '资源ID',
  `resource_name` varchar(200) DEFAULT '' COMMENT '资源名称',
  `ip_address` varchar(50) DEFAULT '' COMMENT 'IP地址',
  `user_agent` varchar(500) DEFAULT '' COMMENT 'User-Agent',
  `request_id` varchar(100) DEFAULT '' COMMENT '请求ID',
  `status` varchar(20) DEFAULT 'success' COMMENT '状态: success/failed',
  `detail` text COMMENT '详情 JSON',
  PRIMARY KEY (`id`),
  KEY `idx_sal_user_id` (`user_id`),
  KEY `idx_sal_action` (`action`),
  KEY `idx_sal_created_at` (`created_at`),
  KEY `idx_sal_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全审计日志';

-- 110. 安全报告表
CREATE TABLE IF NOT EXISTS `security_reports` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '报告名称',
  `report_type` varchar(50) NOT NULL COMMENT '报告类型: compliance/vulnerability/audit',
  `cluster_id` bigint unsigned DEFAULT NULL COMMENT '集群ID',
  `status` varchar(20) DEFAULT 'generating' COMMENT '状态: generating/completed/failed',
  `summary` text COMMENT '摘要',
  `content` longtext COMMENT '报告内容 JSON',
  `generated_at` datetime(3) DEFAULT NULL COMMENT '生成时间',
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sr_deleted_at` (`deleted_at`),
  KEY `idx_sr_report_type` (`report_type`),
  KEY `idx_sr_cluster_id` (`cluster_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='安全报告';

-- 111. 加密密钥表
CREATE TABLE IF NOT EXISTS `encryption_keys` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '密钥名称',
  `key_type` varchar(50) NOT NULL COMMENT '密钥类型: aes/rsa/ed25519',
  `key_data` text NOT NULL COMMENT '密钥数据（加密存储）',
  `description` text COMMENT '描述',
  `expires_at` datetime(3) DEFAULT NULL COMMENT '过期时间',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/expired/revoked',
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ek_deleted_at` (`deleted_at`),
  KEY `idx_ek_key_type` (`key_type`),
  KEY `idx_ek_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='加密密钥管理';

-- 112. 任务表
CREATE TABLE IF NOT EXISTS `tasks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '任务名称',
  `task_type` varchar(50) NOT NULL COMMENT '任务类型: deploy/build/scan/check',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态: pending/running/success/failed/cancelled',
  `payload` text COMMENT '任务参数 JSON',
  `result` text COMMENT '任务结果 JSON',
  `error_msg` text COMMENT '错误信息',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '完成时间',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_t_deleted_at` (`deleted_at`),
  KEY `idx_t_task_type` (`task_type`),
  KEY `idx_t_status` (`status`),
  KEY `idx_t_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='异步任务';

-- 113. 流水线表
CREATE TABLE IF NOT EXISTS `pipelines` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '流水线名称',
  `app_id` bigint unsigned DEFAULT NULL COMMENT '应用ID',
  `template_id` bigint unsigned DEFAULT NULL COMMENT '模板ID',
  `jenkins_instance_id` bigint unsigned DEFAULT NULL COMMENT 'Jenkins实例ID',
  `jenkins_job_name` varchar(200) DEFAULT '' COMMENT 'Jenkins Job名称',
  `config` text COMMENT '流水线配置 JSON',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive',
  `last_build_id` bigint unsigned DEFAULT NULL COMMENT '最近构建ID',
  `last_build_status` varchar(20) DEFAULT '' COMMENT '最近构建状态',
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_p_deleted_at` (`deleted_at`),
  KEY `idx_p_app_id` (`app_id`),
  KEY `idx_p_template_id` (`template_id`),
  KEY `idx_pipelines_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='流水线';

-- ============================================
-- 流水线执行相关表（新增）
-- ============================================

-- 114. 流水线执行记录表
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

-- 115. 阶段执行记录表
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

-- 116. 步骤执行记录表
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

-- 117. 流水线凭证表
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

-- 118. 流水线环境变量表
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

-- 119. Git 仓库配置表
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

-- 120. 构建任务表
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

-- 121. 构建工作空间表
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

-- 122. Webhook 日志表
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

-- 123. 制品库配置表（流水线用）
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
