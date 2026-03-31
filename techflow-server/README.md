# TechFlow Server

TechFlow 的共享后端与平台服务层。

当前它基于 NestJS 搭建，内置本地 Docker 开发环境、Prisma、Redis、Swagger、Jest、GitHub Actions，以及单台阿里云服务器上的 `staging + production` 双环境部署方案。

## 在 TechFlow 中的职责

- 为 `techflow-admin`、`techflow-app`、`techflow-h5`、`techflow-mini` 提供统一 API。
- 承载账号、用户、权限、配置、业务数据和运营接口。
- 负责数据库、Redis、第三方平台等基础集成。
- 当前仓库里仍保留了一部分 demo/starter 结构，后续会逐步向正式业务模块演进。

## 先理解这个项目

如果你不是后端同学，可以先这样理解：

- `apps/api`：真正的后端代码，接口、登录、数据库读写都在这里
- `docker-compose.yml`：本地开发启动清单，告诉 Docker 要起哪些服务
- `deploy`：服务器部署相关文件，给阿里云用
- `docs`：方案文档、部署说明、环境变量说明
- `README.md`：给团队看的总入口，先看这里就够了

## 技术栈

- NestJS + TypeScript
- PostgreSQL + Prisma
- Redis
- Swagger / OpenAPI
- Jest + Supertest
- Docker Compose
- GitHub Actions + GHCR
- Nginx

## 3 分钟快速启动

1. 安装 `Docker Desktop`、`git`，可选安装 `Node 22+` 和 `corepack`。
2. 克隆仓库后执行 `make init`。
3. 查看接口文档：`http://localhost:3000/docs`
4. 健康检查：`http://localhost:3000/health`
5. 打开演示网页：`http://localhost:3000/demo`
6. 默认管理员登录账号来自 `.env.local` 中的 `DEFAULT_ADMIN_PHONE` 和 `DEFAULT_ADMIN_PASSWORD`

## 项目目录说明

下面这份目录可以帮助你快速定位文件：

```text
techflow-server/
├─ apps/
│  └─ api/                       # 主后端服务
│     ├─ src/
│     │  ├─ auth/                # 统一登录、刷新 token、退出登录
│     │  ├─ users/               # 当前用户和用户基础资料
│     │  ├─ health/              # 健康检查
│     │  ├─ client-config/       # 多端共享启动配置、功能目录
│     │  ├─ app-client/          # App 独立接口模块，负责移动端聚合接口
│     │  ├─ site/                # 当前保留的 demo/公开接口模块，后续继续拆分
│     │  ├─ prisma/              # Prisma 连接封装
│     │  ├─ redis/               # Redis 连接封装
│     │  ├─ config/              # 环境变量校验
│     │  └─ common/              # 公共守卫、过滤器、拦截器、DTO
│     ├─ prisma/                 # 数据库表结构、迁移、seed
│     └─ test/                   # e2e 测试
├─ docker/                       # API 容器镜像和启动脚本
├─ deploy/                       # 服务器部署脚本、Nginx、生产 compose
├─ docs/                         # 计划文档、部署 runbook、环境变量说明、多端 API 设计
├─ .github/workflows/            # GitHub Actions: CI 和部署流程
├─ docker-compose.yml            # 本地开发环境编排
├─ Makefile                      # 最常用的启动、停止、测试命令
└─ README.md                     # 项目总说明
```

## 当前模块说明

当前后端已经开始从 demo/starter 结构向“共享服务 + 独立端接口层”演进，可以先这样理解：

- `auth`
  平台级账号能力，所有客户端共用。
- `users`
  当前用户和基础身份信息。
- `client-config`
  多端共享配置入口，给 `app/h5/mini/admin` 提供统一启动信息和公共能力目录。
- `app-client`
  App 独立接口层，负责按照移动端页面需要聚合返回结构，后续如果公司做大，这一层可以自然拆成单独的 App BFF 服务。
