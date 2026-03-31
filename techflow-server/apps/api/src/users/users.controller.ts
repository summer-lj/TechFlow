import { Controller, Get, NotFoundException } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { JwtAuthenticatedUser } from '../common/types/request-with-user.type';
import { UsersService } from './users.service';

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getCurrentUser(@CurrentUser() currentUser: JwtAuthenticatedUser) {
    const user = await this.usersService.findById(currentUser.sub);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      message: 'Current user fetched successfully',
      data: this.usersService.toPublicUser(user),
    };
  }
}
