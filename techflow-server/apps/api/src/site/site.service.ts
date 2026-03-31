import { Injectable } from '@nestjs/common';
import { ClientPlatform, LeadStatus } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import type { CreateLeadDto } from './dto/create-lead.dto';
import type { ListLeadsQueryDto } from './dto/list-leads-query.dto';

@Injectable()
export class SiteService {
  constructor(private readonly prismaService: PrismaService) {}

  getConfig() {
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

  getFeatures() {
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
