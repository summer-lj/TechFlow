# Environment Variables

## 通用应用变量

- `NODE_ENV`
- `APP_NAME`
- `APP_HOST`
- `PORT`
- `API_PREFIX`
- `LOG_LEVEL`
- `TRUST_PROXY`
- `SWAGGER_ENABLED`
- `CORS_ORIGINS`

## 数据库

- `DATABASE_HOST`
- `DATABASE_PORT`
- `DATABASE_NAME`
- `DATABASE_USER`
- `DATABASE_PASSWORD`
- `DATABASE_URL`

## Redis

- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_URL`

## JWT

- `JWT_ACCESS_SECRET`
- `JWT_ACCESS_TTL`
- `JWT_REFRESH_SECRET`
- `JWT_REFRESH_TTL`

## 默认管理员

- `DEFAULT_ADMIN_EMAIL`
- `DEFAULT_ADMIN_PHONE`
- `DEFAULT_ADMIN_PASSWORD`
- `DEFAULT_ADMIN_NAME`

## 自动初始化

- `AUTO_MIGRATE`
- `AUTO_SEED`

### local

- `.env.local` 里默认开启 `AUTO_MIGRATE=true`
- `.env.local` 里默认开启 `AUTO_SEED=true`

### test / ci

- `.env.test` 默认关闭 Swagger
- `.env.test` 指向本机 `localhost` 上的 PostgreSQL / Redis

### staging / production

- `runtime.env` 中保存业务变量
- `compose.env` 中保存镜像 tag、端口和数据目录
- staging 与 production 绝不能复用数据库、Redis 或密钥
