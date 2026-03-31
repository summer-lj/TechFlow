# TechFlow 多端 API 分层设计与实施方案

## 目标

当 `techflow-admin`、`techflow-app`、`techflow-h5`、`techflow-mini` 需要不同接口时，目标不是给每个端各写一套独立后端，而是：

- 让共享业务规则只有一份
- 让不同客户端可以拿到适合自己的接口形态
- 让后台管理接口和用户端接口明确分离
- 让后端模块职责稳定，不因为前端页面差异而变成“大杂烩”

## 核心原则

### 1. 共享业务规则只能有一份

订单、用户、权限、活动、线索、支付、消息这些核心规则，只能在后端领域模块里实现一次。

不允许：

- `app` 一套规则
- `mini` 再写一套类似规则
- `admin` 再复制一套查询和状态流转

### 2. 不同客户端可以有不同接口

不同端的页面结构、交互节奏、加载策略不同，所以接口可以不同。

允许：

- `app` 首页接口一次返回多个卡片和推荐位
- `mini` 首页接口更轻，只返回首屏必要字段
- `admin` 列表接口支持复杂筛选、排序、分页、导出

但这些差异只应该体现在“接口聚合和返回结构”层，不应该让底层业务逻辑分叉。

### 3. 后台接口与用户接口必须分开

`admin` 的职责是管理、审核、配置、统计、运营，不应该直接复用面向用户的接口。

例如：

- 用户端是 `POST /api/v1/marketing/leads`
- 后台端应该是 `GET /api/v1/admin/leads`

不要让后台直接调用 `GET /api/v1/marketing/leads` 这种用户域接口，然后再不断往里面堆管理参数。

### 4. 端侧专属 API 只做聚合，不做真相来源

如果确实需要 `app`、`h5`、`mini` 各自的专属接口，这些接口只能做：

- 聚合多个领域服务
- 裁剪字段
- 调整返回结构
- 加入端侧特有的配置

不能做：

- 新增另一套业务规则
- 写另一套数据库流程
- 绕开共享权限体系

## 推荐的 API 分层

TechFlow 建议把接口分成五层。

### A. 平台基础 API

作用：

- 提供健康检查、登录、用户身份、基础配置等平台能力

典型路由：

- `/health`
- `/api/v1/auth/*`
- `/api/v1/users/*`
- `/api/v1/client-config/*`

典型使用方：

- 全部客户端

### B. 共享领域 API

作用：

- 放真正的业务真相和核心规则

典型模块：

- `marketing`
- `content`
- `order`
- `member`
- `message`

典型路由：

- `/api/v1/marketing/leads`
- `/api/v1/content/banners`
- `/api/v1/member/profile`

典型使用方：

- `app`
- `h5`
- `mini`
- `admin`

### C. 后台管理 API

作用：

- 提供运营、审核、报表、配置维护、复杂筛选视图

典型路由：

- `/api/v1/admin/leads`
- `/api/v1/admin/users`
- `/api/v1/admin/content/banners`
- `/api/v1/admin/dashboard`

典型使用方：

- `techflow-admin`

说明：

后台接口调用底层共享服务，但要有单独的控制器、DTO 和权限体系。

### D. 端侧聚合 API

作用：

- 给不同客户端返回更适合页面结构的数据形态

典型路由：

- `/api/v1/app/home`
- `/api/v1/h5/landing-pages/:code`
- `/api/v1/mini/home`
- `/api/v1/app/profile/overview`

典型使用方：

- 对应单一客户端

说明：

这些接口是 BFF 风格接口，但仍然在同一个 NestJS 服务内实现。

### E. 第三方集成 API

作用：

- 承接微信登录、支付回调、Webhook、消息回执等外部系统输入

典型路由：

- `/api/v1/integration/wechat/*`
- `/api/v1/integration/payment/*`
- `/api/v1/webhooks/*`

## 为未来拆分单独服务做准备

如果公司后面做大，TechFlow 很可能会从“模块化单体”演进到“少量独立服务”。现在设计时就应该为这一步做准备，但不要过早拆分。

当前建议是：

- 先保持一个 NestJS 应用
- 通过模块边界把职责切清楚
- 让 `domain`、`admin`、`app/h5/mini`、`integration` 之间只通过清晰的服务接口协作

这样后续如果要拆服务，可以按下面的方向演进：

