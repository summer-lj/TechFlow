import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';

import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { CreateLeadDto } from './dto/create-lead.dto';
import { ListLeadsQueryDto } from './dto/list-leads-query.dto';
import { SiteService } from './site.service';

@ApiTags('Site')
@Controller('site')
export class SiteController {
  constructor(private readonly siteService: SiteService) {}

  @Public()
  @Get('config')
  getConfig() {
    return {
      message: 'Site config fetched successfully',
      data: this.siteService.getConfig(),
    };
  }

  @Public()
  @Get('features')
  getFeatures() {
    return {
      message: 'Site features fetched successfully',
      data: this.siteService.getFeatures(),
    };
  }

  @Public()
  @Get('client-endpoints')
  getClientEndpoints() {
    return {
      message: 'Client endpoint catalog fetched successfully',
      data: this.siteService.getClientEndpoints(),
    };
  }

  @Public()
  @Post('leads')
  async createLead(@Body() createLeadDto: CreateLeadDto) {
    return {
      message: 'Lead submitted successfully',
      data: await this.siteService.createLead(createLeadDto),
    };
  }

  @ApiBearerAuth()
  @Roles(Role.ADMIN)
  @Get('leads')
  async listLeads(@Query() query: ListLeadsQueryDto) {
    const result = await this.siteService.listLeads(query);

    return {
      message: 'Lead list fetched successfully',
      data: result.items,
      meta: result.meta,
    };
  }
}
