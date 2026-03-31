# TechFlow

面向 `App`、`Admin`、`H5`、`Mini Program` 的全栈软件架构项目。

当前项目的核心方向不是做五套彼此独立的系统，而是让 `techflow-server` 成为统一的业务服务层，为其他客户端模块提供稳定的鉴权、数据、配置和运营能力。

## 项目目标

- 用一套后端承接多端共享的账号、用户、配置、业务和运营能力。
- 让 `techflow-admin` 成为后台运营入口，而不是单独维护一套业务逻辑。
- 让 `techflow-app`、`techflow-h5`、`techflow-mini` 聚焦各自的交互体验和端能力，避免重复实现核心业务规则。

## 项目结构

- `techflow-server`
  TechFlow 的共享后端与平台服务层，当前已经包含 NestJS API、共享配置模块和 App 独立接口模块。
- `techflow-admin`
  面向内部运营、客服、内容管理、数据查看的后台管理系统。
- `techflow-app`
  面向终端用户的手机 App。
- `techflow-h5`
  面向活动页、落地页、分享页、轻交互页面的 H5 应用。
- `techflow-mini`
  面向微信等生态的小程序客户端。
- `docs`
  项目级架构说明和协作约定。

## 当前结构说明

当前仓库已经完成“多端目录 + 共享后端”的基础分层：

- `techflow-server`
  当前唯一有实质代码的模块，负责共享业务服务。
- `techflow-server/apps/api/src/auth`
  统一登录、刷新 token、退出登录等账号能力。
- `techflow-server/apps/api/src/users`
  当前用户和用户基础资料接口。
- `techflow-server/apps/api/src/health`
  健康检查和依赖探活。
- `techflow-server/apps/api/src/client-config`
  多端共享的启动配置和公共能力目录。
- `techflow-server/apps/api/src/app-client`
  App 独立接口模块，负责移动端聚合接口，不直接承载底层业务真相。
- `techflow-server/apps/api/src/site`
  当前仍保留的 demo/公开接口模块，后续会继续拆分为更稳定的业务边界。
- `docs/architecture.md`
  项目级职责、模块边界和整体架构说明。
- `docs/multi-client-api-design.md`
  多端 API 分层、BFF 设计和未来可拆服务的实施方案。

## 模块职责边界

### `techflow-server` 负责什么

- 统一登录、会话、角色、权限。
- 用户资料、账号状态、基础档案。
- 多端共享的业务规则和数据持久化。
- 给 `app/h5/mini/admin` 提供 API、任务、消息、文件、集成能力。
- 平台级配置，例如启动配置、字典、功能开关、版本策略。
- 与数据库、Redis、第三方平台的集成。

### `techflow-server` 不负责什么

- 不长期承载各个客户端的页面实现。
- 不把前端展示文案、交互状态、页面结构和服务端业务逻辑混在一起。
- 不把“演示页面”当成正式业务模块继续扩张。

### `techflow-admin` 负责什么

- 运营和管理视角的页面与流程。
- 管理端专属的数据聚合、筛选、报表展示。
- 调用后端的管理接口，不重复实现领域规则。

### `techflow-app / techflow-h5 / techflow-mini` 负责什么

- 面向用户的页面、交互、端能力接入。
- 端内路由、状态管理、页面编排。
- 按需调用后端提供的公共业务接口或端侧聚合接口。

## 当前状态

- 根目录已经完成多模块目录拆分。
- `techflow-server` 已经有可运行的 NestJS 后端骨架，并开始按“共享配置 + 独立端侧接口模块”拆分。
- `techflow-admin`、`techflow-app`、`techflow-h5`、`techflow-mini` 目前还是空目录，说明现在最需要先定义清楚的是整体职责和服务边界。

## 对 `techflow-server` 的调整建议

当前后端模块以 `auth / users / site / health` 为主，其中 `site` 同时承载了公开配置、演示页面、线索表单和接口目录，偏向 starter/demo 结构。为了让后端真正服务其他模块，建议做下面的职责拆分：

1. 保留平台基础模块：
   `auth`、`users`、`health`、`common`、`config`、`prisma`、`redis`
2. 将 `site` 拆成更稳定的业务边界：
   `marketing`、`client-config`、`demo`
3. 新增面向多端协作的模块：
   `admin`、`media`、`notification`、`integration`
4. 把演示页面能力降级为临时模块：
   `/demo` 只用于联调或演示，不作为正式业务入口继续扩展

更详细的职责说明见 [docs/architecture.md](/Users/liujun/liujun/TechFlow/docs/architecture.md)。

## 建议的协作原则

- 领域规则只放在后端，不在多个前端重复实现。
- 前端如果需要端侧差异化接口，优先做聚合层，不复制底层业务逻辑。
- 后台管理需求优先落到 `admin` 视角的接口，而不是直接复用面向用户的接口。
- 演示模块和正式业务模块分开维护，避免技术债直接进入主路径。

## 下一步建议

1. 先把 `techflow-server` 的模块命名和职责调整到位。
2. 再确定 `admin/app/h5/mini` 第一阶段各自要消费哪些接口。
3. 然后按真实业务补齐数据库模型和接口，而不是继续围绕 demo 页面扩展。

## 初始化

- `2026-03-31` 项目创建
