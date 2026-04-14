# 数据库表结构与 Go Model 一致性检查报告

**生成时间**: 2026-04-14  
**检查范围**: 全部 113 张数据库表与对应的 Go Model  
**问题总数**: 23 个（严重 6 个，中等 6 个，缺失表 11 个）

---

## 📋 执行摘要

本次检查发现数据库表结构与 Go Model 定义存在多处不一致，主要问题包括：

1. **字段名不匹配** - 导致 ORM 映射失败
2. **字段类型不一致** - 可能导致数据截断或类型转换错误
3. **缺失字段** - 功能无法正常使用
4. **缺失表** - 流水线相关功能完全不可用
5. **缺失索引** - 影响查询性能

**影响范围**：
- ❌ K8s 集群管理功能
- ❌ 飞书请求记录功能
- ❌ 应用环境配置功能
- ❌ 制品仓库管理功能
- ❌ 告警历史查询功能
- ❌ 流水线执行功能（完全不可用）

---

## 🔴 严重问题（Critical Issues）

### 1. K8s 集群表字段不匹配

**表名**: `k8s_clusters`

**问题描述**:
- SQL 中有字段 `api_server`, `token`, `ca_cert`（旧版设计）
- Model 中使用 `kubeconfig` 字段（新版设计）
- SQL 缺少 Model 中的字段：`namespace`, `registry`, `repository`, `insecure_skip_tls`, `check_timeout`, `updated_by`

**影响**: K8s 集群配置无法正确保存和读取，集群连接功能异常

**修复方式**: 删除旧字段，添加新字段

---

### 2. 飞书请求表字段完全不匹配

**表名**: `feishu_requests`

**问题描述**:
- SQL 中有字段: `type`, `status`, `payload`, `response`
- Model 中有字段: `request_id`, `original_request`, `disabled_actions`, `action_counts`
- 两者完全不匹配，可能是两个不同版本的设计

**影响**: 飞书请求记录功能完全无法使用，飞书集成可能出现异常

**修复方式**: 重建表结构

---

### 3. 应用环境配置表字段名不一致

**表名**: `application_envs`

**问题描述**:
- SQL 字段名: `env`, `jenkins_instance_id`, `jenkins_job`, `k8s_cluster_id`, `k8s_namespace`, `k8s_deployment`
- Model 字段名: `env_name`, `branch`，且缺少 `jenkins_instance_id`, `k8s_cluster_id`

**影响**: 应用环境配置无法正确保存，部署功能异常

**修复方式**: 重命名字段，删除多余字段，添加缺失字段

---

### 4. 制品仓库表字段不匹配

**表名**: `artifact_repositories`

**问题描述**:
- SQL 缺少 Model 中的字段: `connection_status`, `last_error`, `enable_monitoring`, `check_interval`
- SQL 有额外字段: `check_status`, `check_message`, `check_latency_ms`, `total_images`, `total_size_bytes`

**影响**: 制品仓库监控功能无法使用，连接状态无法正确显示

**修复方式**: 删除旧字段，添加新字段

---

### 5. 制品表字段名不一致

**表名**: `artifacts`

**问题描述**:
- SQL 字段名: `download_cnt`, `latest_version`
- Model 字段名: `download_count`, `latest_ver`

**影响**: 下载次数和最新版本信息无法正确读取

**修复方式**: 重命名字段

---

### 6. 制品版本表字段名不一致

**表名**: `artifact_versions`

**问题描述**:
- SQL 字段名: `download_cnt`
- Model 字段名: `download_count`

**影响**: 版本下载次数统计异常

**修复方式**: 重命名字段

---

## 🟡 中等问题（Medium Issues）

### 7. 告警历史表缺少大量字段

**表名**: `alert_histories`

**问题描述**:
- SQL 缺少 Model 中的字段: `title`, `content`, `level`, `ack_status`, `ack_by`, `ack_at`, `resolved_by`, `resolved_at`, `resolve_comment`, `silenced`, `silence_id`, `escalated`, `escalation_id`, `error_msg`, `source_id`, `source_url`
- SQL 有额外字段: `config_name`, `target`, `details`, `notified`, `notified_at`

**影响**: 告警确认、解决、静默、升级等功能无法使用

**修复方式**: 删除旧字段，添加新字段

---

### 8. 钉钉机器人表有多余字段

**表名**: `dingtalk_bots`

**问题描述**:
- SQL 有字段 `project`, `message_template_id`
- Model 中没有这些字段

**影响**: 可能导致数据冗余，但不影响功能

**修复方式**: 删除多余字段

---

### 9. 企业微信机器人表缺少索引

**表名**: `wechat_work_bots`

**问题描述**:
- Model 中 `created_by` 有 `gorm:"index"` 标签
- SQL 中没有对应索引

**影响**: 按创建者查询性能较差

**修复方式**: 添加索引

---

### 10. 飞书应用表字段类型不匹配

**表名**: `feishu_apps`

**问题描述**:
- SQL 中 `project` 字段默认值为空字符串，但 Model 标记为 `not null`
- SQL 中 `description` 是 `varchar(500)`，Model 中是 `text`

**影响**: 可能导致数据验证失败

**修复方式**: 修改字段类型和约束

---

### 11. 飞书机器人表字段长度不一致

**表名**: `feishu_bots`

