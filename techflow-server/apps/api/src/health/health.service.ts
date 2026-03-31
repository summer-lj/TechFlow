import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class HealthService {
  constructor(
    private readonly prismaService: PrismaService,
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
  ) {}

  async getStatus() {
    const startedAt = Date.now();

    await this.prismaService.$queryRawUnsafe('SELECT 1');
    await this.redisService.ping();

    return {
      status: 'ok',
      environment: this.configService.getOrThrow<string>('NODE_ENV'),
      appName: this.configService.getOrThrow<string>('APP_NAME'),
      services: {
        database: 'up',
        redis: 'up',
      },
      uptimeMs: Date.now() - startedAt,
    };
  }
}
