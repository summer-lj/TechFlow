import { ClientPlatform, LeadStatus, Role } from '@prisma/client';

import { AdminService } from './admin.service';

describe('AdminService', () => {
  const prismaService = {
    lead: {
      count: jest.fn(),
      groupBy: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    user: {
      count: jest.fn(),
    },
  };

  let adminService: AdminService;

  beforeEach(() => {
    jest.clearAllMocks();
    adminService = new AdminService(prismaService as never);
  });

  it('builds the admin overview payload', async () => {
    prismaService.lead.count.mockResolvedValue(12);
    prismaService.user.count.mockResolvedValue(2);
    prismaService.lead.groupBy
      .mockResolvedValueOnce([
        { status: LeadStatus.NEW, _count: { _all: 5 } },
        { status: LeadStatus.QUALIFIED, _count: { _all: 3 } },
      ])
      .mockResolvedValueOnce([
        { platform: ClientPlatform.WEB, _count: { _all: 7 } },
        { platform: ClientPlatform.APP, _count: { _all: 5 } },
      ]);
    prismaService.lead.findMany
      .mockResolvedValueOnce([
        {
          id: 'lead_1',
          name: 'Liu Jun',
          email: 'liu@example.com',
          company: 'TechFlow',
          platform: ClientPlatform.WEB,
          message: 'Need admin portal',
          source: 'demo-page',
          status: LeadStatus.NEW,
          createdAt: new Date('2026-03-30T12:00:00.000Z'),
          updatedAt: new Date('2026-03-30T12:00:00.000Z'),
        },
      ])
      .mockResolvedValueOnce([
        { createdAt: new Date('2026-03-25T12:00:00.000Z') },
        { createdAt: new Date('2026-03-29T12:00:00.000Z') },
      ]);

    const overview = await adminService.getOverview();

    expect(prismaService.user.count).toHaveBeenCalledWith({
      where: {
        role: Role.ADMIN,
        isActive: true,
      },
    });
    expect(overview.kpis.totalLeads).toBe(12);
    expect(overview.kpis.qualifiedLeads).toBe(3);
    expect(overview.pipeline).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          status: LeadStatus.NEW,
          count: 5,
        }),
      ]),
    );
    expect(overview.platforms).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          platform: ClientPlatform.WEB,
          count: 7,
        }),
      ]),
    );
    expect(overview.recentLeads).toHaveLength(1);
  });

  it('updates the lead status', async () => {
    prismaService.lead.update.mockResolvedValue({
      id: 'lead_2',
      status: LeadStatus.CONTACTED,
    });

    const result = await adminService.updateLeadStatus('lead_2', {
      status: LeadStatus.CONTACTED,
    });

    expect(prismaService.lead.update).toHaveBeenCalledWith({
      where: { id: 'lead_2' },
      data: {
        status: LeadStatus.CONTACTED,
      },
    });
    expect(result).toEqual({
      id: 'lead_2',
      status: LeadStatus.CONTACTED,
    });
  });
});
