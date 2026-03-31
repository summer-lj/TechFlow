import { Injectable } from '@nestjs/common';

@Injectable()
export class ClientConfigService {
  getPublicSiteConfig() {
    return {
      title: '一套后端，服务 Web、H5、小程序、App',
      subtitle:
        '这是一个给创业团队演练开发、测试、发布流程的演示页。页面本身、表单提交、登录、鉴权和后台列表都由同一个 NestJS 后端支撑。',
      recommendedFlow: [
        '本地启动 Docker 开发环境',
        '浏览器打开 /demo',
        '提交线索表单并验证写库',
        '登录管理员并读取受保护接口',
        '执行 lint、test、build',
        '合并 main 自动发布 staging',
        '人工确认后提升到 production',
      ],
    };
  }

  getFeatureCards() {
    return [
      {
        tag: 'Local Dev',
        title: '本地一键启动',
        description: '用 Docker 启动 API、PostgreSQL、Redis，减少环境差异和新人配置成本。',
      },
      {
        tag: 'Client APIs',
        title: '多端共用接口',
        description: '同一套 REST API 可以供网页、H5、小程序和 App 共用，接口文档自动生成。',
      },
      {
        tag: 'Protected Flow',
        title: '公开接口 + 鉴权接口',
        description: '公开页面负责获客，管理员登录后读取受保护数据，完整覆盖真实业务链路。',
      },
      {
        tag: 'Release',
        title: '测试到生产发布',
        description: '合并 main 自动进 staging，通过后再人工审批晋升 production。',
      },
    ];
  }

  getSharedBootstrap() {
    return {
      product: {
        name: 'TechFlow',
        apiBasePath: '/api/v1',
      },
      auth: {
        loginMode: 'phone_password',
        accountField: 'phone',
        loginPath: '/api/v1/auth/login',
        refreshPath: '/api/v1/auth/refresh',
        logoutPath: '/api/v1/auth/logout',
        currentUserPath: '/api/v1/users/me',
      },
      publicConfig: {
        bootstrapPath: '/api/v1/client-config/bootstrap',
        featureCatalogPath: '/api/v1/client-config/features',
      },
    };
  }
}
