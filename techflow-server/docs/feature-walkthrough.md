# Feature Walkthrough

这份文档用来带你走一遍“开发一个小功能 -> 本地验证 -> 测试 -> 发布”的完整流程。这里的小功能就是仓库里已经实现好的 `/demo` 页面和它配套的 `site` API。

## 这次演练包含什么

- 一个简单网页：`/demo`
- 三组公开接口
  - `GET /api/v1/site/config`
  - `GET /api/v1/site/features`
  - `POST /api/v1/site/leads`
- 三组客户端常见接口
  - `POST /api/v1/auth/login`
  - `POST /api/v1/auth/refresh`
  - `GET /api/v1/users/me`
- 一个管理员接口
  - `GET /api/v1/site/leads`

## 第 1 步：本地启动

先确保本机安装好 Docker Desktop，然后在项目根目录执行：

```bash
make init
```

启动后访问：

- `http://localhost:3000/demo`
- `http://localhost:3000/docs`
- `http://localhost:3000/health`

## 第 2 步：手工验证网页和接口

### 页面验证

打开 `/demo` 后，确认：

- 页面能正常展示 hero、功能卡片、接口卡片
- 页面底部“实时响应”区域会显示初始化返回结果

### 留资表单验证

在“客户线索表单”填写内容并提交，确认：

- 页面显示“线索提交成功”
- 接口 `POST /api/v1/site/leads` 返回成功
- PostgreSQL 中新增一条 `Lead`

### 管理员登录验证

默认管理员账号来自 `.env.local`：

- 手机号：`DEFAULT_ADMIN_PHONE`
- 密码：`DEFAULT_ADMIN_PASSWORD`

在页面右侧管理员演示台：

1. 点击“登录并保存 Token”
2. 点击“读取当前用户”
3. 点击“读取线索列表”
4. 点击“刷新 Token”
5. 点击“登出”

这一步会把公开接口、鉴权接口和管理员接口全部走一遍。

## 第 3 步：执行测试

### 静态检查与单元测试

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

### E2E 测试

如果 Docker 已启动并且数据库、Redis 可用，再执行：

```bash
pnpm test:e2e
```

E2E 会验证：

- `/health`
- `/demo`
- 公开的 `site` 接口
- 登录和刷新 token
- 当前用户接口
- 线索创建与管理员读取

## 第 4 步：模拟一次开发协作流程

1. 从 `main` 拉一个功能分支
2. 修改 `/demo` 页面文案或增加一个字段
3. 本地重新验证
4. 提交 PR
5. 等 GitHub Actions 通过
6. 合并到 `main`

## 第 5 步：发布到 staging

合并到 `main` 后：

- GitHub Actions 会构建镜像
- 推送到 GHCR
- 自动部署到阿里云 staging

验证地址：

- `http://<你的公网IP>:8080/health`
- `http://<你的公网IP>:8080/docs`
- `http://<你的公网IP>:8080/demo`

建议你在 staging 再走一遍：

- 提交线索
- 管理员登录
- 查看线索列表

## 第 6 步：提升到 production

在 GitHub Actions 手动触发 `Deploy`：

1. 输入 staging 已验证通过的 `image_tag`
2. 通过 production 审批
3. 等待 production 部署完成

验证地址：

- `http://<你的公网IP>/health`
- `http://<你的公网IP>/docs`
- `http://<你的公网IP>/demo`

## 推荐你接下来怎么用它

- 把 `/demo` 当成产品官网或活动页的最小雏形
- 把 `site/leads` 当成第一条真实业务写库接口
- 接下来可以继续加：
  - 线索状态更新接口
  - 后台线索详情页
  - 文件上传
  - 短信或邮件通知
  - 管理后台前端
