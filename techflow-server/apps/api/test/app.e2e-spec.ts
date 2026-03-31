import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ClientPlatform, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import request from 'supertest';

import { AppModule } from '../src/app.module';
import { configureApplication } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { RedisService } from '../src/redis/redis.service';

describe('API starter (e2e)', () => {
  let app: INestApplication;
  let prismaService: PrismaService;
  let redisService: RedisService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    configureApplication(app, { enableSwagger: false });
    await app.init();

    prismaService = app.get(PrismaService);
    redisService = app.get(RedisService);

    await redisService.flushDatabase();
    await prismaService.lead.deleteMany();
    await prismaService.user.deleteMany();
    await prismaService.user.create({
      data: {
        email: 'e2e@example.com',
        phone: '13965026764',
        name: 'E2E User',
        passwordHash: await bcrypt.hash('123456', 10),
        role: Role.ADMIN,
        isActive: true,
      },
    });
  });

  afterAll(async () => {
    await prismaService.lead.deleteMany();
    await prismaService.user.deleteMany();
    await redisService.flushDatabase();
    await app.close();
  });

  it('/health (GET)', async () => {
    const response = await request(app.getHttpServer()).get('/health').expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.status).toBe('ok');
    expect(response.body.data.services.database).toBe('up');
    expect(response.body.data.services.redis).toBe('up');
  });

  it('/demo (GET)', async () => {
    const response = await request(app.getHttpServer()).get('/demo').expect(200);

    expect(response.text).toContain('Development Flow Demo');
    expect(response.text).toContain('/demo/app.js');
  });

  it('returns public site config and feature data', async () => {
    const [configResponse, featuresResponse, endpointsResponse] = await Promise.all([
      request(app.getHttpServer()).get('/api/v1/site/config').expect(200),
      request(app.getHttpServer()).get('/api/v1/site/features').expect(200),
      request(app.getHttpServer()).get('/api/v1/site/client-endpoints').expect(200),
    ]);

    expect(configResponse.body.data.title).toContain('一套后端');
    expect(featuresResponse.body.data).toHaveLength(4);
    expect(endpointsResponse.body.data.length).toBeGreaterThanOrEqual(5);
  });

  it('returns shared bootstrap data and an app-specific payload', async () => {
    const [clientBootstrapResponse, appBootstrapResponse, appHomeResponse] = await Promise.all([
      request(app.getHttpServer()).get('/api/v1/client-config/bootstrap').expect(200),
      request(app.getHttpServer()).get('/api/v1/app/bootstrap').expect(200),
      request(app.getHttpServer()).get('/api/v1/app/home').expect(200),
    ]);

    expect(clientBootstrapResponse.body.data.product.name).toBe('TechFlow');
    expect(clientBootstrapResponse.body.data.auth.loginPath).toBe('/api/v1/auth/login');
    expect(appBootstrapResponse.body.data.client).toBe('app');
    expect(appBootstrapResponse.body.data.routes.homePath).toBe('/api/v1/app/home');
    expect(appHomeResponse.body.data.sections).toHaveLength(2);
  });

  it('submits a public lead and lets an admin read it back', async () => {
    const createLeadResponse = await request(app.getHttpServer())
      .post('/api/v1/site/leads')
      .send({
        name: 'Potential Customer',
        email: 'customer@example.com',
        company: 'Demo Co',
        platform: ClientPlatform.MINI_PROGRAM,
        message: 'We need a mini-program backend launch plan.',
      })
      .expect(201);

    expect(createLeadResponse.body.success).toBe(true);
    expect(createLeadResponse.body.data.platform).toBe(ClientPlatform.MINI_PROGRAM);

    const loginResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        phone: '13965026764',
        password: '123456',
      })
      .expect(200);

    const accessToken = loginResponse.body.data.tokens.accessToken;

    const leadListResponse = await request(app.getHttpServer())
      .get('/api/v1/site/leads?page=1&pageSize=10')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(leadListResponse.body.data).toHaveLength(1);
    expect(leadListResponse.body.data[0].email).toBe('customer@example.com');
    expect(leadListResponse.body.meta.total).toBe(1);
  });

  it('logs in and reads the current user', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        phone: '13965026764',
        password: '123456',
      })
      .expect(200);

    expect(loginResponse.body.success).toBe(true);
    expect(loginResponse.body.data.tokens.accessToken).toBeDefined();
    expect(loginResponse.body.data.tokens.refreshToken).toBeDefined();

    const accessToken = loginResponse.body.data.tokens.accessToken;

    const meResponse = await request(app.getHttpServer())
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(meResponse.body.data.email).toBe('e2e@example.com');
  });

  it('registers a new user and allows app login with the new account', async () => {
    const registerResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        phone: '13965026765',
        password: '123456',
      })
      .expect(201);

    expect(registerResponse.body.success).toBe(true);
    expect(registerResponse.body.data.user.phone).toBe('13965026765');
    expect(registerResponse.body.data.tokens.accessToken).toBeDefined();

    const loginResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        phone: '13965026765',
        password: '123456',
      })
      .expect(200);

    expect(loginResponse.body.success).toBe(true);
    expect(loginResponse.body.data.user.role).toBe(Role.USER);
  });

  it('refreshes a token', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        phone: '13965026764',
        password: '123456',
      })
      .expect(200);

    const refreshResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/refresh')
      .send({
        refreshToken: loginResponse.body.data.tokens.refreshToken,
      })
      .expect(200);

    expect(refreshResponse.body.success).toBe(true);
    expect(refreshResponse.body.data.tokens.accessToken).toBeDefined();
    expect(refreshResponse.body.data.tokens.refreshToken).not.toBe(
      loginResponse.body.data.tokens.refreshToken,
    );
  });

  it('rejects missing bearer tokens on protected endpoints', async () => {
    const response = await request(app.getHttpServer()).get('/api/v1/users/me').expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('UNAUTHORIZED');
  });

  it('returns validation errors in a unified error shape', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        phone: 'not-a-phone',
        password: '123',
      })
      .expect(400);

    expect(response.body.success).toBe(false);
    expect(response.body.error.message).toBe('Validation failed');
    expect(response.body.error.details).toBeInstanceOf(Array);
  });
});
