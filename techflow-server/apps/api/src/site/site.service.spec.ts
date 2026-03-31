import { ClientPlatform, LeadStatus } from '@prisma/client';

import { SiteService } from './site.service';

describe('SiteService', () => {
  const prismaService = {
    lead: {
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
  };
  const clientConfigService = {
    getPublicSiteConfig: jest.fn(),
    getFeatureCards: jest.fn(),
  };

  let siteService: SiteService;

  beforeEach(() => {
    jest.clearAllMocks();
    siteService = new SiteService(prismaService as never, clientConfigService as never);
  });

  it('returns a stable catalog of client endpoints', () => {
    const endpoints = siteService.getClientEndpoints();

    expect(endpoints).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          method: 'GET',
          path: '/api/v1/site/config',
        }),
        expect.objectContaining({
          method: 'POST',
          path: '/api/v1/auth/login',
        }),
      ]),
    );
  });

  it('creates a normalized lead', async () => {
    prismaService.lead.create.mockResolvedValue({
      id: 'lead_123',
      name: 'Potential Customer',
      email: 'customer@example.com',
      company: 'Demo Co',
      platform: ClientPlatform.APP,
      message: 'Need an app launch backend',
      status: LeadStatus.NEW,
      source: 'demo-page',
      createdAt: new Date('2026-03-30T12:00:00.000Z'),
      updatedAt: new Date('2026-03-30T12:00:00.000Z'),
    });

    const result = await siteService.createLead({
      name: 'Potential Customer',
      email: 'Customer@Example.com',
      company: 'Demo Co',
      platform: ClientPlatform.APP,
      message: 'Need an app launch backend',
    });

    expect(prismaService.lead.create).toHaveBeenCalledWith({
      data: {
        name: 'Potential Customer',
        email: 'customer@example.com',
        company: 'Demo Co',
        platform: ClientPlatform.APP,
        message: 'Need an app launch backend',
      },
    });
    expect(result.email).toBe('customer@example.com');
    expect(result.status).toBe(LeadStatus.NEW);
  });
});
