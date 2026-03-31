# Deployment Runbook

## 目标拓扑

一台阿里云 Ubuntu 服务器同时承载：

- `production`
  - 宿主机 Nginx `:80`
  - API 容器映射到 `127.0.0.1:3000`
- `staging`
  - 宿主机 Nginx `:8080`
  - API 容器映射到 `127.0.0.1:3001`

数据库和 Redis 分别独立容器、独立数据目录、独立环境变量。

## 首次初始化服务器

1. 将仓库中的部署文件传到服务器，或者先把仓库 clone 到服务器。
2. 在服务器执行：

```bash
chmod +x deploy/scripts/bootstrap-server.sh
./deploy/scripts/bootstrap-server.sh
```

3. 脚本会完成：
   - 安装 Docker Engine 和 Docker Compose Plugin
   - 安装 Nginx
   - 创建 `/srv/backend/staging` 和 `/srv/backend/production`
   - 写入 Nginx 配置
   - 启用日志轮转

## 需要准备的服务器文件

每个环境都需要两个文件：

- `compose.env`
- `runtime.env`

路径如下：

- `/srv/backend/staging/env/compose.env`
- `/srv/backend/staging/env/runtime.env`
- `/srv/backend/production/env/compose.env`
- `/srv/backend/production/env/runtime.env`

模板参考：

- `deploy/compose/compose.env.staging.example`
- `deploy/compose/compose.env.production.example`

## GitHub Secrets / Environments

### Repository secrets

- `ALIYUN_HOST`
- `ALIYUN_USER`
- `ALIYUN_SSH_KEY`
- `GHCR_PULL_USERNAME`
- `GHCR_PULL_TOKEN`

### Staging environment secrets

- `STAGING_POSTGRES_DB`
- `STAGING_POSTGRES_USER`
- `STAGING_POSTGRES_PASSWORD`
- `STAGING_CORS_ORIGINS`
- `STAGING_JWT_ACCESS_SECRET`
- `STAGING_JWT_REFRESH_SECRET`
- `STAGING_DEFAULT_ADMIN_EMAIL`
- `STAGING_DEFAULT_ADMIN_PASSWORD`

### Production environment secrets

- `PRODUCTION_POSTGRES_DB`
- `PRODUCTION_POSTGRES_USER`
- `PRODUCTION_POSTGRES_PASSWORD`
- `PRODUCTION_CORS_ORIGINS`
- `PRODUCTION_JWT_ACCESS_SECRET`
- `PRODUCTION_JWT_REFRESH_SECRET`
- `PRODUCTION_DEFAULT_ADMIN_EMAIL`
- `PRODUCTION_DEFAULT_ADMIN_PASSWORD`

## 发布流程

### 自动到 staging

- 向 `main` 合并代码
- GitHub Actions:
  - 构建生产镜像
  - 推送到 GHCR
  - 通过 SSH 登录阿里云
  - 写入 staging 环境变量
  - 拉取并启动新镜像

验证地址：

- `http://<公网IP>:8080/health`
- `http://<公网IP>:8080/docs`

### 手动晋升到 production

1. 在 GitHub Actions 手动触发 `Deploy`
2. 输入 staging 已验证的 `image_tag`
3. GitHub Environment `production` 做审批
4. 审批通过后部署到 production

验证地址：

- `http://<公网IP>/health`
- `http://<公网IP>/docs`

## 回滚

1. 找到上一个稳定的镜像 tag
2. 在 GitHub Actions 手动触发 production 部署
3. 将 `image_tag` 改为旧 tag

因为 production 不重新构建镜像，而是复用已存在镜像，所以回滚只是重新部署旧版本 tag。

## 备份

生产库备份脚本：

```bash
chmod +x deploy/scripts/backup-postgres.sh
./deploy/scripts/backup-postgres.sh production
```

建议加到 crontab，例如每天凌晨 3 点执行一次。

## 常见排查

- 查看容器状态

```bash
docker compose --env-file /srv/backend/staging/env/compose.env -f /srv/backend/staging/compose/docker-compose.yml ps
docker compose --env-file /srv/backend/production/env/compose.env -f /srv/backend/production/compose/docker-compose.yml ps
```

- 查看 API 日志

```bash
docker compose --env-file /srv/backend/staging/env/compose.env -f /srv/backend/staging/compose/docker-compose.yml logs -f api
docker compose --env-file /srv/backend/production/env/compose.env -f /srv/backend/production/compose/docker-compose.yml logs -f api
```

- 检查 Nginx 配置

```bash
sudo nginx -t
sudo systemctl status nginx
```
