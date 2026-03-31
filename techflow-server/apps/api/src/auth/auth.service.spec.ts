import { UnauthorizedException } from '@nestjs/common';
import type { JwtService } from '@nestjs/jwt';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import type { RedisService } from '../redis/redis.service';
import type { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

jest.mock('bcrypt', () => ({
  compare: jest.fn(),
  hash: jest.fn(),
}));

describe('AuthService', () => {
  const mockUser = {
    id: 'user_123',
    email: 'founder@example.com',
    name: 'Founder',
    passwordHash: 'hashed-password',
    role: Role.ADMIN,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const usersService = {
    findByEmail: jest.fn(),
    findById: jest.fn(),
    toPublicUser: jest.fn(),
  } as unknown as jest.Mocked<UsersService>;

  const jwtService = {
    signAsync: jest.fn(),
    verifyAsync: jest.fn(),
  } as unknown as jest.Mocked<JwtService>;

  const redisService = {
    setRefreshSession: jest.fn(),
    getRefreshSession: jest.fn(),
    deleteRefreshSession: jest.fn(),
  } as unknown as jest.Mocked<RedisService>;

  const configService = {
    getOrThrow: jest.fn((key: string) => {
      const values: Record<string, string> = {
        JWT_ACCESS_SECRET: 'access-secret-123456',
        JWT_REFRESH_SECRET: 'refresh-secret-123456',
        JWT_ACCESS_TTL: '15m',
        JWT_REFRESH_TTL: '7d',
      };

      return values[key];
    }),
  };

  let authService: AuthService;
  const mockedBcrypt = jest.mocked(bcrypt);

  beforeEach(() => {
    jest.clearAllMocks();
    authService = new AuthService(usersService, jwtService, redisService, configService as never);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('logs in a valid user and stores a refresh session', async () => {
    usersService.findByEmail.mockResolvedValue(mockUser);
    usersService.toPublicUser.mockReturnValue({
      id: mockUser.id,
      email: mockUser.email,
      name: mockUser.name,
      role: mockUser.role,
      isActive: mockUser.isActive,
      createdAt: mockUser.createdAt,
      updatedAt: mockUser.updatedAt,
    });
    jwtService.signAsync
      .mockResolvedValueOnce('access-token')
      .mockResolvedValueOnce('refresh-token');
    mockedBcrypt.compare.mockResolvedValue(true as never);
    mockedBcrypt.hash.mockResolvedValue('hashed-refresh-token' as never);

    const result = await authService.login({
      email: mockUser.email,
      password: 'ChangeMe123!',
    });

    expect(result.message).toBe('Login successful');
    expect(result.data.tokens.accessToken).toBe('access-token');
    expect(result.data.tokens.refreshToken).toBe('refresh-token');
    expect(redisService.setRefreshSession).toHaveBeenCalledTimes(1);
  });

  it('rejects invalid passwords', async () => {
    usersService.findByEmail.mockResolvedValue(mockUser);
    mockedBcrypt.compare.mockResolvedValue(false as never);

    await expect(
      authService.login({
        email: mockUser.email,
        password: 'wrong-password',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
