-- DevOps 平台建表 SQL
-- 请在 MySQL 中执行此脚本
-- 更新时间: 2026-01-04

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
  KEY `idx_users_deleted_at` (`deleted_at`),
  KEY `idx_users_last_login_at` (`last_login_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 2. 审计日志表
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `user_id` bigint unsigned DEFAULT 0,
  `username` varchar(100) DEFAULT '',
  `action` varchar(50) NOT NULL COMMENT '操作类型: create/update/delete',
  `resource` varchar(100) NOT NULL COMMENT '资源类型',
  `resource_id` bigint unsigned DEFAULT 0 COMMENT '资源ID',
  `resource_name` varchar(255) DEFAULT '' COMMENT '资源名称',
  `detail` text COMMENT '详情JSON',
  `ip_address` varchar(50) DEFAULT '' COMMENT '客户端IP',
  `user_agent` varchar(500) DEFAULT '' COMMENT 'User-Agent',
  `status` varchar(20) DEFAULT 'success' COMMENT '状态',
  `error_msg` varchar(500) DEFAULT '' COMMENT '错误信息',
  PRIMARY KEY (`id`),
  KEY `idx_audit_user` (`user_id`),
  KEY `idx_audit_action` (`action`),
  KEY `idx_audit_resource` (`resource`),
  KEY `idx_audit_created` (`created_at`)
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

-- ============================================
-- K8s 相关表
-- ============================================

-- 4. K8s 集群表
CREATE TABLE IF NOT EXISTS `k8s_clusters` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `kubeconfig` text NOT NULL,
  `namespace` varchar(100) DEFAULT 'default' NOT NULL,
  `registry` varchar(500) DEFAULT '',
  `repository` varchar(200) DEFAULT '',
  `description` text,
  `status` varchar(20) DEFAULT 'active' NOT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `check_timeout` int DEFAULT 180 NOT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_k8s_deleted_at` (`deleted_at`),
  KEY `idx_k8s_created_by` (`created_by`),
  KEY `idx_k8s_updated_by` (`updated_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K8s集群';

-- ============================================
-- 飞书相关表
-- ============================================

-- 5. 飞书应用表
CREATE TABLE IF NOT EXISTS `feishu_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `app_id` varchar(100) NOT NULL,
  `app_secret` varchar(200) NOT NULL,
  `project` varchar(100) DEFAULT '',
  `description` text,
  `status` varchar(20) DEFAULT 'active' NOT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_feishu_app_id` (`app_id`),
  KEY `idx_feishu_deleted_at` (`deleted_at`),
  KEY `idx_feishu_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书应用';

-- 6. 飞书机器人表
CREATE TABLE IF NOT EXISTS `feishu_bots` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `webhook_url` varchar(500) NOT NULL,
  `secret` varchar(100) DEFAULT '',
  `description` text,
  `status` varchar(20) DEFAULT 'active' NOT NULL,
  `message_template_id` bigint unsigned DEFAULT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_feishu_bot_deleted_at` (`deleted_at`),
  KEY `idx_feishu_bot_template` (`message_template_id`),
  KEY `idx_feishu_bot_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书机器人';

-- 7. Jenkins与飞书应用关联表
CREATE TABLE IF NOT EXISTS `jenkins_feishu_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `jenkins_instance_id` bigint unsigned NOT NULL,
  `feishu_app_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_jfa_jenkins` (`jenkins_instance_id`),
  KEY `idx_jfa_feishu` (`feishu_app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Jenkins与飞书应用关联';

-- 8. K8s与飞书应用关联表
CREATE TABLE IF NOT EXISTS `k8s_cluster_feishu_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `k8s_cluster_id` bigint unsigned NOT NULL,
  `feishu_app_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_kfa_k8s` (`k8s_cluster_id`),
  KEY `idx_kfa_feishu` (`feishu_app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='K8s与飞书应用关联';

-- ============================================
-- 钉钉相关表
-- ============================================

-- 9. 钉钉应用表
CREATE TABLE IF NOT EXISTS `dingtalk_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL,
  `app_key` varchar(100) NOT NULL,
  `app_secret` varchar(200) NOT NULL,
  `agent_id` bigint NOT NULL,
  `project` varchar(100) DEFAULT '',
  `description` text,
  `status` varchar(20) DEFAULT 'active',
  `is_default` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='钉钉应用';

-- 10. 钉钉机器人表
CREATE TABLE IF NOT EXISTS `dingtalk_bots` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL,
  `webhook_url` varchar(500) NOT NULL,
  `secret` varchar(100) DEFAULT '',
  `description` text,
  `status` varchar(20) DEFAULT 'active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='钉钉机器人';

-- 11. 钉钉消息日志表
CREATE TABLE IF NOT EXISTS `dingtalk_message_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `msg_type` varchar(50) NOT NULL,
  `target` varchar(500) DEFAULT '',
  `content` text,
  `title` varchar(200) DEFAULT '',
  `source` varchar(50) DEFAULT '',
  `status` varchar(20) DEFAULT 'success',
  `error_msg` text,
  `app_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='钉钉消息日志';

-- ============================================
-- 企业微信相关表
-- ============================================

-- 12. 企业微信应用表
CREATE TABLE IF NOT EXISTS `wechat_work_apps` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL,
  `corp_id` varchar(100) NOT NULL,
  `agent_id` bigint NOT NULL,
  `secret` varchar(200) NOT NULL,
  `project` varchar(100) DEFAULT '',
  `description` text,
  `status` varchar(20) DEFAULT 'active',
  `is_default` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业微信应用';

-- 13. 企业微信机器人表
CREATE TABLE IF NOT EXISTS `wechat_work_bots` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL,
  `webhook_url` varchar(500) NOT NULL,
  `description` text,
  `status` varchar(20) DEFAULT 'active',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业微信机器人';

-- 14. 企业微信消息日志表
CREATE TABLE IF NOT EXISTS `wechat_work_message_logs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `msg_type` varchar(50) NOT NULL,
  `to_user` varchar(500) DEFAULT '',
  `to_party` varchar(500) DEFAULT '',
  `to_tag` varchar(500) DEFAULT '',
  `content` text,
  `title` varchar(200) DEFAULT '',
  `source` varchar(50) DEFAULT '',
  `status` varchar(20) DEFAULT 'success',
  `error_msg` text,
  `app_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='企业微信消息日志';

-- ============================================
-- 其他基础表
-- ============================================

-- 15. 任务表
CREATE TABLE IF NOT EXISTS `tasks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `description` text,
  `status` varchar(20) DEFAULT 'pending' NOT NULL,
  `created_by` bigint unsigned NOT NULL,
  `start_time` datetime(3) DEFAULT NULL,
  `end_time` datetime(3) DEFAULT NULL,
  `jenkins_job` varchar(100) DEFAULT '',
  `parameters` text,
  PRIMARY KEY (`id`),
  KEY `idx_tasks_deleted_at` (`deleted_at`),
  KEY `idx_tasks_start_time` (`start_time`),
  KEY `idx_tasks_end_time` (`end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务';

-- 16. 消息模板表
CREATE TABLE IF NOT EXISTS `message_templates` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `type` varchar(50) NOT NULL,
  `content` text NOT NULL,
  `description` text,
  `is_active` tinyint(1) DEFAULT 1,
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_msg_tpl_deleted_at` (`deleted_at`),
  KEY `idx_msg_tpl_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息模板';

-- 17. 系统配置表
CREATE TABLE IF NOT EXISTS `system_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `key` varchar(100) NOT NULL,
  `value` text,
  `description` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_sys_config_key` (`key`),
  KEY `idx_sys_config_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置';

-- ============================================
-- OA 相关表
-- ============================================

-- 18. OA数据表
CREATE TABLE IF NOT EXISTS `oa_data` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `unique_id` varchar(100) NOT NULL,
  `ip_address` varchar(50) DEFAULT '',
  `user_agent` varchar(500) DEFAULT '',
  `original_data` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_oa_unique_id` (`unique_id`),
  KEY `idx_oa_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OA数据';

-- 19. 飞书请求表
CREATE TABLE IF NOT EXISTS `feishu_requests` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `request_id` varchar(100) NOT NULL,
  `original_request` text,
  `disabled_actions` text,
  `action_counts` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_feishu_req_id` (`request_id`),
  KEY `idx_feishu_req_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='飞书请求';

-- 20. OA地址表
CREATE TABLE IF NOT EXISTS `oa_addresses` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `url` varchar(500) NOT NULL,
  `type` varchar(50) DEFAULT 'webhook',
  `description` text,
  `status` varchar(20) DEFAULT 'active' NOT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `created_by` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_oa_addr_deleted_at` (`deleted_at`),
  KEY `idx_oa_addr_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OA地址';

-- ============================================
-- 告警相关表
-- ============================================

-- 21. 告警配置表
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
  `feishu_bot_id` bigint unsigned DEFAULT NULL COMMENT '飞书机器人ID',
  `dingtalk_bot_id` bigint unsigned DEFAULT NULL COMMENT '钉钉机器人ID',
  `wechatwork_bot_id` bigint unsigned DEFAULT NULL COMMENT '企业微信机器人ID',
  `enabled` tinyint(1) DEFAULT 1,
  `description` varchar(500) DEFAULT '',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_alert_type` (`type`),
  KEY `idx_alert_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警配置';

-- 22. 告警历史表
CREATE TABLE IF NOT EXISTS `alert_histories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `config_id` bigint unsigned NOT NULL COMMENT '告警配置ID',
  `config_name` varchar(100) DEFAULT '' COMMENT '告警名称',
  `type` varchar(50) NOT NULL COMMENT '告警类型',
  `target` varchar(255) DEFAULT '' COMMENT '监控目标',
  `severity` varchar(20) DEFAULT 'warning' COMMENT '严重级别',
  `message` text COMMENT '告警消息',
  `details` text COMMENT '详细信息JSON',
  `status` varchar(20) DEFAULT 'firing' COMMENT '状态: firing/resolved',
  `notified` tinyint(1) DEFAULT 0 COMMENT '是否已通知',
  `notified_at` datetime(3) DEFAULT NULL COMMENT '通知时间',
  `resolved_at` datetime(3) DEFAULT NULL COMMENT '恢复时间',
  PRIMARY KEY (`id`),
  KEY `idx_alert_history_config` (`config_id`),
  KEY `idx_alert_history_status` (`status`),
  KEY `idx_alert_history_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='告警历史';

-- ============================================
-- 应用与部署相关表
-- ============================================

-- 23. 应用表
CREATE TABLE IF NOT EXISTS `applications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '应用名称',
  `display_name` varchar(200) DEFAULT '' COMMENT '显示名称',
  `description` varchar(500) DEFAULT '' COMMENT '描述',
  `team` varchar(100) DEFAULT '' COMMENT '所属团队',
  `owner` varchar(100) DEFAULT '' COMMENT '负责人',
  `repo_url` varchar(500) DEFAULT '' COMMENT '代码仓库地址',
  `language` varchar(50) DEFAULT '' COMMENT '开发语言',
  `framework` varchar(50) DEFAULT '' COMMENT '框架',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态: active/inactive/archived',
  `created_by` bigint unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_app_name` (`name`),
  KEY `idx_app_team` (`team`),
  KEY `idx_app_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用管理';

-- 24. 应用环境配置表
CREATE TABLE IF NOT EXISTS `application_envs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `app_id` bigint unsigned NOT NULL COMMENT '应用ID',
  `env` varchar(50) NOT NULL COMMENT '环境: dev/test/staging/prod',
  `jenkins_instance_id` bigint unsigned DEFAULT 0 COMMENT 'Jenkins实例ID',
  `jenkins_job` varchar(200) DEFAULT '' COMMENT 'Jenkins Job名称',
  `k8s_cluster_id` bigint unsigned DEFAULT 0 COMMENT 'K8s集群ID',
  `k8s_namespace` varchar(100) DEFAULT '' COMMENT 'K8s命名空间',
  `k8s_deployment` varchar(200) DEFAULT '' COMMENT 'K8s Deployment名称',
  `replicas` int DEFAULT 1 COMMENT '副本数',
  `config` text COMMENT '其他配置JSON',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_app_env` (`app_id`, `env`),
  KEY `idx_env_jenkins` (`jenkins_instance_id`),
  KEY `idx_env_k8s` (`k8s_cluster_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用环境配置';

-- 25. 部署记录表
CREATE TABLE IF NOT EXISTS `deploy_records` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  -- 基础字段
  `app_id` bigint unsigned DEFAULT 0 COMMENT '应用ID(旧)',
  `application_id` bigint unsigned DEFAULT 0 COMMENT '应用ID',
  `app_name` varchar(100) DEFAULT '' COMMENT '应用名称',
  `env` varchar(50) DEFAULT '' COMMENT '环境(旧)',
  `env_name` varchar(50) DEFAULT '' COMMENT '环境名称',
  `version` varchar(100) DEFAULT '' COMMENT '版本号',
  `branch` varchar(100) DEFAULT '' COMMENT 'Git分支',
  `commit_id` varchar(100) DEFAULT '' COMMENT 'Git Commit ID',
  `commit_message` varchar(500) DEFAULT '' COMMENT 'Commit消息',
  -- 部署方式
  `deploy_type` varchar(50) DEFAULT 'deploy' COMMENT '部署类型: deploy/rollback/restart/scale',
  `deploy_method` varchar(50) DEFAULT 'jenkins' COMMENT '部署方式: jenkins/k8s',
  -- 镜像相关
  `image` varchar(500) DEFAULT '' COMMENT '镜像地址(旧)',
  `image_tag` varchar(200) DEFAULT '' COMMENT '镜像标签',
  -- Jenkins相关
  `jenkins_build_id` bigint unsigned DEFAULT 0 COMMENT 'Jenkins构建ID',
  `jenkins_build_number` int DEFAULT 0 COMMENT 'Jenkins构建号(旧)',
  `jenkins_build` int DEFAULT 0 COMMENT 'Jenkins构建号',
  `jenkins_url` varchar(500) DEFAULT '' COMMENT 'Jenkins构建URL',
  -- 状态相关
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态: pending/approved/rejected/running/success/failed/cancelled',
  `started_at` datetime(3) DEFAULT NULL COMMENT '开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '结束时间',
  `duration` int DEFAULT 0 COMMENT '耗时(秒)',
  `error_msg` text COMMENT '错误信息',
  -- 操作人
  `deployed_by` bigint unsigned DEFAULT 0 COMMENT '部署人ID(旧)',
  `deployed_by_name` varchar(100) DEFAULT '' COMMENT '部署人(旧)',
  `operator` varchar(100) DEFAULT '' COMMENT '操作人',
  `operator_id` bigint unsigned DEFAULT 0 COMMENT '操作人ID',
  -- 审批相关
  `need_approval` tinyint(1) DEFAULT 0 COMMENT '是否需要审批',
  `approval_chain_id` bigint unsigned DEFAULT NULL COMMENT '审批链ID',
  `approver_id` bigint unsigned DEFAULT NULL COMMENT '审批人ID',
  `approver_name` varchar(100) DEFAULT '' COMMENT '审批人',
  `approved_at` datetime(3) DEFAULT NULL COMMENT '审批时间',
  `reject_reason` text COMMENT '拒绝原因',
  -- 其他
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

-- 26. 发布锁表
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

-- 27. 审批记录表
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

-- 28. 健康检查配置表
CREATE TABLE IF NOT EXISTS `health_check_configs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at` datetime(3) DEFAULT NULL,
  `name` varchar(100) NOT NULL COMMENT '检查名称',
  `type` varchar(50) NOT NULL COMMENT '检查类型: jenkins/k8s/oa/custom',
  `target_id` bigint unsigned DEFAULT 0 COMMENT '对应资源的ID',
  `target_name` varchar(200) DEFAULT '' COMMENT '目标名称',
  `url` varchar(500) DEFAULT '' COMMENT '自定义检查的URL',
  `interval` int DEFAULT 300 COMMENT '检查间隔(秒)',
  `timeout` int DEFAULT 10 COMMENT '超时时间(秒)',
  `retry_count` int DEFAULT 3 COMMENT '重试次数',
  `enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用',
  `alert_enabled` tinyint(1) DEFAULT 1 COMMENT '是否启用告警',
  `alert_platform` varchar(50) DEFAULT '' COMMENT '告警平台: feishu/dingtalk/wechatwork',
  `alert_bot_id` bigint unsigned DEFAULT NULL COMMENT '告警机器人ID',
  `last_check_at` datetime(3) DEFAULT NULL COMMENT '最后检查时间',
  `last_status` varchar(20) DEFAULT 'unknown' COMMENT '最后状态: healthy/unhealthy/unknown',
  `last_error` text COMMENT '最后错误信息',
  `created_by` bigint unsigned DEFAULT NULL COMMENT '创建人ID',
  PRIMARY KEY (`id`),
  KEY `idx_hc_deleted_at` (`deleted_at`),
  KEY `idx_hc_type` (`type`),
  KEY `idx_hc_enabled` (`enabled`),
  KEY `idx_hc_target` (`target_id`),
  KEY `idx_hc_alert_bot` (`alert_bot_id`),
  KEY `idx_hc_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='健康检查配置';

-- 29. 健康检查历史表
CREATE TABLE IF NOT EXISTS `health_check_histories` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `config_id` bigint unsigned NOT NULL COMMENT '配置ID',
  `config_name` varchar(100) DEFAULT '' COMMENT '检查名称',
  `type` varchar(50) NOT NULL COMMENT '检查类型',
  `target_name` varchar(200) DEFAULT '' COMMENT '目标名称',
  `status` varchar(20) NOT NULL COMMENT '状态: healthy/unhealthy',
  `response_time_ms` bigint DEFAULT 0 COMMENT '响应时间(ms)',
  `error_msg` text COMMENT '错误信息',
  `alert_sent` tinyint(1) DEFAULT 0 COMMENT '是否已发送告警',
  PRIMARY KEY (`id`),
  KEY `idx_hc_history_config` (`config_id`),
  KEY `idx_hc_history_status` (`status`),
  KEY `idx_hc_history_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='健康检查历史';

-- ============================================
-- RBAC 权限相关表
-- ============================================

-- 30. 角色表
CREATE TABLE IF NOT EXISTS `roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(50) NOT NULL COMMENT '角色标识',
  `display_name` varchar(100) NOT NULL COMMENT '显示名称',
  `description` varchar(255) DEFAULT '' COMMENT '描述',
  `is_system` tinyint(1) DEFAULT 0 COMMENT '是否系统内置',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_roles_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色';

-- 31. 权限表
CREATE TABLE IF NOT EXISTS `permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `name` varchar(100) NOT NULL COMMENT '权限标识',
  `display_name` varchar(100) NOT NULL COMMENT '显示名称',
  `resource` varchar(50) NOT NULL COMMENT '资源类型',
  `action` varchar(50) NOT NULL COMMENT '操作类型',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_permissions_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='权限';

-- 32. 角色权限关联表
SET @permissions_description_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'permissions'
    AND COLUMN_NAME = 'description'
);
SET @permissions_description_sql := IF(
  @permissions_description_exists = 0,
  'ALTER TABLE `permissions` ADD COLUMN `description` text AFTER `action`',
  'SELECT 1'
);
PREPARE permissions_description_stmt FROM @permissions_description_sql;
EXECUTE permissions_description_stmt;
DEALLOCATE PREPARE permissions_description_stmt;

SET @permissions_resource_index_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'permissions'
    AND INDEX_NAME = 'idx_permissions_resource'
);
SET @permissions_resource_index_sql := IF(
  @permissions_resource_index_exists = 0,
  'ALTER TABLE `permissions` ADD KEY `idx_permissions_resource` (`resource`)',
  'SELECT 1'
);
PREPARE permissions_resource_index_stmt FROM @permissions_resource_index_sql;
EXECUTE permissions_resource_index_stmt;
DEALLOCATE PREPARE permissions_resource_index_stmt;

CREATE TABLE IF NOT EXISTS `role_permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `role_id` bigint unsigned NOT NULL,
  `permission_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_role_perm` (`role_id`, `permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联';

-- 33. 用户角色关联表
CREATE TABLE IF NOT EXISTS `user_roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  `user_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_role` (`user_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色关联';

-- ============================================
-- 审批规则相关表
-- ============================================

-- 34. 审批规则表
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

-- 35. 发布窗口表
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

-- ============================================
-- 多级审批链相关表
-- ============================================

-- 36. 审批链表
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

-- 37. 审批节点表
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

-- 38. 审批实例表
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

-- 39. 节点实例表
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

-- 40. 审批动作表
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
-- 初始化数据
-- ============================================

-- 插入默认管理员用户 (密码: admin123)
INSERT IGNORE INTO `users` (`username`, `password`, `email`, `role`, `status`) 
VALUES ('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', 'admin@example.com', 'admin', 'active');

-- 插入默认角色
INSERT IGNORE INTO `roles` (`name`, `display_name`, `description`, `is_system`) VALUES
('admin', '管理员', '系统管理员，拥有所有权限', 1),
('developer', '开发者', '开发人员，可以查看和部署应用', 1),
('viewer', '访客', '只读权限', 1);

-- 插入默认审批规则（生产环境需要审批）
INSERT IGNORE INTO `approval_rules` (`app_id`, `env`, `need_approval`, `approvers`, `timeout_minutes`, `enabled`, `created_by`) VALUES
(0, 'prod', 1, '', 30, 1, 1),
(0, 'production', 1, '', 30, 1, 1);

-- 插入默认发布窗口（工作日 10:00-18:00）
INSERT IGNORE INTO `deploy_windows` (`app_id`, `env`, `weekdays`, `start_time`, `end_time`, `allow_emergency`, `enabled`, `created_by`) VALUES
(0, 'prod', '1,2,3,4,5', '10:00', '18:00', 1, 1, 1),
(0, 'production', '1,2,3,4,5', '10:00', '18:00', 1, 1, 1);

-- ============================================
-- RBAC 权限初始化（增量更新，保留现有数据）
-- ============================================

-- 补充角色（如果不存在则插入）
INSERT IGNORE INTO roles (name, display_name, description, is_system, created_at, updated_at) VALUES
('super_admin', '超级管理员', '拥有所有权限，不可被修改或删除', 1, NOW(), NOW()),
('admin', '管理员', '拥有大部分管理权限', 1, NOW(), NOW()),
('user', '普通用户', '查看和基本操作权限', 1, NOW(), NOW()),
('guest', '访客', '只有查看权限', 1, NOW(), NOW());

-- 补充权限（如果不存在则插入）
INSERT IGNORE INTO permissions (name, display_name, resource, action, description, created_at) VALUES
-- 用户管理
('user:view', '查看用户', 'user', 'view', '查看用户列表和详情', NOW()),
('user:create', '创建用户', 'user', 'create', '创建新用户', NOW()),
('user:update', '更新用户', 'user', 'update', '更新用户信息', NOW()),
('user:delete', '删除用户', 'user', 'delete', '删除用户', NOW()),
('user:role', '修改角色', 'user', 'role', '修改用户角色', NOW()),
('user:status', '修改状态', 'user', 'status', '启用/禁用用户', NOW()),
-- 应用管理
('app:view', '查看应用', 'app', 'view', '查看应用', NOW()),
('app:create', '创建应用', 'app', 'create', '创建应用', NOW()),
('app:update', '更新应用', 'app', 'update', '更新应用', NOW()),
('app:delete', '删除应用', 'app', 'delete', '删除应用', NOW()),
('app:deploy', '发布应用', 'app', 'deploy', '发布部署', NOW()),
-- 审批管理
('approval:view', '查看审批', 'approval', 'view', '查看审批', NOW()),
('approval:create', '创建审批', 'approval', 'create', '创建审批规则', NOW()),
('approval:update', '更新审批', 'approval', 'update', '更新审批配置', NOW()),
('approval:delete', '删除审批', 'approval', 'delete', '删除审批规则', NOW()),
-- K8s管理
('k8s:view', '查看K8s', 'k8s', 'view', '查看K8s资源', NOW()),
('k8s:create', '创建K8s', 'k8s', 'create', '创建K8s配置', NOW()),
('k8s:update', '更新K8s', 'k8s', 'update', '更新K8s配置', NOW()),
('k8s:delete', '删除K8s', 'k8s', 'delete', '删除K8s配置', NOW()),
('k8s:exec', 'K8s操作', 'k8s', 'exec', '重启/扩缩容等', NOW()),
-- Jenkins管理
('jenkins:view', '查看Jenkins', 'jenkins', 'view', '查看Jenkins', NOW()),
('jenkins:create', '创建Jenkins', 'jenkins', 'create', '创建Jenkins', NOW()),
('jenkins:update', '更新Jenkins', 'jenkins', 'update', '更新Jenkins', NOW()),
('jenkins:delete', '删除Jenkins', 'jenkins', 'delete', '删除Jenkins', NOW()),
('jenkins:trigger', '触发构建', 'jenkins', 'trigger', '触发构建', NOW()),
-- 系统配置
('system:view', '查看系统配置', 'system', 'view', '查看系统配置', NOW()),
('system:update', '更新系统配置', 'system', 'update', '更新系统配置', NOW()),
-- 告警管理
('alert:view', '查看告警', 'alert', 'view', '查看告警', NOW()),
('alert:create', '创建告警', 'alert', 'create', '创建告警配置', NOW()),
('alert:update', '更新告警', 'alert', 'update', '更新告警配置', NOW()),
('alert:delete', '删除告警', 'alert', 'delete', '删除告警配置', NOW());

-- 重建角色权限关联
DELETE FROM role_permissions;

-- 超级管理员 - 所有权限
INSERT INTO role_permissions (role_id, permission_id, created_at)
SELECT r.id, p.id, NOW() FROM roles r, permissions p WHERE r.name = 'super_admin';

-- 管理员 - 除系统配置更新外的所有权限
INSERT INTO role_permissions (role_id, permission_id, created_at)
SELECT r.id, p.id, NOW() FROM roles r, permissions p 
WHERE r.name = 'admin' AND p.name != 'system:update';

-- 普通用户 - 查看 + 发布 + 触发构建
INSERT INTO role_permissions (role_id, permission_id, created_at)
SELECT r.id, p.id, NOW() FROM roles r, permissions p 
WHERE r.name = 'user' AND p.name IN (
    'app:view', 'app:deploy',
    'approval:view',
    'k8s:view',
    'jenkins:view', 'jenkins:trigger',
    'alert:view'
);

-- 访客 - 只有查看权限
INSERT INTO role_permissions (role_id, permission_id, created_at)
SELECT r.id, p.id, NOW() FROM roles r, permissions p 
WHERE r.name = 'guest' AND p.action = 'view';

-- 更新用户角色
UPDATE users SET role = 'super_admin' WHERE id = 1;
UPDATE users SET role = 'user' WHERE username = 'test';
UPDATE users SET role = 'guest' WHERE role IS NULL OR role = '';
