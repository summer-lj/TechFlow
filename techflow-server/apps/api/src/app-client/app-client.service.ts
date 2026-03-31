import { Injectable } from '@nestjs/common';

import { ClientConfigService } from '../client-config/client-config.service';

@Injectable()
export class AppClientService {
  constructor(private readonly clientConfigService: ClientConfigService) {}

  getBootstrap() {
    const hero = this.clientConfigService.getPublicSiteConfig();
    const features = this.clientConfigService.getFeatureCards();

    return {
      client: 'app',
      routes: {
        bootstrapPath: '/api/v1/app/bootstrap',
        homePath: '/api/v1/app/home',
      },
      shared: this.clientConfigService.getSharedBootstrap(),
      home: {
        hero,
        featureCards: features,
      },
    };
  }

  getHome() {
    const hero = this.clientConfigService.getPublicSiteConfig();
    const features = this.clientConfigService.getFeatureCards();

    return {
      client: 'app',
      hero,
      sections: [
        {
          code: 'recommended-flow',
          title: '推荐流程',
          items: hero.recommendedFlow,
        },
        {
          code: 'feature-cards',
          title: '能力模块',
          items: features,
        },
      ],
      quickActions: [
        {
          label: '登录',
          method: 'POST',
          path: '/api/v1/auth/login',
        },
        {
          label: '查看当前用户',
          method: 'GET',
          path: '/api/v1/users/me',
          requiresAuth: true,
        },
      ],
    };
  }
}
