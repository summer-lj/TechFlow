# TechFlow H5

TechFlow 的 H5 前端工程，面向活动页、落地页、分享页、轻交互页面。

当前工程使用：

- `Vite`
- `React 19`
- `TypeScript`
- `react-router-dom`

H5 构建产物会被服务器托管在 `/h5/` 路径下，App 通过 `WebView` 直接访问服务器上的 H5 链接。

## 页面清单

当前已经接入的页面如下：

| 页面名称 | 路由 | 说明 |
| --- | --- | --- |
| 注册页 | `/h5/register/:businessSlug` | 手机号 + 密码注册，调用 `/api/v1/auth/register`，注册成功后可回传登录态给 App |

### 当前可直接访问的业务页面

| 业务 slug | 完整路径 | 说明 |
| --- | --- | --- |
| `techflow-app` | `/h5/register/techflow-app` | 当前 App 默认打开的注册页入口 |

说明：

- 当前工程只有一个“注册页模板”，但支持通过 `businessSlug` 区分不同业务入口。
- 默认业务 slug 定义在 [runtime.ts](/Users/liujun/liujun/TechFlow/techflow-h5/src/lib/runtime.ts)。
- 路由入口定义在 [App.tsx](/Users/liujun/liujun/TechFlow/techflow-h5/src/App.tsx)。

## 怎么访问

### 1. 本地开发访问

先启动 H5 开发服务：

```bash
cd techflow-h5
pnpm install
pnpm dev
```

默认本地开发地址：

- H5 页面：`http://localhost:5175/h5/register/techflow-app`
- 如果后端不在本机 `3000`，可通过环境变量指定代理目标：

```bash
VITE_API_TARGET=http://你的后端地址 pnpm dev
```

### 2. 本地后端联调访问

如果后端本地服务已经启动，并且服务端静态托管了 `techflow-h5/dist`，可以直接访问：

- `http://localhost:3000/h5/register/techflow-app`

说明：

- 这种方式最接近线上真实访问链路。
- 页面默认会请求同域 `/api/v1`。

### 3. 测试环境访问

测试环境部署后，直接访问：

- `http://<服务器IP>:8080/h5/register/techflow-app`

如果 H5 和 API 同域部署，不需要额外传 `apiBase`。

### 4. 生产环境访问

生产环境部署后，直接访问：

- `http://<服务器域名或IP>/h5/register/techflow-app`

## App WebView 访问方式

App 当前会打开服务器上的注册页，并通过 query 传入接口地址与嵌入标记。

示例：

```text
http://<服务器地址>/h5/register/techflow-app?apiBase=http://<服务器地址>/api/v1&embedded=1&source=app
```

说明：

- `apiBase`：H5 调用注册接口时使用的 API 基地址
- `embedded=1`：标识当前页面运行在 App WebView 中
- `source=app`：标识来源是 App
- 如果 WebView 中存在 `window.TechFlowRegister.postMessage`，注册成功后会把登录态回传给 App

相关实现位置：

- App 组装链接：[api_config.dart](/Users/liujun/liujun/TechFlow/techflow-app/lib/src/core/api_config.dart)
- WebView 容器页：[register_webview_page.dart](/Users/liujun/liujun/TechFlow/techflow-app/lib/src/ui/register_webview_page.dart)
- H5 注册页：[RegisterPage.tsx](/Users/liujun/liujun/TechFlow/techflow-h5/src/pages/RegisterPage.tsx)

## 构建与部署

构建：

```bash
cd techflow-h5
pnpm build
```

构建产物目录：

- `techflow-h5/dist`

服务器部署要求：

1. 先执行 `pnpm build`
2. 把 `dist` 发布到服务器上的 H5 静态目录
3. 由 Nginx 或后端静态托管 `/h5/`

当前约定：

- H5 构建产物通过服务器托管在 `/h5/`
- API 走 `/api/v1`
- App 不直接加载本地文件，而是访问服务器上的 H5 页面

## 后续新增页面时怎么记录

每新增一个页面，建议同步更新这个 README，至少补这三项：

1. 页面名称
2. 路由路径
3. 访问方式

推荐格式：

| 页面名称 | 路由 | 说明 |
| --- | --- | --- |
| 示例活动页 | `/h5/campaign/summer-2026` | 夏季活动落地页 |