- `site`
  当前仍兼顾 demo 页面和公开能力，会逐步拆到 `marketing`、`demo`、`admin` 等更清晰的模块中。

项目后续的目标结构会逐步收敛为：

- 平台基础模块：`auth`、`users`、`health`、`client-config`
- 共享领域模块：`marketing`、`content`、`member` 等
- 后台管理模块：`admin/*`
- 端侧聚合模块：`app/*`、`h5/*`、`mini/*`
- 第三方集成模块：`integration/*`

## 常见配置文件说明

可以把这些文件理解成“项目说明书”：

- `.env.example`：本地环境变量模板。第一次启动时会复制成 `.env.local`
- `.env.local`：你自己本机开发时用的配置，不提交到 Git
- `.env.test`：跑测试时使用的环境变量
- `docker-compose.yml`：定义本地要启动哪些容器，比如 `api`、`postgres`、`redis`、`mailpit`
- `Makefile`：给开发者用的一组快捷命令，比如 `make init`、`make up`、`make test`
- `package.json`：根级脚本入口，定义 lint、test、build 等命令
- `pnpm-workspace.yaml`：告诉 `pnpm` 这是一个 workspace 项目
- `tsconfig.base.json`：TypeScript 的公共配置
- `eslint.config.mjs`：代码规范检查配置
- `prettier.config.mjs`：代码格式化配置
- `lint-staged.config.mjs`：提交代码前，自动检查哪些文件
- `.husky/pre-commit`：Git 提交前自动执行检查
- `apps/api/package.json`：API 服务自己的脚本和依赖
- `apps/api/prisma/schema.prisma`：数据库表结构定义
- `apps/api/prisma/seed.ts`：初始化默认管理员和测试数据
- `.github/workflows/ci.yml`：PR 或提交后的自动检查流程
- `.github/workflows/deploy.yml`：部署到 `staging` 和 `production` 的工作流
- `deploy/compose/server-compose.yml`：服务器上的容器编排文件
- `deploy/nginx/backend-ip.conf`：阿里云服务器上的 Nginx 反向代理配置
- `deploy/scripts/bootstrap-server.sh`：新服务器初始化脚本
- `deploy/scripts/server-deploy.sh`：服务器拉取镜像并部署的脚本

## 你最常会改的地方

- 想加共享业务接口：看 `apps/api/src`
- 想加 App 独立接口：看 `apps/api/src/app-client`
- 想加多端共享配置：看 `apps/api/src/client-config`
- 想改数据库表：看 `apps/api/prisma/schema.prisma`
- 想改本地启动方式：看 `docker-compose.yml`
- 想改部署流程：看 `deploy/` 和 `.github/workflows/`
- 想看完整说明：看 `docs/`

## 常用命令

- `make init`：初始化本地环境、执行 migration、注入种子数据
- `make up`：后台启动所有容器
- `make down`：停止本地环境
- `make logs`：查看 API 日志
- `make migrate`：执行 Prisma migration
- `make seed`：执行种子数据
- `make lint`
- `make typecheck`
- `make test`
- `make test-e2e`
- `make build`

## 默认接口

- `GET /health`
- `GET /docs`
- `GET /demo`
- `GET /api/v1/client-config/bootstrap`
- `GET /api/v1/client-config/features`
- `GET /api/v1/app/bootstrap`
- `GET /api/v1/app/home`
- `GET /api/v1/site/config`
- `GET /api/v1/site/features`
- `GET /api/v1/site/client-endpoints`
- `POST /api/v1/site/leads`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `GET /api/v1/users/me`
- `GET /api/v1/site/leads`

## 文档

- [本地开发与整体计划](./docs/backend-local-dev-plan.md)
- [功能演练流程](./docs/feature-walkthrough.md)
- [部署 Runbook](./docs/deployment-runbook.md)
- [环境变量说明](./docs/environment-variables.md)
- [整体架构说明](../docs/architecture.md)
- [多端 API 分层设计](../docs/multi-client-api-design.md)