**问题描述**:
- SQL 中 `secret` 是 `varchar(200)`
- Model 中 `secret` 是 `varchar(100)`

**影响**: 可能导致数据截断

**修复方式**: 统一字段长度

---

### 12. 多个表缺少 deleted_at 索引

**问题描述**:
- 部分使用软删除的表缺少 `deleted_at` 索引

**影响**: 软删除查询性能较差

**修复方式**: 添加索引

---

## ⚠️ 缺失的表（Missing Tables）

以下 11 张表在 `init_tables.sql` 中不存在，但在 Go Model 中有定义，导致相关功能完全不可用：

### 13. pipeline_runs - 流水线执行记录
**影响**: 无法记录流水线执行历史

### 14. stage_runs - 阶段执行记录
**影响**: 无法记录流水线阶段执行状态

### 15. step_runs - 步骤执行记录
**影响**: 无法记录流水线步骤执行日志

### 16. pipeline_credentials - 流水线凭证
**影响**: 无法管理流水线凭证（Git、Docker Registry 等）

### 17. pipeline_variables - 流水线环境变量
**影响**: 无法配置流水线环境变量

### 18. git_repositories - Git 仓库配置
**影响**: 无法管理 Git 仓库连接

### 19. build_jobs - 构建任务
**影响**: 无法执行 K8s Job 构建任务

### 20. build_workspaces - 构建工作空间
**影响**: 无法管理构建工作空间（PVC）

### 21. webhook_logs - Webhook 日志
**影响**: 无法记录 Git Webhook 触发日志

### 22. artifact_registries - 制品库配置（流水线用）
**影响**: 流水线无法推送制品到仓库

### 23. ai_message_feedbacks - AI 消息反馈
**影响**: 无法收集 AI Copilot 用户反馈

---

## 🛠️ 修复方案

### 方式一：执行修复脚本（推荐）

```bash
# 1. 备份数据库
mysqldump -u root -p devops > devops_backup_$(date +%Y%m%d_%H%M%S).sql

# 2. 执行修复脚本
mysql -u root -p devops < migrations/fix_db_consistency.sql

# 3. 验证修复结果
mysql -u root -p devops -e "SHOW TABLES;" | wc -l
```

### 方式二：重新初始化数据库（谨慎）

```bash
# 警告：此操作会清空所有数据！
mysql -u root -p -e "DROP DATABASE IF EXISTS devops; CREATE DATABASE devops CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p devops < migrations/init_tables.sql
mysql -u root -p devops < migrations/upgrades.sql
mysql -u root -p devops < migrations/fix_db_consistency.sql
```

---

## 📊 修复后验证清单

执行修复脚本后，请验证以下功能：

- [ ] K8s 集群管理 - 添加/编辑集群配置
- [ ] 飞书集成 - 发送消息，查看请求记录
- [ ] 应用管理 - 配置应用环境
- [ ] 制品管理 - 查看制品列表，下载制品
- [ ] 告警管理 - 查看告警历史，确认/解决告警
- [ ] 流水线管理 - 创建流水线，执行流水线
- [ ] Git 仓库管理 - 添加 Git 仓库
- [ ] Webhook 触发 - 推送代码触发流水线
- [ ] AI Copilot - 对话反馈功能

---

## 🔍 根本原因分析

### 1. 版本不一致
- `init_tables.sql` 可能是早期版本
- Go Model 已经迭代更新
- 缺少同步机制

### 2. 开发流程问题
- 先修改 Model，未同步更新 SQL
- 或先修改 SQL，未同步更新 Model
- 缺少自动化检查工具

### 3. 功能迭代
- 流水线功能是后期新增
- 部分表结构在 `upgrades.sql` 中补充
- 但 `init_tables.sql` 未合并

---

## 💡 建议

### 短期建议
1. ✅ 立即执行修复脚本 `fix_db_consistency.sql`
2. ✅ 验证所有功能模块
3. ✅ 更新 `init_tables.sql`，合并 `upgrades.sql` 和 `fix_db_consistency.sql`

### 长期建议
1. 🔧 引入数据库迁移工具（如 golang-migrate、goose）
2. 🔧 添加 CI/CD 检查，自动对比 Model 与数据库表结构
3. 🔧 建立 Model 变更规范，要求同步更新迁移脚本
4. 🔧 定期执行一致性检查脚本

---

## 📝 附录

### 相关文件
- `migrations/init_tables.sql` - 初始化表结构
- `migrations/upgrades.sql` - 升级脚本
- `migrations/fix_db_consistency.sql` - 本次修复脚本（新增）
- `internal/domain/*/model/*.go` - Go Model 定义

### 检查工具
可以编写自动化检查脚本：
```go
// 伪代码
func CheckConsistency() {
    models := GetAllModels()
    tables := GetAllTables()
    
    for _, model := range models {
        table := tables[model.TableName]
        if table == nil {
            log.Error("Missing table: %s", model.TableName)
            continue
        }
        
        for _, field := range model.Fields {
            column := table.Columns[field.ColumnName]
            if column == nil {
                log.Error("Missing column: %s.%s", model.TableName, field.ColumnName)
            } else if column.Type != field.Type {
                log.Error("Type mismatch: %s.%s", model.TableName, field.ColumnName)
            }
        }
    }
}
```

---

**报告生成者**: Claude Opus 4.6  
**联系方式**: 如有疑问请查看项目文档或提交 Issue
