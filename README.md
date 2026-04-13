# 企业级 DevOps 运维平台

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Go](https://img.shields.io/badge/Go-1.25%2B-00ADD8.svg)
![Vue](https://img.shields.io/badge/Vue.js-3.x-4FC08D.svg)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20%2B-326CE5.svg)

一个企业级的一站式 DevOps 管理平台，旨在简化 Kubernetes 运维、CI/CD 流水线、流量治理和可观测性。基于现代技术栈构建，支持高性能和可扩展的软件交付。

## ✨ 核心功能

- **☸️ Kubernetes 管理**: 支持多集群管理、工作负载管理（Deployments, Pods, Services）、Web 终端和实时日志查看。
- **🚀 CI/CD 流水线**: 深度集成 Jenkins，提供可视化的流水线模板、制品管理和自动化的构建/部署工作流。
- **🚦 流量治理**: 提供高级流量控制策略，包括金丝雀发布、熔断、限流和负载均衡（兼容 Istio）。
- **🤖 AI Copilot**: 智能 DevOps 助手，用于自动化故障排查、日志分析和运维指导。
- **👀 可观测性与告警**: 集成 Prometheus/Grafana 监控，支持灵活的告警规则和多渠道通知（飞书、钉钉、企业微信）。
- **🛡️ 安全与 RBAC**: 细粒度的基于角色的访问控制（RBAC）、审计日志和安全资源管理。

## 🛠 技术栈

### 后端
- **语言**: Go 1.25+
- **框架**: Gin Web Framework
- **数据库**: MySQL 8.0 (GORM)
- **缓存**: Redis
- **基础设施**: Kubernetes Client-go, OpenTelemetry
- **文档**: Swagger (Swaggo)

### 前端
- **框架**: Vue 3 + TypeScript
- **构建工具**: Vite
- **UI 组件库**: Ant Design Vue, Element Plus
- **状态管理**: Pinia
- **可视化**: ECharts, XTerm.js (Web 终端)

## 📂 项目结构

```bash
devops/
├── cmd/                # 应用程序入口
├── internal/           # 私有应用程序代码
│   ├── config/         # 配置逻辑
│   ├── models/         # 数据库模型
│   ├── modules/        # 业务逻辑模块 (Handlers & Repositories)
│   ├── service/        # 复杂业务服务
│   └── infrastructure/ # 基础设施适配器 (K8s, DB, Cache)
├── migrations/         # 数据库迁移 SQL 脚本
├── pkg/                # 公共库代码 (Utils, Errors, Logger)
├── web/                # 前端 Vue.js 应用程序
├── docs/               # API 文档
└── go.mod              # Go 模块定义
```

## 🚀 快速开始

### 前置要求
- **Go**: 1.25 或更高版本
- **Node.js**: 18.0 或更高版本
- **MySQL**: 5.7 或 8.0+
- **Redis**: 6.0+
- **Kubernetes**: 运行中的集群（本地开发可选，完整功能需要）

### 1. 数据库设置
使用 `migrations` 目录下的脚本初始化数据库。详细说明请参考 [迁移指南](migrations/README.md)。

```bash
# 基础设置
mysql -u root -p devops < migrations/init_tables.sql
mysql -u root -p devops < migrations/create_rbac_tables.sql
mysql -u root -p devops < migrations/init_rbac.sql
```

### 2. 后端设置

```bash
# 克隆仓库
git clone https://gitlab.tastien.com/tools/devops-all-ai.git
cd devops-all-ai/devops

# 下载依赖
go mod download

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件配置你的 DB, Redis 和 K8s 信息

# 运行服务
go run cmd/server/main.go
```

后端服务默认将在 `http://localhost:8080` 启动。
Swagger API 文档访问地址：`http://localhost:8080/swagger/index.html`。

### 3. 前端设置

```bash
# 进入 web 目录
cd web

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

前端应用将在 `http://localhost:5173` 启动。

### 4. Docker 快速启动

```bash
# 在 devops 根目录下运行
docker-compose up --build -d
```

## ⚙️ 配置

应用启动时会从当前目录向上查找并自动加载 `.env`，也支持直接使用环境变量。主要配置项包括：

- `DB_DSN`: MySQL 连接字符串。
- `REDIS_ADDR`: Redis 地址。
- `KUBE_CONFIG`: Kubernetes kubeconfig 文件路径（或使用集群内配置）。
- `JENKINS_URL` / `JENKINS_USER` / `JENKINS_TOKEN`: Jenkins 集成设置。

## 🤝 贡献指南

欢迎贡献代码！请随时提交 Pull Request。

1. Fork 本项目
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。
