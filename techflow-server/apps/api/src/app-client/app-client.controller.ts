import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { Public } from '../common/decorators/public.decorator';
import { AppClientService } from './app-client.service';

@ApiTags('App')
@Controller('app')
export class AppClientController {
  constructor(private readonly appClientService: AppClientService) {}

  @Public()
  @Get('bootstrap')
  getBootstrap() {
    return {
      message: 'App bootstrap payload fetched successfully',
      data: this.appClientService.getBootstrap(),
    };
  }

  @Public()
  @Get('home')
  getHome() {
    return {
      message: 'App home payload fetched successfully',
      data: this.appClientService.getHome(),
    };
  }
}