- `member` 或 `users` 相关能力拆成账号服务
- `marketing` 拆成营销服务
- `content` 拆成内容服务
- `app/h5/mini` 的 BFF 层拆成独立网关或独立 BFF 服务
- `integration` 拆成第三方集成服务

为了让以后拆得动，现在就要遵守几条规则：

1. 不让控制器直接写数据库逻辑
2. 不让 `app/h5/mini/admin` 模块直接互相调用彼此的控制器
3. 共享规则沉淀在领域服务中，而不是埋在端侧接口里
4. DTO、权限、状态流转尽量模块内聚
5. 外部依赖接入统一放到 `integration` 或基础设施模块

一句话说：

现在做的是“可拆的单体”，而不是“一开始就拆开的微服务”。

## 推荐的职责划分

下面这张表是最核心的边界。

| 类型 | 面向谁 | 负责什么 | 不负责什么 |
| --- | --- | --- | --- |
| 平台基础 API | 全部客户端 | 登录、身份、配置、健康检查 | 复杂业务聚合 |
| 共享领域 API | 全部客户端与后台 | 核心业务规则、状态流转、数据存储 | 页面定制返回结构 |
| 后台管理 API | Admin | 管理、审核、报表、运营动作 | 用户端页面聚合 |
| 端侧聚合 API | 单一客户端 | 按端组装数据、裁剪字段 | 业务真相、核心规则 |
| 第三方集成 API | 外部系统 | 回调、同步、外部接入 | 前端页面服务 |

## 在当前 `techflow-server` 中怎么落地

当前后端已有模块：

- `auth`
- `users`
- `site`
- `health`
- `common`
- `config`
- `prisma`
- `redis`

问题在于 `site` 模块职责过于混合。建议按下面的目录逐步重构。

## 推荐目录结构

```text
techflow-server/apps/api/src/
├─ common/
├─ config/
├─ prisma/
├─ redis/
├─ modules/
│  ├─ platform/
│  │  ├─ health/
│  │  ├─ auth/
│  │  ├─ users/
│  │  └─ client-config/
│  ├─ domain/
│  │  ├─ marketing/
│  │  ├─ content/
│  │  ├─ member/
│  │  └─ ...
│  ├─ admin/
│  │  ├─ dashboard/
│  │  ├─ leads/
│  │  ├─ users/
│  │  └─ ...
│  ├─ bff/
│  │  ├─ app/
│  │  ├─ h5/
│  │  └─ mini/
│  └─ integration/
│     ├─ wechat/
│     ├─ payment/
│     └─ webhooks/
└─ app.module.ts
```

如果你不想一次性大改目录，也可以先保留现有目录风格，只调整模块命名：

```text
src/
├─ auth/
├─ users/
├─ health/
├─ client-config/
├─ marketing/
├─ admin/
├─ app/
├─ h5/
├─ mini/
├─ integration/
├─ common/
├─ config/
├─ prisma/
└─ redis/
```

## 推荐的模块职责

### `auth`

- 登录
- refresh token
- logout
- 会话治理
- 多端登录方式扩展

### `users`

- 当前用户
- 用户资料
- 账号状态
- 用户基础档案

### `client-config`

- 各端启动配置
- 字典项
- 功能开关
- 版本控制策略
- 客户端公共配置

说明：

当前 `site/config` 和 `site/features` 这类接口，未来更适合沉淀到这里，而不是继续挂在 `site`。

### `marketing`

- 落地页线索
- 活动表单
- 推广来源
- 公共营销内容

说明：

当前 `site/leads` 更适合迁移到 `marketing/leads`。

### `admin`

- 后台 dashboard
- 线索管理
- 用户管理
- 配置管理
- 审核和运营动作

说明：

后台模块是“管理视角接口”，不是万能聚合桶。按业务分子模块更合适，例如 `admin/leads`、`admin/users`、`admin/dashboard`。

### `app / h5 / mini`

- 只放端侧聚合接口
- 对接页面实际需要的数据结构
- 复用 `auth/users/marketing/client-config` 等领域服务

说明：

如果某个接口未来只有某一个端会用，而且它本质上是在“组装页面数据”，就放在对应端模块里。

例如：

- `GET /api/v1/app/home`
- `GET /api/v1/mini/home`
- `GET /api/v1/h5/campaign/:slug`

## 控制器与服务的实现规则

这是实施时最重要的一条。

