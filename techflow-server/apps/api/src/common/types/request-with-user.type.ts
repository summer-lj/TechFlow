import type { Role } from '@prisma/client';
import type { Request } from 'express';

export interface JwtAuthenticatedUser {
  sub: string;
  email: string;
  role: Role;
  type: 'access';
}

export interface RequestWithUser extends Request {
  requestId?: string;
  user?: JwtAuthenticatedUser;
}
