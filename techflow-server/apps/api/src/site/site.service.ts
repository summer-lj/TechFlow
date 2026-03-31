import { Injectable } from '@nestjs/common';
import { ClientPlatform, LeadStatus } from '@prisma/client';

import { ClientConfigService } from '../client-config/client-config.service';
import { PrismaService } from '../prisma/prisma.service';
import type { CreateLeadDto } from './dto/create-lead.dto';
import type { ListLeadsQueryDto } from './dto/list-leads-query.dto';

@Injectable()
export class SiteService {
  constructor(
    private readonly prismaService: PrismaService,
    private readonly clientConfigService: ClientConfigService,
  ) {}

  getConfig() {
    return this.clientConfigService.getPublicSiteConfig();
  }

  getFeatures() {
    return this.clientConfigService.getFeatureCards();
  }

  getClientEndpoints() {
    return [
      {
        audience: 'Public',
        name: '读取站点配置',
        method: 'GET',
        path: '/api/v1/site/config',
        description: '网页、H5、小程序首页初始化时读取基础文案和流程提示。',
      },
      {
        audience: 'Public',
        name: '读取功能卡片',
        method: 'GET',
        path: '/api/v1/site/features',
        description: '客户端用来渲染营销卡片、产品卖点或新手引导。',
      },
      {
        audience: 'Public',
        name: '读取共享启动配置',
        method: 'GET',
        path: '/api/v1/client-config/bootstrap',
        description: '各客户端启动时读取共享配置、登录接口路径和公共 API 前缀。',
      },
      {
        audience: 'Public',
        name: '读取共享功能目录',
        method: 'GET',
        path: '/api/v1/client-config/features',
        description: '各客户端读取统一功能卡片和公共能力目录。',
      },
      {
        audience: 'Public',
        name: '提交客户线索',
        method: 'POST',
        path: '/api/v1/site/leads',
        description: '落地页、活动页、小程序表单统一提交线索到后端。',
      },
      {
        audience: 'Auth',
        name: '管理员登录',
        method: 'POST',
        path: '/api/v1/auth/login',
        description: '后台管理端、运营工具、调试页面都通过这条接口获取访问令牌。',
      },
      {
        audience: 'Auth',
        name: '读取当前用户',
        method: 'GET',
        path: '/api/v1/users/me',
        description: '客户端登录后读取当前身份，判断角色和权限。',
      },
      {
        audience: 'App',
        name: '读取 App 启动聚合数据',
        method: 'GET',
        path: '/api/v1/app/bootstrap',
        description: 'App 独立接口模块返回启动页、首页初始化所需的聚合数据。',
      },
      {
        audience: 'App',
        name: '读取 App 首页数据',
        method: 'GET',
        path: '/api/v1/app/home',
        description: 'App 独立接口模块根据移动端页面结构返回首页区块数据。',
      },
      {
        audience: 'Admin',
        name: '读取线索列表',
        method: 'GET',
        path: '/api/v1/site/leads?page=1&pageSize=10',
        description: '管理员登录后查看最近提交的线索，验证受保护数据接口。',
      },
    ];
  }

  async createLead(createLeadDto: CreateLeadDto) {
    const lead = await this.prismaService.lead.create({
      data: {
        name: createLeadDto.name.trim(),
        email: createLeadDto.email.toLowerCase(),
        company: createLeadDto.company?.trim() || null,
        platform: createLeadDto.platform,
        message: createLeadDto.message?.trim() || null,
      },
    });

    return {
      id: lead.id,
      name: lead.name,
      email: lead.email,
      company: lead.company,
      platform: lead.platform,
      status: lead.status,
      createdAt: lead.createdAt,
    };
  }

  async listLeads(query: ListLeadsQueryDto) {
    const page = query.page;
    const pageSize = query.pageSize;
    const where = query.status ? { status: query.status } : {};

    const [items, total] = await Promise.all([
      this.prismaService.lead.findMany({
        where,
        orderBy: {
          createdAt: 'desc',
        },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prismaService.lead.count({ where }),
    ]);

    return {
      items,
      meta: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
        hasNextPage: page * pageSize < total,
      },
    };
  }

  getPlatformOptions() {
    return Object.values(ClientPlatform);
  }

  getLeadStatuses() {
    return Object.values(LeadStatus);
  }
}
