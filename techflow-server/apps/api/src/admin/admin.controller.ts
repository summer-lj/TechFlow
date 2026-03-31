import { Body, Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';

import { Roles } from '../common/decorators/roles.decorator';
import { AdminService } from './admin.service';
import { ListAdminLeadsQueryDto } from './dto/list-admin-leads-query.dto';
import { UpdateLeadStatusDto } from './dto/update-lead-status.dto';

@ApiTags('Admin')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('overview')
  async getOverview() {
    return {
      message: 'Admin overview fetched successfully',
      data: await this.adminService.getOverview(),
    };
  }

  @Get('leads')
  async listLeads(@Query() query: ListAdminLeadsQueryDto) {
    const result = await this.adminService.listLeads(query);

    return {
      message: 'Admin lead list fetched successfully',
      data: result.items,
      meta: result.meta,
    };
  }

  @Patch('leads/:leadId/status')
  async updateLeadStatus(
    @Param('leadId') leadId: string,
    @Body() updateLeadStatusDto: UpdateLeadStatusDto,
  ) {
    return {
      message: 'Lead status updated successfully',
      data: await this.adminService.updateLeadStatus(leadId, updateLeadStatusDto),
    };
  }
}
