import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { User } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import ms from 'ms';

import { RedisService } from '../redis/redis.service';
import { UsersService } from '../users/users.service';
import type { LoginDto } from './dto/login.dto';
import type { LogoutDto } from './dto/logout.dto';
import type { RefreshTokenDto } from './dto/refresh-token.dto';
import type { JwtAccessPayload, JwtRefreshPayload } from './interfaces/jwt-payload.interface';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
  ) {}

  async login(loginDto: LoginDto) {
    const user = await this.validateUser(loginDto.phone, loginDto.password);

    return {
      message: 'Login successful',
      data: await this.buildAuthPayload(user),
    };
  }

  async refresh(refreshTokenDto: RefreshTokenDto) {
    const payload = await this.verifyRefreshToken(refreshTokenDto.refreshToken);
    const storedHash = await this.redisService.getRefreshSession(payload.sub, payload.sessionId);

    if (!storedHash) {
      throw new UnauthorizedException('Refresh token expired or revoked');
    }

    const isValidToken = await bcrypt.compare(refreshTokenDto.refreshToken, storedHash);

    if (!isValidToken) {
      throw new UnauthorizedException('Refresh token expired or revoked');
    }

    const user = await this.usersService.findById(payload.sub);

    if (!user || !user.isActive) {
      throw new UnauthorizedException('User account is unavailable');
    }

    await this.redisService.deleteRefreshSession(payload.sub, payload.sessionId);

    return {
      message: 'Token refreshed successfully',
      data: await this.buildAuthPayload(user),
    };
  }

  async logout(logoutDto: LogoutDto) {
    try {
      const payload = await this.verifyRefreshToken(logoutDto.refreshToken);
      await this.redisService.deleteRefreshSession(payload.sub, payload.sessionId);
    } catch {
      return {
        message: 'Logout completed',
        data: { loggedOut: true },
      };
    }

    return {
      message: 'Logout completed',
      data: { loggedOut: true },
    };
  }

  async validateUser(phone: string, password: string) {
    const user = await this.usersService.findByPhone(phone);

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return user;
  }

  private async buildAuthPayload(user: User) {
    const publicUser = this.usersService.toPublicUser(user);
    const sessionId = randomUUID();

    const accessPayload: JwtAccessPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      type: 'access',
    };

    const refreshPayload: JwtRefreshPayload = {
      ...accessPayload,
      sessionId,
      type: 'refresh',
    };

    const accessTtl = this.configService.getOrThrow<string>('JWT_ACCESS_TTL');
    const refreshTtl = this.configService.getOrThrow<string>('JWT_REFRESH_TTL');

    const accessToken = await this.jwtService.signAsync(accessPayload, {
      secret: this.configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
      expiresIn: accessTtl,
    });

    const refreshToken = await this.jwtService.signAsync(refreshPayload, {
      secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
      expiresIn: refreshTtl,
    });

    await this.redisService.setRefreshSession(
      user.id,
      sessionId,
      await bcrypt.hash(refreshToken, 10),
      this.toSeconds(refreshTtl),
    );

    return {
      user: publicUser,
      tokens: {
        accessToken,
        refreshToken,
        tokenType: 'Bearer',
        expiresIn: this.toSeconds(accessTtl),
      },
    };
  }

  private async verifyRefreshToken(token: string) {
    try {
      const payload = await this.jwtService.verifyAsync<JwtRefreshPayload>(token, {
        secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });

      if (payload.type !== 'refresh' || !payload.sessionId) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      return payload;
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  private toSeconds(value: string) {
    const parsed = ms(value);

    if (typeof parsed !== 'number') {
      throw new Error(`Unsupported duration: ${value}`);
    }

    return Math.floor(parsed / 1000);
  }
}
