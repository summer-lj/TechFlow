import { Injectable } from '@nestjs/common';
import type { User } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';

export type PublicUser = Omit<User, 'passwordHash'>;
type CreateRegisteredUserInput = {
  phone: string;
  passwordHash: string;
};

@Injectable()
export class UsersService {
  constructor(private readonly prismaService: PrismaService) {}

  async findById(id: string) {
    return this.prismaService.user.findUnique({ where: { id } });
  }

  async findByEmail(email: string) {
    return this.prismaService.user.findUnique({
      where: { email: email.toLowerCase() },
    });
  }

  async findByPhone(phone: string) {
    return this.prismaService.user.findUnique({
      where: { phone: phone.replace(/\D/g, '') },
    });
  }

  async createRegisteredUser(input: CreateRegisteredUserInput) {
    const normalizedPhone = input.phone.replace(/\D/g, '');

    return this.prismaService.user.create({
      data: {
        phone: normalizedPhone,
        email: `${normalizedPhone}@techflow.local`,
        name: `TechFlow 用户 ${normalizedPhone.slice(-4)}`,
        passwordHash: input.passwordHash,
      },
    });
  }

  toPublicUser(user: User): PublicUser {
    const { passwordHash: _passwordHash, ...safeUser } = user;
    return safeUser;
  }
}
