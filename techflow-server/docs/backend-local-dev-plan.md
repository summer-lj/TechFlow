# Backend Local Dev Plan

## 目标

这套仓库提供一套适合创业团队和中小公司使用的后端工程模板，覆盖：

- 本地开发
- 数据库与缓存
- API 文档
- 测试
- CI
- 镜像构建
- 阿里云单机双环境部署

## 仓库结构

```text
.
├── apps/api                # NestJS API 服务
├── deploy                  # 服务器部署脚本、Nginx、Compose 模板
├── docker                  # 本地与生产镜像入口
├── docs                    # 计划、部署和环境说明
├── .github/workflows       # CI/CD
├── docker-compose.yml      # 本地 Docker 开发环境
└── Makefile                # 新人友好的命令入口
```

## 本地开发流程

1. 复制并检查环境变量
   - `.env.example` 是模板
   - `.env.local` 是本地默认值
   - `.env.test` 给测试和 CI 使用
2. 执行 `make init`
   - 启动 PostgreSQL、Redis、Mailpit
   - 安装依赖
   - 生成 Prisma Client
   - 执行 migration
   - 执行种子数据
   - 启动 API
3. 日常开发
   - 看日志：`make logs`
   - 迁移数据库：`make migrate`
   - 补种子数据：`make seed`
4. 开发完成后执行质量检查
   - `make lint`
   - `make typecheck`
   - `make test`
   - `make test-e2e`
   - `make build`

## 应用架构

- 采用模块化单体
- 当前包含模块：
  - `health`
  - `auth`
  - `users`
  - `prisma`
  - `redis`
  - `common`
- 统一约定：
  - 业务接口前缀为 `/api/v1`
  - 健康检查独立为 `/health`
  - Swagger 独立为 `/docs`
  - 所有成功响应通过拦截器封装
  - 所有异常响应通过全局过滤器统一格式
  - 通过 JWT Access Token + Refresh Token 支持多端统一登录态

## 测试策略

- 单元测试
  - `AuthService`
  - 统一响应拦截器
- E2E 测试
  - `/health`
  - `/api/v1/auth/login`
  - `/api/v1/auth/refresh`
  - `/api/v1/users/me`
  - 参数校验失败
  - 未登录访问受保护接口

## Git 与协作流程

1. 从 `main` 拉出功能分支
2. 本地完成开发和自测
3. 提交 PR
4. GitHub Actions 运行 `ci.yml`
5. 合并到 `main`
6. `deploy.yml` 自动构建镜像并发布到 staging
7. 人工验证后，用 `workflow_dispatch` 将同一镜像 tag 晋升到 production
