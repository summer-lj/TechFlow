import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { Public } from '../common/decorators/public.decorator';
import { ClientConfigService } from './client-config.service';

@ApiTags('Client Config')
@Controller('client-config')
export class ClientConfigController {
  constructor(private readonly clientConfigService: ClientConfigService) {}

  @Public()
  @Get('bootstrap')
  getBootstrap() {
    return {
      message: 'Client bootstrap config fetched successfully',
      data: this.clientConfigService.getSharedBootstrap(),
    };
  }

  @Public()
  @Get('features')
  getFeatures() {
    return {
      message: 'Client feature catalog fetched successfully',
      data: this.clientConfigService.getFeatureCards(),
    };
  }
}
