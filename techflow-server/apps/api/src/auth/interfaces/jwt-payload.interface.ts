import type { Role } from '@prisma/client';

export interface JwtBasePayload {
  sub: string;
  email: string;
  role: Role;
  type: 'access' | 'refresh';
}

export interface JwtAccessPayload extends JwtBasePayload {
  type: 'access';
}

export interface JwtRefreshPayload extends JwtBasePayload {
  sessionId: string;
  type: 'refresh';
}
