# DevOps 运维平台

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Go](https://img.shields.io/badge/Go-1.25%2B-00ADD8.svg)
![Vue](https://img.shields.io/badge/Vue.js-3.x-4FC08D.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-4479A1.svg)
![Redis](https://img.shields.io/badge/Redis-6.0%2B-DC382D.svg)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20%2B-326CE5.svg)

DevOps 是一套开箱即用的企业级一站式 DevOps 平台，深度融合云原生生态，提供 Kubernetes 可视化运维、灵活可编排的 CI/CD 流水线、服务流量治理以及监控告警、日志追踪等全链路可观测能力。平台采用现代化技术架构，兼顾性能与扩展性，助力企业快速落地云原生研发运维体系，提升交付效率与运维稳定性。

## 目录

- [一、项目介绍](#一项目介绍)
- [二、环境要求](#二环境要求)
- [三、本地开发快速启动](#三本地开发快速启动)
- [四、Docker Compose 快速部署（推荐）](#四docker-compose-快速部署推荐)
- [五、环境变量配置说明](#五环境变量配置说明)
- [六、飞书消息发送格式说明](#六飞书消息发送格式说明)
- [七、生产环境部署](#七生产环境部署)
- [八、API 文档](#八api-文档)
- [九、许可证](#九许可证)
- [十、致谢](#十致谢)
- [十一、联系方式](#十一联系方式)

## 登录界面

![登录界面](screenshots/login.jpg)

# 一、项目介绍

## 1.1 关于

DevOps 运维平台是一个企业级的一站式运维管理系统，围绕云原生基础设施和持续交付，提供完整的 DevOps 工具链。

把 Kubernetes 管理、CI/CD 流水线、监控告警、流量治理拆分成清晰的功能模块，让运维工作既能保持高效性，也能维持长期可维护性。

| 模块 | 技术栈 | 定位 |
| --- | --- | --- |
| `server` | Go 1.25 / Gin / GORM / MySQL | 后端服务、认证、接口、数据与定时任务 |
| `web` | Vue 3 / Ant Design Vue / Element Plus / Vite | 运维管理、仪表盘、可视化、操作后台 |

**为什么选择 DevOps 运维平台**

- 有完整工程结构，而不是只做出一个页面展示
- 多集群管理与工作负载管理解耦，运维体验更纯粹
- 支持 Kubernetes、Jenkins、监控告警等运维常见能力
- 适合企业级运维管理，也适合继续扩展成 PaaS 平台

## 1.2 核心功能

- **☸️ Kubernetes 管理**: 支持多集群管理、工作负载管理（Deployments, Pods, Services）、Web 终端和实时日志查看
- **🚀 CI/CD 流水线**: 深度集成 Jenkins，提供可视化的流水线模板、制品管理和自动化的构建/部署工作流
- **🚦 流量治理**: 提供高级流量控制策略，包括金丝雀发布、熔断、限流和负载均衡（兼容 Istio）
- **🤖 AI Copilot**: 智能 DevOps 助手，用于自动化故障排查、日志分析和运维指导
- **👀 可观测性与告警**: 集成 Prometheus/Grafana 监控，支持灵活的告警规则和多渠道通知（飞书、钉钉、企业微信）
- **🛡️ 安全与 RBAC**: 细粒度的基于角色的访问控制（RBAC）、审计日志和安全资源管理
- **💰 成本管理**: 资源成本统计、预算管理和优化建议
- **🔒 合规检查**: 镜像扫描、配置合规检测和安全报告

## 1.3 技术栈

### 1.3.1 Server - 服务端

- **语言**: [Go 1.25](https://golang.org)
- **框架**: [Gin](https://github.com/gin-gonic/gin)
- **ORM**: [GORM](https://gorm.io)
- **数据库**: MySQL 8.0+
- **缓存**: Redis 6.0+
- **基础设施**: Kubernetes Client-go, OpenTelemetry
- **API 文档**: Swagger (Swaggo)

### 1.3.2 Web - 前端

- **框架**: [Vue 3](https://vuejs.org) + [Vite](https://vitejs.dev)
- **UI 组件**: [Ant Design Vue](https://antdv.com), [Element Plus](https://element-plus.org)
- **状态管理**: [Pinia](https://pinia.vuejs.org)
- **可视化**: ECharts, XTerm.js (Web 终端)
- **其他**: TypeScript, Vue Router, Axios, dayjs

## 1.4 目录结构

### 1.4.1 Server

```bash
server/
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
├── docs/                   # Swagger API 文档
└── go.mod
```

### 1.4.2 Web

```bash
web/
├── src/
│   ├── api/              # API 接口
│   ├── assets/           # 静态资源
│   ├── components/       # 公共组件
│   ├── router/           # 路由配置
│   ├── types/            # TypeScript 类型定义
│   ├── utils/            # 工具函数
│   ├── views/            # 页面组件
│   ├── App.vue           # 根组件
│   └── main.ts           # 入口文件
├── public/               # 公共文件
├── index.html            # HTML 模板
└── vite.config.ts        # Vite 配置
```

## 1.5 特性

### 1.5.1 API 文档

服务启动后，访问以下地址查看 API 文档：

```bash
http://localhost:8080/swagger/index.html
```

### 1.5.2 多集群管理

支持同时管理多个 Kubernetes 集群，统一视图查看所有集群资源状态。

### 1.5.3 Web 终端

内置 Web 终端，支持直接在浏览器中连接 Pod 执行命令，无需本地安装 kubectl。

# 二、环境要求

| 依赖       | 版本要求 | 说明                           |
| :--------- | :------- | :----------------------------- |
| Go         | >= 1.25  | 后端运行环境                   |
| Node.js    | >= 18    | 前端构建环境                   |
| MySQL      | >= 8.0   | 主数据库，需 utf8mb4 字符集    |
| Redis      | >= 6.0   | 缓存与会话存储                 |
| Kubernetes | >= 1.20  | 可选，完整功能需要运行中的集群 |

# 三、本地开发快速启动

## 3.1 环境要求

- **Node.js** >= 18 (web)
- **Go** >= 1.25 (server)
- **MySQL** >= 8.0 (server)
- **Redis** >= 6.0 (server)

> 如果本地没有安装部署 MySQL 和 Redis，可参考以下 docker 快速部署相关数据库（可选）。

创建 `mysql` 容器：

```bash
docker run -d --name devops-mysql \
  -p 3306:3306 \
  --privileged=true \
  -v /data/MySqlData:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD="123456ok!" \
  -e MYSQL_DATABASE="devops" \
  -e TZ=Asia/Shanghai \
  mysql:8.0.34 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci
```

创建 `redis` 容器：

```bash
docker run -d --name devops-redis \
  -p 6379:6379 \
  -v /data/redisData:/data \
  -e TZ=Asia/Shanghai \
  redis:7-alpine \
  redis-server --requirepass 123456 --appendonly yes
```

查看是否创建成功：

```bash
[root@docker-server ~]# docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                                         NAMES
22205f8e78c6   mysql:8.0.34      "docker-entrypoint.s…"   34 minutes ago   Up 34 minutes   0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp   devops-mysql
33316g9f89d7   redis:7-alpine "docker-entrypoint.s…"   34 minutes ago   Up 34 minutes   0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp   devops-redis
```

## 3.2 克隆项目

```bash
git clone https://github.com/zyx3721/JeriDevOps.git /data/devops
cd /data/devops
```

## 3.3 数据库配置

### 3.3.1 本地数据库创建

创建 MySQL 数据库：

```bash
mysql -h 127.0.0.1 -u root -p -e "CREATE DATABASE IF NOT EXISTS devops DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### 3.3.2 容器数据库创建

进入容器内的 mysql 交互界面：

```bash
docker exec -it devops-mysql mysql -u root -p
```

在 mysql 中创建 devops 库（执行后输入 `exit` 退出）：

```bash
CREATE DATABASE IF NOT EXISTS devops DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3.3.3 初始化数据库

**全新部署**：

```bash
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

详细说明见 [migrations/README.md](migrations/README.md) 。

## 3.4 后端配置与启动

> 如果没有配置 go 的镜像代理，可以参考 [Go 国内加速：Go 国内加速镜像 | Go 技术论坛](https://learnku.com/go/wikis/38122)。

1. 下载相关依赖：

```bash
go mod download
```

2. 配置环境变量：

```bash
# 步骤1：复制模板文件
cp .env.example .env

# 步骤2：编辑 .env，配置数据库连接等信息
vim .env
```

`.env` 配置示例：

```bash
# 服务器配置
PORT=8080
LOG_LEVEL=info
READ_TIMEOUT=10
WRITE_TIMEOUT=10
SHUTDOWN_TIMEOUT=5
DEBUG=false
VERSION=1.0.0

# 数据库配置
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=devops
MYSQL_MAX_IDLE_CONNS=10
MYSQL_MAX_OPEN_CONNS=100
MYSQL_CONN_MAX_LIFETIME=3600

# Redis 配置
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0
REDIS_POOL_SIZE=10
REDIS_MIN_IDLE_CONNS=5

# Jenkins 配置
JENKINS_URL=http://localhost:8080
JENKINS_USER=admin
JENKINS_TOKEN=your_jenkins_token

# K8s 配置
K8S_KUBECONFIG_PATH=
K8S_NAMESPACE=default
K8S_CHECK_TIMEOUT=300
K8S_REGISTRY=
K8S_REPOSITORY=

# 飞书配置
FEISHU_APP_ID=your_app_id
FEISHU_APP_SECRET=your_app_secret

# JWT 配置
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION=24
```

3. 运行后端服务：

```bash
# 方式1：前台运行（终端关闭则服务停止）
go run cmd/server/main.go

# 方式2：后台运行（日志输出到 app.log）
nohup go run cmd/server/main.go > app.log 2>&1 &
```

后端服务默认运行在 `http://localhost:8080`，如需指定端口，请修改环境变量文件内的 `PORT` 参数。

## 3.5 前端配置与启动

1. 进入前端目录下载相关依赖：

```bash
cd web
npm install
```

2. 配置 API 地址（可选）：

```bash
# 配置说明：
# - 后端端口 = 8080：无需创建 .env 文件（默认值为 http://localhost:8080）
# - 后端端口 ≠ 8080：需要创建 .env 文件（指定正确端口，例如后端端口改为 8090）
#   创建 .env 文件，例如：
echo "VITE_DEV_PROXY_TARGET=http://localhost:8090" > .env
```

3. 启动前端服务：

```bash
# 方式1：前台运行（终端关闭则服务停止）
npm run dev

# 方式2：后台运行（日志输出到 web.log）
nohup npm run dev > web.log 2>&1 &
```

前端服务默认运行在 `http://localhost:3000` 。

## 3.6 访问系统

- **前端页面**：`http://localhost:3000`
- **API 文档**：`http://localhost:8080/swagger/index.html`
- **默认管理员账户**：`admin`
- **默认管理员密码**：`admin123`

# 四、Docker Compose 快速部署（推荐）

## 4.1 部署目录结构

所有相关文件统一放在 `deploy/` 目录下，单镜像包含前端（Nginx）、后端（devops），通过 supervisord 管理多进程。

```bash
deploy/
├── docker-compose.yaml    # 服务编排配置
├── Dockerfile             # 镜像构建配置
├── nginx.conf             # Nginx 配置
├── supervisord.conf       # 进程管理配置
├── entrypoint.sh          # 容器启动脚本
├── .env                   # 环境变量（需自行创建，见 4.2）
├── DevOpsData/            # 应用持久化数据（首次启动自动创建）
│   └── logs/              # 运行日志
├── MySqlData/             # MySQL 数据（首次启动自动创建）
└── redisData/             # Redis 数据（首次启动自动创建）
```

## 4.2 准备配置文件

进入 `deploy` 目录，复制环境变量模板文件：

```bash
cd deploy
cp .env.example .env
vim .env
```

`.env` 文件内容参考（容器内已通过 Nginx 反向代理配置，以下为必填项）：

```bash
# -------------------- MySQL 配置（必填）--------------------
# 容器间通信使用 service name（非 container_name）
MYSQL_HOST=mysql
MYSQL_PORT=3306

# MySQL root 密码（用于容器初始化，必填）
MYSQL_ROOT_PASSWORD=your_root_password

# 应用连接数据库的用户（可以是 root 或普通用户）
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=devops

# -------------------- Redis 配置（必填）--------------------
# 容器间通信使用 service name（非 container_name）
REDIS_ADDR=redis:6379

# -------------------- Jenkins 配置（必填）--------------------
# 外部 Jenkins 地址（需替换为实际地址）
JENKINS_URL=http://your-jenkins-host:8080
JENKINS_USER=admin
JENKINS_TOKEN=your_jenkins_token

# -------------------- JWT 配置（必填）--------------------
# 生产环境必须修改为强密码
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION=24

# -------------------- 飞书配置（可选）--------------------
FEISHU_APP_ID=your_app_id
FEISHU_APP_SECRET=your_app_secret

# -------------------- K8s 配置（可选）--------------------
# 如需 K8s 集成，将 kubeconfig 文件放到 ./DevOpsData/ 目录
K8S_KUBECONFIG_PATH=/app/data/kubeconfig
K8S_NAMESPACE=default
K8S_CHECK_TIMEOUT=300
K8S_REGISTRY=
K8S_REPOSITORY=
```

**配置说明：**

- **容器网络**：MySQL 和 Redis 使用 `docker-compose.yaml` 中定义的 service name（`mysql`、`redis`），而非 container_name
- **容器架构**：容器内 Nginx 监听 80 端口，反向代理到 Go 后端 8080 端口，无需配置 `PORT` 变量
- **MySQL 用户**：
  - `MYSQL_ROOT_PASSWORD`：用于 MySQL 容器初始化（必填）
  - `MYSQL_USER/MYSQL_PASSWORD`：后端应用连接数据库使用（默认用 root，也可创建普通用户）
- **必填项**：`MYSQL_ROOT_PASSWORD`、`MYSQL_PASSWORD`、`JWT_SECRET`、`JENKINS_*` 必须修改为真实值
- **可选项**：飞书和 K8s 配置按需填写

## 4.3 构建镜像（可选）

如果不想使用阿里云镜像仓库的镜像，可直接在本地手动构建（默认使用阿里云镜像仓库地址）：

```bash
# 在 deploy/ 目录下构建（构建上下文为项目根目录）
cd deploy
docker build -t devops:latest -f Dockerfile ..
```

然后修改 `deploy/docker-compose.yaml` 中 `devops` 服务的 `image` 字段为 `devops:latest`。

## 4.4 启动服务

`docker-compose.yaml` 支持两种模式，按需选择：

**模式一：新建 MySQL 和 Redis 容器（默认）**

首次启动会自动创建 `devops` 数据库：

```bash
cd deploy
docker compose up -d
```

**模式二：使用已有容器**

`.env` 环境变量文件中确保数据库配置填入已有容器地址，并编辑 `deploy/docker-compose.yaml`：

1. 注释掉 `mysql` 和 `redis` 服务块
2. 注释掉 `devops.depends_on` 块

```bash
cd deploy
docker compose up -d
```

## 4.5 服务管理

```bash
# 查看服务状态
docker compose ps

# 查看实时日志
docker compose logs -f devops

# 重启 devops 服务
docker compose restart devops

# 停止所有服务
docker compose down

# 停止并删除数据卷（谨慎！数据会丢失）
docker compose down -v
```

## 4.6 访问系统

服务启动后，访问以下地址：

- **前端页面**：`http://your-domain.com`
- **API 文档**：`http://your-domain.com/swagger/index.html`
- **健康检查**：`http://your-domain.com/health`
- **默认管理员账户**：`admin`
- **默认管理员密码**：`admin123`

## 4.7 宿主机 Nginx 反代（可选）

如需通过宿主机 Nginx 配置 HTTPS，将 `deploy/docker-compose.yml` 中的端口映射改为非 80 端口（如 `8080:80`），再配置外部 Nginx 代理：

### 4.7.1 HTTP 示例

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    # 限制上传文件大小（可选）
    client_max_body_size 50m;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 4.7.2 HTTPS 实例

> HTTPS 示例（含 80→443 跳转，请替换证书路径）：

```nginx
# HTTP 80端口配置，自动重定向到HTTPS
server {
    listen 80;
    server_name your-domain.com;   # 修改为你的域名/主机名，例如：devops.cn
    return 301 https://$host$request_uri;
}

# blog 站点 HTTPS 配置
server {
    # listen 443 ssl http2;  # Nginx 1.25 以下版本写法
    listen 443 ssl;
    http2 on;
    server_name your-domain.com;   # 修改为你的域名/主机名，例如：devops.cn

    # 证书路径（替换为实际证书文件）
    ssl_certificate     /usr/local/nginx/ssl/your-domain.com.pem;  # 例如：/usr/local/nginx/ssl/blog.cn.pem
    ssl_certificate_key /usr/local/nginx/ssl/your-domain.com.key;  # 例如：/usr/local/nginx/ssl/blog.cn.key
    
    # SSL安全优化
    ssl_protocols              TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers  on;
    ssl_ciphers                ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
    ssl_session_timeout        10m;
    ssl_session_cache          shared:SSL:10m;
    
    # 限制上传文件大小（可选）
    client_max_body_size 50m;

    ssl_certificate     /path/to/your-domain.com.pem;
    ssl_certificate_key /path/to/your-domain.com.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_cache   shared:SSL:10m;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

# 五、环境变量配置说明

应用启动时会从当前目录向上递归查找 `.env` 文件并自动加载，也支持直接设置系统环境变量。

复制模板后按需修改：

```bash
cp .env.example .env
```

## 5.1 服务器配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `8080` | HTTP 监听端口 |
| `LOG_LEVEL` | `info` | 日志级别：`debug` / `info` / `warn` / `error` |
| `DEBUG` | `false` | 调试模式，`true` 时输出 Gin 路由信息和 SQL 日志 |
| `VERSION` | `1.0.0` | 服务版本号，显示在管理页面右上角，便于区分部署版本 |
| `READ_TIMEOUT` | `10` | HTTP 读取超时（秒） |
| `WRITE_TIMEOUT` | `10` | HTTP 写入超时（秒） |
| `SHUTDOWN_TIMEOUT` | `5` | 优雅关闭等待时间（秒） |

## 5.2 MySQL 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MYSQL_HOST` | `localhost` | MySQL 主机地址 |
| `MYSQL_PORT` | `3306` | MySQL 端口 |
| `MYSQL_USER` | `root` | 数据库用户名 |
| `MYSQL_PASSWORD` | `123456` | 数据库密码 |
| `MYSQL_DATABASE` | `devops` | 数据库名称 |
| `MYSQL_MAX_IDLE_CONNS` | `10` | 连接池最大空闲连接数 |
| `MYSQL_MAX_OPEN_CONNS` | `100` | 连接池最大打开连接数 |
| `MYSQL_CONN_MAX_LIFETIME` | `3600` | 连接最大存活时间（秒） |

## 5.3 Redis 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `REDIS_ADDR` | `localhost:6379` | Redis 地址（host:port） |
| `REDIS_PASSWORD` | — | Redis 密码，无密码留空 |
| `REDIS_DB` | `0` | Redis 数据库编号（0-15） |
| `REDIS_POOL_SIZE` | `10` | 连接池最大连接数 |
| `REDIS_MIN_IDLE_CONNS` | `5` | 连接池最小空闲连接数 |

## 5.4 Jenkins 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `JENKINS_URL` | `http://localhost:8080` | Jenkins 服务地址 |
| `JENKINS_USER` | `admin` | Jenkins 用户名 |
| `JENKINS_TOKEN` | — | Jenkins API Token |

## 5.5 Kubernetes 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `K8S_KUBECONFIG_PATH` | — | kubeconfig 文件路径，留空则使用集群内配置（InCluster） |
| `K8S_NAMESPACE` | `default` | 默认操作的命名空间 |
| `K8S_CHECK_TIMEOUT` | `300` | K8s 资源检查超时时间（秒） |
| `K8S_REGISTRY` | — | 默认镜像仓库地址（预留） |
| `K8S_REPOSITORY` | — | 默认镜像仓库名称（预留） |

## 5.6 飞书配置

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

## 5.7 飞书应用权限配置

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

## 5.8 飞书 OAuth 授权（按姓名搜索用户）

按姓名/拼音搜索用户需要 `user_access_token`，必须完成 OAuth 授权流程：

**第一步：配置回调地址**

在飞书开发者后台 → 应用详情 → **安全设置** → **重定向 URL** 中添加：

```
# 本地开发
http://localhost:8080/app/api/v1/feishu/oauth/callback

# 生产环境（替换为实际域名）
https://your-domain.com/app/api/v1/feishu/oauth/callback
```

> 回调地址必须与实际访问地址完全一致（含端口），否则授权时报错 20029。

**第二步：发布应用版本**

每次修改权限或安全配置后，必须在飞书开发者后台发布新版本才能生效。

**第三步：执行授权**

在前端 **飞书管理 → 用户搜索** 页面，点击 **飞书授权** 按钮，使用飞书账号完成 OAuth 登录。授权成功后系统会自动保存 `user_access_token` 和 `refresh_token`，并每小时自动刷新，无需重复授权。

> **说明**：未完成 OAuth 授权时，用户搜索仍可通过手机号/邮箱精确匹配，但无法按姓名模糊搜索。

## 5.9 JWT 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `JWT_SECRET` | `your-secret-key` | JWT 签名密钥，**生产环境必须修改为强随机字符串** |
| `JWT_EXPIRATION` | `24` | Token 有效期（小时） |

> **安全提示**：`.env` 文件已加入 `.gitignore`，请勿将真实密钥提交到版本控制系统。

# 六、飞书消息发送格式说明

前端页面 **飞书管理 → 发送消息** 中，不同消息类型对应不同的 `content` 格式，填写错误会导致飞书 API 报错。

## 6.1 text（文本消息）

直接填写纯文本内容即可，后端会自动包装成飞书要求的格式：

```
你好，这是一条测试消息
```

## 6.2 post（富文本消息）

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

## 6.3 interactive（卡片消息）

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

# 七、生产环境部署

> 数据库配置请参考 `三、本地开发快速启动` 的相关配置。

## 7.1 克隆项目

```bash
git clone https://github.com/zyx3721/JeriDevOps.git /data/devops
cd /data/devops
```

## 7.2 后端构建与配置

1. 下载相关依赖：

```bash
go mod tidy
```

2. 配置环境变量：

```bash
# 步骤1：复制模板文件
cp .env.example .env

# 步骤2：编辑 .env，配置数据库连接等信息
vim .env
```

`.env` 配置示例：

```bash
# 服务器配置
PORT=8080
LOG_LEVEL=info
READ_TIMEOUT=10
WRITE_TIMEOUT=10
SHUTDOWN_TIMEOUT=5
DEBUG=false
VERSION=1.0.0

# 数据库配置
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=devops
MYSQL_MAX_IDLE_CONNS=10
MYSQL_MAX_OPEN_CONNS=100
MYSQL_CONN_MAX_LIFETIME=3600

# Redis 配置
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0
REDIS_POOL_SIZE=10
REDIS_MIN_IDLE_CONNS=5

# Jenkins 配置
JENKINS_URL=http://localhost:8080
JENKINS_USER=admin
JENKINS_TOKEN=your_jenkins_token

# K8s 配置
K8S_KUBECONFIG_PATH=
K8S_NAMESPACE=default
K8S_CHECK_TIMEOUT=300
K8S_REGISTRY=
K8S_REPOSITORY=

# 飞书配置
FEISHU_APP_ID=your_app_id
FEISHU_APP_SECRET=your_app_secret

# JWT 配置
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRATION=24
```

3. 构建后端可执行文件：

```bash
go build -o devops cmd/server/main.go
```

4. 运行后端服务： 

```bash
# 方式1：前台运行（终端关闭则服务停止）
go run cmd/server/main.go

# 方式2：后台运行（日志输出到 app.log）
nohup go run cmd/server/main.go > app.log 2>&1 &

# 方法3：加入 systemd 管理启动运行
# 服务配置参考如下，请自行修改相应目录路径
cat > /etc/systemd/system/devops.service <<EOF
[Unit]
Description=DevOps Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/data/devops
ExecStart=/data/devops/devops

StandardOutput=append:/data/devops/app.log
StandardError=inherit

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 重载服务配置并启动
systemctl daemon-reload
systemctl start devops

# 设置开机自启
systemctl enable --now devops
```

后端服务默认运行在 `http://localhost:8080`，如需指定端口，请修改环境变量文件内的 `PORT` 参数。

## 7.3 前端构建与配置

1. 进入前端目录下载相关依赖：

```bash
cd web
npm install
```

2. 构建前端项目：

```
npm run build
```

构建产物在 `dist` 目录，可部署到任何静态服务器（Nginx、Vercel、Netlify 等）。生产环境前端无需配置 API 地址，统一通过 Nginx `/api/` 反向代理到后端。

## 7.4 配置Nginx反向代理

在服务器上准备前端目录（例如 `/data/devops/frontend/dist`），**将本地 `dist` 目录中的所有文件和子目录整体上传到该目录**，保持结构不变，例如：

```bash
/data/devops/web/dist/
├── css/
├── js/
├── index.html
```

Nginx 中的 `root` 应指向 **包含 `index.html` 的目录本身**（如 `/data/devops/frontend/dist` ，可按实际路径调整），而不是上级目录。

### 7.4.1 HTTP 示例

> 配置 Nginx （按需替换域名/路径/证书），`HTTP 示例` ：

```nginx
server {
    listen 80;
    server_name your-domain.com;   # 修改为你的域名/主机名，例如：devops.cn
    
    # 前端静态资源目录（dist 构建产物）
    root /data/devops/web/dist;  # 按实际部署路径修改
    index index.html;
    
    # 限制上传文件大小（可选）
    client_max_body_size 50m;

    # 前端路由回退到 index.html（适配前端 history 模式）
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 后端 API 反向代理
    location /app/ {
        proxy_pass http://127.0.0.1:8080;  # 与后端 API 相同地址
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
    
    # 后端 API 文档
    location /swagger/ {
        proxy_pass http://127.0.0.1:8080;  # 与后端 API 相同地址
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

### 7.4.2 HTTPS 示例

> HTTPS 示例（含 80→443 跳转，请替换证书路径）：

```nginx
# 80 强制跳转到 443
server {
    listen 80;
    server_name your-domain.com;   # 修改为你的域名/主机名，例如：devops.cn
    return 301 https://$host$request_uri;
}

server {
    # listen 443 ssl http2;  # Nginx 1.25 以下版本写法
    listen 443 ssl;
    http2 on;
    server_name your-domain.com;   # 修改为你的域名/主机名，例如：devops.cn

    # 证书路径（替换为实际证书文件）
    ssl_certificate     /usr/local/nginx/ssl/your-domain.com.pem;  # 例如：/usr/local/nginx/ssl/devops.cn.pem
    ssl_certificate_key /usr/local/nginx/ssl/your-domain.com.key;  # 例如：/usr/local/nginx/ssl/devops.cn.key
    
    # SSL安全优化
    ssl_protocols              TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers  on;
    ssl_ciphers                ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout        10m;
    ssl_session_cache          shared:SSL:10m;

    # 前端静态资源目录（dist 构建产物）
    root /data/devops/web/dist;  # 按实际部署路径修改
    index index.html;
    
    # 限制上传文件大小（可选）
    client_max_body_size 50m;
    
    # 前端路由回退到 index.html（适配前端 history 模式）
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 后端 API 反向代理
    location /app/ {
        proxy_pass http://127.0.0.1:8080;  # 与后端 API 相同地址
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
    
    # 后端 API 文档
    location /swagger/ {
        proxy_pass http://127.0.0.1:8080;  # 与后端 API 相同地址
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

重载 Nginx：

```bash
# 检查语法
nginx -t

# 重载配置
## 方法1
nginx -s reload
## 方法2
systemctl reload nginx
```

## 7.5 访问系统

- **前端页面**：`http://your-domain.com`
- **API 文档**：`http://your-domain.com/swagger/index.html`
- **健康检查**：`http://your-domain.com/health`
- **默认管理员账户**：`admin`
- **默认管理员密码**：`admin123`

# 八、API 文档

后端集成 Swagger，服务启动后可通过以下地址在线查阅完整接口文档：

| 环境 | 地址 |
| ---- | ---- |
| 本地开发 | `http://localhost:8080/swagger/index.html` |
| 生产环境 | `http://your-domain.com/swagger/index.html` |

以下为接口速查表，按模块分组列出所有路由。

**说明：**
- 所有路由的 BasePath 为 `/app/api/v1`
- 需要认证的接口需要在 Header 中携带 `Authorization: Bearer {token}`
- 管理员权限：需要 admin 或 super_admin 角色
- 超级管理员权限：需要 super_admin 角色

## 8.1 认证与用户管理

### 8.1.1 认证接口

- `POST /auth/login` - 用户登录
- `POST /auth/register` - 用户注册

### 8.1.2 用户管理

- `GET /users` - 获取用户列表（需要认证）
- `GET /users/profile` - 获取当前用户资料（需要认证）
- `GET /users/:id` - 获取用户详情（需要认证）
- `POST /users` - 创建用户（需要管理员）
- `PUT /users/:id` - 更新用户信息（需要管理员）
- `PUT /users/:id/role` - 更新用户角色（需要管理员）
- `PUT /users/:id/status` - 更新用户状态（需要管理员）
- `DELETE /users/:id` - 删除用户（需要管理员）
- `POST /users/change-password` - 修改密码（需要认证）
- `POST /users/:id/reset-password` - 重置密码（需要管理员）

### 8.1.3 RBAC 权限管理

- `GET /rbac/roles` - 获取角色列表（需要认证）
- `GET /rbac/roles/:id` - 获取角色详情（需要认证）
- `POST /rbac/roles` - 创建角色（需要超级管理员）
- `PUT /rbac/roles/:id` - 更新角色（需要超级管理员）
- `DELETE /rbac/roles/:id` - 删除角色（需要超级管理员）
- `GET /rbac/permissions` - 获取权限列表（需要认证）
- `GET /rbac/my-permissions` - 获取当前用户权限（需要认证）

## 8.2 应用管理

### 8.2.1 应用管理

- `GET /app` - 获取应用列表（需要认证）
- `GET /app/:id` - 获取应用详情（需要认证）
- `POST /app` - 创建应用（需要管理员）
- `PUT /app/:id` - 更新应用（需要管理员）
- `DELETE /app/:id` - 删除应用（需要管理员）
- `GET /app/:id/envs` - 获取应用环境列表（需要认证）
- `GET /app/:id/deploys` - 获取应用部署记录（需要认证）
- `GET /app/stats` - 获取应用统计（需要认证）

### 8.2.2 金丝雀发布

- `GET /applications/:id/release/canary` - 获取金丝雀发布列表（需要认证）
- `POST /applications/:id/release/canary` - 创建金丝雀发布（需要认证）
- `POST /applications/:id/release/canary/:releaseId/start` - 开始金丝雀发布（需要认证）
- `POST /applications/:id/release/canary/:releaseId/pause` - 暂停金丝雀发布（需要认证）
- `POST /applications/:id/release/canary/:releaseId/rollback` - 回滚金丝雀发布（需要认证）

### 8.2.3 蓝绿部署

- `GET /deploy/bluegreen/list` - 获取所有蓝绿部署列表（需要认证）
- `POST /deploy/bluegreen/start` - 开始蓝绿部署（需要认证）
- `POST /deploy/bluegreen/:id/switch` - 切换蓝绿环境（需要认证）
- `POST /deploy/bluegreen/:id/rollback` - 回滚蓝绿部署（需要认证）

## 8.3 发布管理

- `POST /deploy/records` - 创建部署记录（需要认证）
- `GET /deploy/records` - 获取部署记录列表（需要认证）
- `POST /deploy/records/:id/approve` - 审批通过（需要认证）
- `POST /deploy/records/:id/reject` - 审批拒绝（需要认证）
- `POST /deploy/records/:id/execute` - 执行部署（需要认证）
- `POST /deploy/rollback` - 创建回滚（需要认证）
- `GET /deploy/stats` - 获取部署统计（需要认证）

## 8.4 审批管理

- `GET /approval/chains` - 获取审批链列表（需要认证）
- `POST /approval/chains` - 创建审批链（需要认证）
- `GET /approval/pending` - 获取待审批列表（需要认证）
- `POST /approval/:id/approve` - 审批通过（需要认证）
- `POST /approval/:id/reject` - 审批拒绝（需要认证）

## 8.5 Pipeline 流水线

- `GET /pipelines` - 获取流水线列表（需要认证）
- `POST /pipelines` - 创建流水线（需要认证）
- `POST /pipelines/:id/run` - 运行流水线（需要认证）
- `GET /pipelines/runs` - 获取执行历史（需要认证）
- `GET /pipelines/templates` - 获取模板列表（需要认证）
- `GET /pipelines/credentials` - 获取凭证列表（需要认证）
- `POST /webhook/github/:repoId` - GitHub Webhook
- `POST /webhook/gitlab/:repoId` - GitLab Webhook

## 8.6 Kubernetes 集群管理

- `GET /k8s-clusters` - 获取集群列表（需要认证）
- `POST /k8s-clusters` - 创建集群（需要超级管理员）
- `PUT /k8s-clusters/:id` - 更新集群（需要超级管理员）
- `DELETE /k8s-clusters/:id` - 删除集群（需要超级管理员）
- `POST /k8s-clusters/:id/test-connection` - 测试连接（需要超级管理员）
- `GET /k8s-clusters/:id/namespaces` - 获取命名空间列表（需要认证）
- `GET /k8s-clusters/:id/pods` - 获取 Pod 列表（需要认证）
- `GET /k8s/exec/shell` - WebSocket 终端（需要认证）

## 8.7 Jenkins 管理

- `GET /jenkins-instances` - 获取 Jenkins 实例列表（需要认证）
- `POST /jenkins-instances` - 创建实例（需要管理员）
- `PUT /jenkins-instances/:id` - 更新实例（需要管理员）
- `DELETE /jenkins-instances/:id` - 删除实例（需要管理员）
- `POST /jenkins-instances/:id/test-connection` - 测试连接（需要管理员）
- `GET /jenkins-instances/:id/jobs` - 获取任务列表（需要认证）

## 8.8 告警管理

- `GET /alert/configs` - 获取告警配置列表（需要认证）
- `POST /alert/configs` - 创建告警配置（需要管理员）
- `GET /alert/histories` - 获取告警历史（需要认证）
- `GET /alert/silences` - 获取静默规则列表（需要认证）
- `GET /alert/stats` - 获取告警统计（需要认证）

## 8.9 健康检查

- `GET /healthcheck/configs` - 获取配置列表（需要认证）
- `POST /healthcheck/configs` - 创建配置（需要管理员）
- `GET /healthcheck/ssl-domains` - 获取 SSL 域名列表（需要认证）
- `GET /healthcheck/ssl-domains/expiring` - 获取即将过期证书（需要认证）
- `GET /healthcheck/stats` - 获取统计数据（需要认证）

## 8.10 通知管理

### 8.10.1 飞书

- `POST /feishu/send-message` - 发送消息
- `POST /feishu/api/send-card` - 发送卡片消息
- `POST /feishu/user/search` - 搜索用户
- `GET /feishu/oauth/authorize` - OAuth 授权
- `GET /feishu/app` - 获取应用列表
- `POST /feishu/app` - 创建应用

### 8.10.2 钉钉与企业微信

- `POST /dingtalk/send-message` - 发送钉钉消息
- `POST /wechatwork/send-message` - 发送企业微信消息

## 8.11 安全管理

- `GET /security/overview` - 获取安全概览（需要认证）
- `POST /security/scan` - 扫描镜像（需要认证）
- `GET /security/scans` - 获取扫描历史（需要认证）
- `GET /security/registries` - 获取仓库列表（需要认证）
- `GET /security/audit-logs` - 获取审计日志（需要认证）

## 8.12 系统管理

- `GET /audit/logs` - 获取审计日志列表（需要认证）
- `GET /dashboard/stats` - 获取仪表盘统计数据
- `GET /health` - 健康检查
- `GET /metrics` - Prometheus 指标

# 九、许可证

本项目采用 [MIT License](LICENSE) 开源协议。

MIT License 是一个宽松的开源许可证，允许您自由地使用、复制、修改、合并、发布、分发、再许可和/或销售本软件的副本。唯一的要求是在所有副本或重要部分中保留版权声明和许可声明。

# 十、致谢

感谢以下开源项目和技术社区的支持：

- [Gin](https://github.com/gin-gonic/gin) - 高性能的 Go Web 框架
- [Vue.js](https://github.com/vuejs/core) - 渐进式 JavaScript 框架
- [Ant Design Vue](https://github.com/vueComponent/ant-design-vue) - 企业级 UI 组件库
- [Element Plus](https://github.com/element-plus/element-plus) - 基于 Vue 3 的组件库
- [GORM](https://github.com/go-gorm/gorm) - Go 语言 ORM 库
- [Kubernetes](https://github.com/kubernetes/kubernetes) - 容器编排平台
- [client-go](https://github.com/kubernetes/client-go) - Kubernetes Go 客户端
- [XTerm.js](https://github.com/xtermjs/xterm.js) - Web 终端模拟器

特别感谢所有为本项目贡献代码、提出建议和报告问题的开发者。

# 十一、联系方式

如果您在使用过程中遇到问题，或有任何建议和反馈，欢迎通过以下方式联系：

- **Email**: 416685476@qq.com
- **GitHub Issues**: [https://github.com/zyx3721/JeriDevOps/issues](https://github.com/zyx3721/JeriDevOps/issues)
- **项目主页**: [https://github.com/zyx3721/JeriDevOps](https://github.com/zyx3721/JeriDevOps)

---

**⭐ 如果这个项目对您有帮助，欢迎 Star 支持！**
