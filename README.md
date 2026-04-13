# 企业级 DevOps 运维平台

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Go](https://img.shields.io/badge/Go-1.25%2B-00ADD8.svg)
![Vue](https://img.shields.io/badge/Vue.js-3.x-4FC08D.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-4479A1.svg)
![Redis](https://img.shields.io/badge/Redis-6.0%2B-DC382D.svg)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20%2B-326CE5.svg)

一个企业级的一站式 DevOps 管理平台，旨在简化 Kubernetes 运维、CI/CD 流水线、流量治理和可观测性。基于现代技术栈构建，支持高性能和可扩展的软件交付。

## ✨ 核心功能

- **☸️ Kubernetes 管理**: 支持多集群管理、工作负载管理（Deployments, Pods, Services）、Web 终端和实时日志查看。
- **🚀 CI/CD 流水线**: 深度集成 Jenkins，提供可视化的流水线模板、制品管理和自动化的构建/部署工作流。
- **🚦 流量治理**: 提供高级流量控制策略，包括金丝雀发布、熔断、限流和负载均衡（兼容 Istio）。
- **🤖 AI Copilot**: 智能 DevOps 助手，用于自动化故障排查、日志分析和运维指导。
- **👀 可观测性与告警**: 集成 Prometheus/Grafana 监控，支持灵活的告警规则和多渠道通知（飞书、钉钉、企业微信）。
- **🛡️ 安全与 RBAC**: 细粒度的基于角色的访问控制（RBAC）、审计日志和安全资源管理。
- **💰 成本管理**: 资源成本统计、预算管理和优化建议。
- **🔒 合规检查**: 镜像扫描、配置合规检测和安全报告。

## 🛠 技术栈

### 后端
- **语言**: Go 1.25+
- **框架**: Gin Web Framework
- **数据库**: MySQL 8.0+ (GORM)
- **缓存**: Redis 6.0+
- **基础设施**: Kubernetes Client-go, OpenTelemetry
- **文档**: Swagger (Swaggo)

### 前端
- **框架**: Vue 3 + TypeScript
- **构建工具**: Vite
- **UI 组件库**: Ant Design Vue, Element Plus
- **状态管理**: Pinia
- **可视化**: ECharts, XTerm.js (Web 终端)

## 📂 项目结构

```
devops/
├── cmd/
│   └── server/             # 应用程序入口 (main.go)
├── internal/               # 私有应用程序代码
│   ├── config/             # 配置加载与 Gin 初始化
│   ├── domain/             # 领域模型与仓储接口
│   ├── models/             # 数据库模型定义
│   ├── modules/            # 业务逻辑模块 (Handlers & Repositories)
│   ├── service/            # 复杂业务服务层
│   └── infrastructure/     # 基础设施适配器 (K8s, DB, Cache)
├── migrations/             # 数据库 SQL 脚本
│   ├── init_tables.sql     # 全量建表（113 张表）
│   └── upgrades.sql        # 存量数据库升级补丁
├── pkg/                    # 公共库 (utils, errors, logger, response)
├── web/                    # 前端 Vue.js 应用
├── docs/                   # Swagger API 文档
├── .env.example            # 环境变量模板
└── go.mod                  # Go 模块定义
```

## 🚀 快速开始

### 前置要求

| 依赖 | 最低版本 | 说明 |
|------|---------|------|
| Go | 1.25+ | 后端运行环境 |
| Node.js | 18.0+ | 前端构建环境 |
| MySQL | 8.0+ | 主数据库，需 utf8mb4 字符集 |
| Redis | 6.0+ | 缓存与会话存储 |
| Kubernetes | 1.20+ | 可选，完整功能需要运行中的集群 |

### 1. 数据库初始化

**全新部署**：

```bash
# 创建数据库
mysql -h 127.0.0.1 -u root -p -e "CREATE DATABASE IF NOT EXISTS devops DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 初始化所有表结构和初始数据（113 张表）
mysql -h 127.0.0.1 -u root -p devops < migrations/init_tables.sql
```

初始化完成后使用以下账号登录：

| 字段 | 值 |
|------|----|
| 用户名 | `admin` |
| 密码 | `admin123` |
| 角色 | 超级管理员 |

**升级已有数据库**（全新部署无需执行）：

```bash
mysql -h 127.0.0.1 -u root -p devops < migrations/upgrades.sql
```

详细说明见 [migrations/README.md](migrations/README.md)。

### 2. 后端启动

```bash
# 下载依赖
go mod download

# 复制并编辑环境变量
cp .env.example .env
# 按实际情况修改 .env 中的数据库、Redis、K8s 等配置

# 启动服务
go run cmd/server/main.go
```

- 后端服务默认监听：`http://localhost:8080`
- Swagger 文档地址：`http://localhost:8080/swagger/index.html`

### 3. 前端启动

```bash
cd web
npm install
npm run dev
```

前端开发服务器默认监听：`http://localhost:5173`

### 4. Docker 一键启动

```bash
# 在项目根目录执行
docker-compose up --build -d
```

## ⚙️ 环境变量配置

应用启动时会从当前目录向上递归查找 `.env` 文件并自动加载，也支持直接设置系统环境变量。

复制模板后按需修改：

```bash
cp .env.example .env
```

### 服务器配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `8080` | HTTP 监听端口 |
| `LOG_LEVEL` | `info` | 日志级别：`debug` / `info` / `warn` / `error` |
| `DEBUG` | `false` | 调试模式，`true` 时输出 Gin 路由信息和 SQL 日志 |
| `VERSION` | `1.0.0` | 服务版本号，显示在飞书管理页面右上角，便于区分部署版本 |
| `READ_TIMEOUT` | `10` | HTTP 读取超时（秒） |
| `WRITE_TIMEOUT` | `10` | HTTP 写入超时（秒） |
| `SHUTDOWN_TIMEOUT` | `5` | 优雅关闭等待时间（秒） |

### MySQL 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MYSQL_HOST` | `localhost` | MySQL 主机地址 |
| `MYSQL_PORT` | `3306` | MySQL 端口 |
| `MYSQL_USER` | `root` | 数据库用户名 |
| `MYSQL_PASSWORD` | — | 数据库密码（必填） |
| `MYSQL_DATABASE` | `devops` | 数据库名称 |
| `MYSQL_MAX_IDLE_CONNS` | `10` | 连接池最大空闲连接数 |
| `MYSQL_MAX_OPEN_CONNS` | `100` | 连接池最大打开连接数 |
| `MYSQL_CONN_MAX_LIFETIME` | `3600` | 连接最大存活时间（秒） |

### Redis 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `REDIS_ADDR` | `localhost:6379` | Redis 地址（host:port） |
| `REDIS_PASSWORD` | — | Redis 密码，无密码留空 |
| `REDIS_DB` | `0` | Redis 数据库编号（0-15） |
| `REDIS_POOL_SIZE` | `10` | 连接池最大连接数 |
| `REDIS_MIN_IDLE_CONNS` | `5` | 连接池最小空闲连接数 |

### Jenkins 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `JENKINS_URL` | `http://localhost:8080` | Jenkins 服务地址 |
| `JENKINS_USER` | `admin` | Jenkins 用户名 |
| `JENKINS_TOKEN` | — | Jenkins API Token |

### Kubernetes 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `K8S_KUBECONFIG_PATH` | — | kubeconfig 文件路径，留空则使用集群内配置（InCluster） |
| `K8S_NAMESPACE` | `default` | 默认操作的命名空间 |
| `K8S_CHECK_TIMEOUT` | `300` | K8s 资源检查超时时间（秒） |
| `K8S_REGISTRY` | — | 默认镜像仓库地址（预留） |
| `K8S_REPOSITORY` | — | 默认镜像仓库名称（预留） |

### 飞书配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `FEISHU_APP_ID` | — | 系统级飞书应用 App ID |
| `FEISHU_APP_SECRET` | — | 系统级飞书应用 App Secret |

> **说明：飞书应用的两种配置方式**
>
> 本系统支持两种飞书应用配置方式，各有用途：
>
> **方式一：`.env` 全局配置（系统级）**
>
> `FEISHU_APP_ID` 和 `FEISHU_APP_SECRET` 是后端启动时初始化的**系统级默认飞书客户端**，用于发送系统告警、审批通知等内部消息。该配置仅在后端代码中生效，**不会显示在前端管理页面中**。
>
> **方式二：前端页面配置（业务级）**
>
> 前端菜单 **飞书管理 → 应用管理** 页面支持配置多个飞书应用，数据存储在数据库 `feishu_apps` 表中。Jenkins 实例和 K8s 集群可以各自绑定不同的飞书应用，适用于多团队、多租户场景。
>
> **推荐做法：**
> - 如果只有一个飞书应用，在 `.env` 填写即可，同时也在页面上录入一份，供 Jenkins/K8s 绑定使用。
> - 如果有多个飞书应用（多团队），通过页面统一管理，`.env` 填写一个兜底的默认应用。

### 飞书应用权限配置

在[飞书开发者后台](https://open.feishu.cn/app)创建应用后，需开通以下权限，否则相关功能将报错：

**应用身份权限（tenant_access_token，必须开通）：**

| 权限标识 | 说明 | 用途 |
|---------|------|------|
| `contact:user.id:readonly` | 通过手机号/邮箱获取用户 ID | 用户搜索（手机号/邮箱精确匹配） |
| `contact:user.base:readonly` | 获取用户基本信息 | 获取用户姓名、头像等详情 |
| `im:message:send_as_bot` | 以应用身份发送消息 | 发送飞书消息 |
| `im:chat` | 获取与更新群组信息 | 群聊管理（查询/创建/添加成员） |
| `im:chat:create` | 创建群组 | 创建群聊 |

**用户身份权限（user_access_token，按需开通）：**

| 权限标识 | 说明 | 用途 |
|---------|------|------|
| `search:user` | 搜索用户 | 按姓名/拼音模糊搜索用户（需 OAuth 授权） |

> **注意**：修改权限后必须**重新发布应用版本**才能生效。

### 飞书 OAuth 授权（按姓名搜索用户）

按姓名/拼音搜索用户需要 `user_access_token`，必须完成 OAuth 授权流程：

**第一步：配置回调地址**

在飞书开发者后台 → 应用详情 → **安全设置** → **重定向 URL** 中添加：

```
# 本地开发
http://localhost:8090/app/api/v1/feishu/oauth/callback

# 生产环境（替换为实际域名）
https://your-domain.com/app/api/v1/feishu/oauth/callback
```

> 回调地址必须与实际访问地址完全一致（含端口），否则授权时报错 20029。

**第二步：发布应用版本**

每次修改权限或安全配置后，必须在飞书开发者后台发布新版本才能生效。

**第三步：执行授权**

在前端 **飞书管理 → 用户搜索** 页面，点击 **飞书授权** 按钮，使用飞书账号完成 OAuth 登录。授权成功后系统会自动保存 `user_access_token` 和 `refresh_token`，并每小时自动刷新，无需重复授权。

> **说明**：未完成 OAuth 授权时，用户搜索仍可通过手机号/邮箱精确匹配，但无法按姓名模糊搜索。

### JWT 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `JWT_SECRET` | `your-secret-key` | JWT 签名密钥，**生产环境必须修改为强随机字符串** |
| `JWT_EXPIRATION` | `24` | Token 有效期（小时） |

## 📨 飞书消息发送格式说明

前端页面 **飞书管理 → 发送消息** 中，不同消息类型对应不同的 `content` 格式，填写错误会导致飞书 API 报错。

### text（文本消息）

直接填写纯文本内容即可，后端会自动包装成飞书要求的格式：

```
你好，这是一条测试消息
```

---

### post（富文本消息）

必须填写符合飞书富文本规范的 JSON，结构为 `{"zh_cn": {...}}`：

```json
{
  "zh_cn": {
    "title": "消息标题",
    "content": [
      [
        {"tag": "text", "text": "这是一段普通文字，"},
        {"tag": "a", "text": "点击跳转", "href": "https://example.com"}
      ],
      [
        {"tag": "text", "text": "第二行内容"}
      ]
    ]
  }
}
```

常用 tag 类型：

| tag | 说明 | 必填字段 |
|-----|------|---------|
| `text` | 普通文本 | `text` |
| `a` | 超链接 | `text`, `href` |
| `at` | @用户 | `user_id`（填 `all` 表示 @所有人） |
| `img` | 图片 | `image_key`（需先上传图片获取 key） |

---

### interactive（卡片消息）

必须填写符合飞书卡片 2.0 规范的 JSON：

```json
{
  "schema": "2.0",
  "header": {
    "title": {
      "content": "卡片标题",
      "tag": "plain_text"
    },
    "template": "blue"
  },
  "body": {
    "elements": [
      {
        "tag": "markdown",
        "content": "**加粗文字**\n普通文字\n[链接](https://example.com)"
      },
      {
        "tag": "hr"
      },
      {
        "tag": "markdown",
        "content": "底部说明文字"
      }
    ]
  }
}
```

`header.template` 可选颜色：`blue`、`green`、`red`、`yellow`、`grey`、`purple`

> **注意**：`interactive` 类型的 content 必须是完整的卡片 JSON 对象，不能填写普通字符串。

> **安全提示**：`.env` 文件已加入 `.gitignore`，请勿将真实密钥提交到版本控制系统。

## 🤝 贡献指南

欢迎贡献代码！请随时提交 Pull Request。

1. Fork 本项目
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -m 'feat: 添加某功能'`
4. 推送分支：`git push origin feature/your-feature`
5. 开启 Pull Request

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。
