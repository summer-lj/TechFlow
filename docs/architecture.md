# TechFlow Architecture

## 核心判断

`TechFlow` 的项目级核心应该是：

- `techflow-server` 作为共享服务层
- `techflow-admin` 作为内部管理入口
- `techflow-app`、`techflow-h5`、`techflow-mini` 作为不同终端形态

这意味着后端不应该继续停留在“演示页面 + 几个示例接口”的 starter 形态，而应该逐步收敛为真正的多端共享业务平台。

## 当前现状

根目录已经拆成五个子模块，但只有 `techflow-server` 有实质代码。

当前后端模块主要是：

- `auth`
- `users`
- `site`
- `health`
- `common`
- `config`
- `prisma`
- `redis`

其中 `site` 模块同时承担了多种职责：

- 公开站点配置
- 功能卡片配置
- 客户线索提交
- 管理员线索读取
- 演示页 `/demo`
- 接口目录展示

这在 starter 阶段很方便，但在多端正式项目里会造成职责混杂。

## 项目级职责划分

| 模块 | 主要职责 | 不应该承担的职责 |
| --- | --- | --- |
| `techflow-server` | 统一鉴权、用户、共享业务、配置、消息、文件、集成 | 具体前端页面实现、临时展示逻辑 |
| `techflow-admin` | 运营后台、管理流程、数据查看、配置维护 | 核心业务规则、数据库直连逻辑 |
| `techflow-app` | 用户 App 页面、端能力、交互体验 | 核心业务规则复制实现 |
| `techflow-h5` | 落地页、活动页、分享页、轻交互场景 | 后端配置中心、权限系统 |
| `techflow-mini` | 小程序用户流程、生态接入 | 独立维护一套重复后端逻辑 |

## 后端目标模块

建议把 `techflow-server` 从“演示型模块”调整为“平台型模块”。可以按下面的职责来组织。

### 1. 平台基础层

- `common`
  公共守卫、拦截器、过滤器、装饰器、基础 DTO、错误码
- `config`
  环境变量、配置读取、配置校验
- `prisma`
  数据库访问基础设施
- `redis`
  缓存、会话、短期状态
- `health`
  健康检查、存活探针、依赖探测

这部分当前已经基本具备，可以保留。

### 2. 身份与账号层

- `auth`
  登录、刷新 token、退出、会话治理
- `users`
  当前用户、用户资料、账号状态
- 可进一步拆出 `permissions`
  角色、权限点、后台菜单权限、接口授权策略

说明：
当前 `auth` 和 `users` 的基础已经具备，但未来如果 `admin` 和 `mini` 存在不同登录方式，需要在这里继续扩展，而不是散落到各个业务模块里。

### 3. 多端共享能力层

- `client-config`
  客户端启动配置、功能开关、字典、版本策略、公共枚举
- `media`
  文件上传、图片资源、附件元数据
- `notification`
  短信、邮件、站内信、Push
- `integration`
  微信、小程序登录、支付、Webhook、第三方回调

说明：
这些模块是后续 `app/h5/mini/admin` 都容易依赖到的共享能力，应该优先作为平台能力建设，而不是夹在某个具体页面模块里。

### 4. 业务域模块

当前的 `site` 建议拆分成下面三个方向：

- `marketing`
  落地页配置、线索收集、活动表单、推广来源追踪
- `client-config`
  提供给各端初始化的配置，不再混在 `site/config` 里
- `demo`
  纯演示用途，单独保留，后续可移除

说明：
`线索` 是营销域数据，不应该长期挂在 `site` 这种泛化模块里。

### 5. 后台运营层

- `admin`
  后台聚合接口、统计视图、运营命令、审核流、报表接口

说明：
`admin` 模块不是把所有后台页面逻辑搬进服务端，而是提供“管理视角”的 API。它可以调用共享领域服务，但不应该成为新的万能模块。

## 推荐的接口边界

建议逐步收敛到下面的命名方式：

- `/health`
- `/docs`
- `/api/v1/auth/*`
- `/api/v1/users/*`
- `/api/v1/client-config/*`
- `/api/v1/marketing/*`
- `/api/v1/admin/*`
- `/api/v1/media/*`
- `/api/v1/notification/*`
- `/api/v1/integration/*`

如果未来确实需要端侧聚合接口，可以加：

- `/api/v1/app/*`
- `/api/v1/h5/*`
- `/api/v1/mini/*`

但这些端侧接口应该只承担“组装返回结构”的职责，不应该变成新的业务真相来源。

## 对当前代码的具体调整建议

### 建议立即调整

1. 保留 `auth`、`users`、`health`、`common`、`config`、`prisma`、`redis`
2. 把 `site` 按职责拆成：
   - `marketing`
   - `client-config`
   - `demo`
3. 将 `/demo` 认定为临时联调模块，不再继续往里面加正式业务能力
4. 给后端 README 和项目 README 明确“server 是共享服务层”的定位

### 建议第二阶段补齐

1. 增加 `admin` 模块
2. 增加 `media` 模块
3. 增加 `notification` 模块
4. 增加 `integration` 模块

### 暂时不用急着做的事

1. 不用一开始就拆微服务
2. 不用一开始就区分太多客户端专属模块
3. 不用为了“架构漂亮”先做复杂 DDD 分层

当前最合适的做法是先保持 NestJS 单体应用，但把模块职责划分清楚。

## 推荐的演进顺序

1. 先完成项目级职责定义
2. 再调整 `techflow-server` 模块命名和 API 命名
3. 再确定 `admin/app/h5/mini` 第一阶段需要消费的共享能力
4. 最后按真实业务补数据库模型和接口

## 一句话总结

TechFlow 现在最需要的不是继续增加 demo 接口，而是把 `techflow-server` 从“后端演示仓库”收敛成“多端共享服务平台”。