### 规则 1：Controller 可以分开，Service 不要复制

可以有：

- `AdminLeadsController`
- `AppHomeController`
- `MiniHomeController`

但底层应该复用共享服务，例如：

- `LeadService`
- `BannerService`
- `UserProfileService`

### 规则 2：BFF Controller 只做组装

例如：

`AppHomeController` 可以：

- 调用 banner 服务
- 调用推荐服务
- 调用用户摘要服务
- 组装成 app 首页返回结构

但不应该：

- 直接写复杂 SQL
- 直接写核心状态流转
- 写成“只有 app 才懂”的业务规则真相

### 规则 3：Admin Controller 只负责管理动作

例如线索场景：

- `POST /api/v1/marketing/leads`
  用户提交线索
- `GET /api/v1/admin/leads`
  后台看线索列表
- `PATCH /api/v1/admin/leads/:id/status`
  后台修改线索状态

不要把这些动作都塞到一个 `SiteController` 或 `LeadController` 里。

## 路由设计建议

建议统一使用下面的命名方式。

### 平台公共

- `/api/v1/auth/login`
- `/api/v1/auth/refresh`
- `/api/v1/users/me`
- `/api/v1/client-config/bootstrap`

### 共享领域

- `/api/v1/marketing/leads`
- `/api/v1/marketing/campaigns`
- `/api/v1/content/banners`

### 后台管理

- `/api/v1/admin/dashboard`
- `/api/v1/admin/leads`
- `/api/v1/admin/users`
- `/api/v1/admin/content/banners`

### 端侧聚合

- `/api/v1/app/home`
- `/api/v1/app/profile`
- `/api/v1/h5/pages/:slug`
- `/api/v1/mini/home`

### 外部集成

- `/api/v1/integration/wechat/login`
- `/api/v1/integration/wechat/callback`
- `/api/v1/webhooks/payment`

## 一个典型例子

以“首页”场景为例。

### 不推荐的做法

- `GET /api/v1/site/home`
  同时给 app、h5、mini 用
- 然后不断加参数：
  `?client=app`
  `?client=mini`
  `?scene=activity`

这样很快就会变成巨型接口。

### 推荐的做法

共享领域服务提供：

- BannerService
- NoticeService
- RecommendationService

然后分成：

- `GET /api/v1/app/home`
- `GET /api/v1/mini/home`
- `GET /api/v1/h5/pages/home`

每个控制器分别调用共享服务，返回各自端需要的数据结构。

## TechFlow 当前最适合的实施顺序

### 第一阶段：先把边界定清

1. 保留 `auth`、`users`、`health`
2. 把 `site` 拆分思路定下来
3. 明确 `admin` 与 `app/h5/mini` 的接口边界

### 第二阶段：重命名和拆模块

建议优先做：

1. `site/config` -> `client-config`
2. `site/leads` -> `marketing`
3. 管理端读线索改成 `admin/leads`
4. `/demo` 单独保留为 `demo` 或未来移除

### 第三阶段：补 BFF 层

当各端页面开始落地后，再新增：

1. `app` 模块
2. `h5` 模块
3. `mini` 模块

这些模块初期只放确实存在差异化的数据聚合接口。

### 第四阶段：补后台管理层

随着 `techflow-admin` 开发推进，补：

1. `admin/dashboard`
2. `admin/leads`
3. `admin/users`
4. `admin/config`

## 对你当前项目的直接建议

如果现在就开始实施，我建议你先执行这套最小方案：

1. 保留现有 `auth`、`users`、`health`
2. 新建 `client-config` 模块，承接 `site/config`、`site/features`
3. 新建 `marketing` 模块，承接 `site/leads`
4. 新建 `admin/leads` 管理接口，不再用 `site/leads` 做后台读取
5. `site-page` 和 `/demo` 迁到 `demo` 模块，明确为临时演示能力
6. 暂时不要新建 `app/h5/mini` 模块，等真实页面出现后再只为差异化场景补 BFF

这套做法的好处是：

- 改动不大
- 立刻能把职责边界拉正
- 不会把项目过早做重
- 后面还能自然扩展到 `admin/app/h5/mini`

## 一句话结论

TechFlow 应该采用：

- 共享领域 API 做业务真相
- `admin` API 做管理视角
- `app/h5/mini` API 做端侧聚合

这样既能支持不同客户端拿不同接口，又不会把后端做成四套重复系统。
