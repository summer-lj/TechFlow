import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly client: Redis;

  constructor(private readonly configService: ConfigService) {
    this.client = new Redis(this.configService.getOrThrow<string>('REDIS_URL'), {
      lazyConnect: true,
      maxRetriesPerRequest: 1,
    });
  }

  async connect() {
    if (this.client.status === 'wait') {
      await this.client.connect();
    }
  }

  async ping(): Promise<string> {
    await this.connect();
    return this.client.ping();
  }

  async setRefreshSession(userId: string, sessionId: string, hash: string, ttlSeconds: number) {
    await this.connect();
    await this.client.set(this.refreshKey(userId, sessionId), hash, 'EX', ttlSeconds);
  }

  async getRefreshSession(userId: string, sessionId: string) {
    await this.connect();
    return this.client.get(this.refreshKey(userId, sessionId));
  }

  async deleteRefreshSession(userId: string, sessionId: string) {
    await this.connect();
    await this.client.del(this.refreshKey(userId, sessionId));
  }

  async flushDatabase() {
    await this.connect();
    await this.client.flushdb();
  }

  async onModuleDestroy() {
    if (this.client.status !== 'end') {
      await this.client.quit();
    }
  }

  private refreshKey(userId: string, sessionId: string) {
    return `auth:refresh:${userId}:${sessionId}`;
  }
}
