import { Injectable, NotFoundException } from '@nestjs/common';
import { ClientPlatform, LeadStatus, Prisma, Role } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import type { ListAdminLeadsQueryDto } from './dto/list-admin-leads-query.dto';
import type { UpdateLeadStatusDto } from './dto/update-lead-status.dto';

const statusLabels: Record<LeadStatus, string> = {
  [LeadStatus.NEW]: '待跟进',
  [LeadStatus.CONTACTED]: '已联系',
  [LeadStatus.QUALIFIED]: '高意向',
  [LeadStatus.ARCHIVED]: '已归档',
};

const platformLabels: Record<ClientPlatform, string> = {
  [ClientPlatform.WEB]: 'Web',
  [ClientPlatform.H5]: 'H5',
  [ClientPlatform.MINI_PROGRAM]: '小程序',
  [ClientPlatform.APP]: 'App',
};

@Injectable()
export class AdminService {
  constructor(private readonly prismaService: PrismaService) {}

  async getOverview() {
    const now = new Date();
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);

    const recentWindowStart = new Date(today);
    recentWindowStart.setDate(today.getDate() - 6);

    const previousWindowStart = new Date(today);
    previousWindowStart.setDate(today.getDate() - 13);

    const nextDay = new Date(today);
    nextDay.setDate(today.getDate() + 1);

    const [totalLeads, activeAdmins, statusBuckets, platformBuckets, recentLeads, activityRows] =
      await Promise.all([
        this.prismaService.lead.count(),
        this.prismaService.user.count({
          where: {
            role: Role.ADMIN,
            isActive: true,
          },
        }),
        this.prismaService.lead.groupBy({
          by: ['status'],
          _count: {
            _all: true,
          },
        }),
        this.prismaService.lead.groupBy({
          by: ['platform'],
          _count: {
            _all: true,
          },
        }),
        this.prismaService.lead.findMany({
          orderBy: {
            createdAt: 'desc',
          },
          take: 6,
        }),
        this.prismaService.lead.findMany({
          where: {
            createdAt: {
              gte: previousWindowStart,
              lt: nextDay,
            },
          },
          orderBy: {
            createdAt: 'asc',
          },
          select: {
            createdAt: true,
          },
        }),
      ]);

    const statusCountMap = new Map(
      statusBuckets.map((bucket) => [bucket.status, bucket._count._all]),
    );
    const platformCountMap = new Map(
      platformBuckets.map((bucket) => [bucket.platform, bucket._count._all]),
    );

    const pipeline = Object.values(LeadStatus).map((status) => {
      const count = statusCountMap.get(status) ?? 0;

      return {
        status,
        label: statusLabels[status],
        count,
        share: totalLeads > 0 ? Number(((count / totalLeads) * 100).toFixed(1)) : 0,
      };
    });

    const platforms = Object.values(ClientPlatform).map((platform) => {
      const count = platformCountMap.get(platform) ?? 0;

      return {
        platform,
        label: platformLabels[platform],
        count,
        share: totalLeads > 0 ? Number(((count / totalLeads) * 100).toFixed(1)) : 0,
      };
    });

    const activityIndex = new Map<string, number>();

    for (let dayOffset = 0; dayOffset < 7; dayOffset += 1) {
      const day = new Date(recentWindowStart);
      day.setDate(recentWindowStart.getDate() + dayOffset);
      activityIndex.set(this.toDateKey(day), 0);
    }

    let currentWindowCount = 0;
    let previousWindowCount = 0;

    for (const row of activityRows) {
      const createdAt = row.createdAt;

      if (createdAt >= recentWindowStart) {
        const key = this.toDateKey(createdAt);
        activityIndex.set(key, (activityIndex.get(key) ?? 0) + 1);
        currentWindowCount += 1;
        continue;
      }

      previousWindowCount += 1;
    }

    const activity = Array.from(activityIndex.entries()).map(([date, count]) => ({
      date,
      label: this.toShortDateLabel(date),
      count,
    }));

    const qualifiedLeads = statusCountMap.get(LeadStatus.QUALIFIED) ?? 0;
    const newLeads = statusCountMap.get(LeadStatus.NEW) ?? 0;

    return {
      kpis: {
        totalLeads,
        newLeads,
        qualifiedLeads,
        activeAdmins,
        conversionRate: totalLeads > 0 ? Number(((qualifiedLeads / totalLeads) * 100).toFixed(1)) : 0,
        weeklyTrendPercent: this.calculateTrend(currentWindowCount, previousWindowCount),
      },
      pipeline,
      platforms,
      activity,
      recentLeads,
      lastUpdatedAt: now.toISOString(),
    };
  }

  async listLeads(query: ListAdminLeadsQueryDto) {
    const page = query.page;
    const pageSize = query.pageSize;
    const keyword = query.keyword?.trim();
    const where: Prisma.LeadWhereInput = {};

    if (query.status) {
      where.status = query.status;
    }

    if (query.platform) {
      where.platform = query.platform;
    }

    if (keyword) {
      where.OR = [
        {
          name: {
            contains: keyword,
            mode: 'insensitive',
          },
        },
        {
          email: {
            contains: keyword,
            mode: 'insensitive',
          },
        },
        {
          company: {
            contains: keyword,
            mode: 'insensitive',
          },
        },
      ];
    }

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

  async updateLeadStatus(leadId: string, updateLeadStatusDto: UpdateLeadStatusDto) {
    try {
      return await this.prismaService.lead.update({
        where: { id: leadId },
        data: {
          status: updateLeadStatusDto.status,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') {
        throw new NotFoundException('Lead not found');
      }

      throw error;
    }
  }

  private calculateTrend(current: number, previous: number) {
    if (previous === 0) {
      return current > 0 ? 100 : 0;
    }

    return Number((((current - previous) / previous) * 100).toFixed(1));
  }

  private toDateKey(value: Date) {
    return value.toISOString().slice(0, 10);
  }

  private toShortDateLabel(dateKey: string) {
    const date = new Date(`${dateKey}T00:00:00.000Z`);
    return `${date.getUTCMonth() + 1}.${date.getUTCDate()}`;
  }
}
