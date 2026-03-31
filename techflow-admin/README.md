# TechFlow Admin

独立的后台管理端，负责管理员登录、运营总览、线索查看与状态推进。

## 启动方式

1. 先启动后端：`cd ../techflow-server && make up`
2. 安装依赖：`pnpm install`
3. 启动前端：`pnpm dev`
4. 打开 `http://localhost:5174`

## 默认账号

- 手机号：`13965026764`
- 密码：`123456`

默认管理员来自 `techflow-server/apps/api/prisma/seed.ts`。如果你在 `techflow-server/.env.local`
里覆盖了 `DEFAULT_ADMIN_PHONE` 或 `DEFAULT_ADMIN_PASSWORD`，则以本地环境变量为准。

## 可选环境变量

- `VITE_API_TARGET`：Vite 开发代理目标，默认 `http://localhost:3000`
- `VITE_API_BASE_URL`：直接请求后端时的完整基地址，例如 `https://api.example.com`
- `VITE_APP_BASE`：构建后静态资源的基础路径，例如 `/admin/`
- `VITE_ROUTER_BASENAME`：React Router 的 basename，例如 `/admin`
