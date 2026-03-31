import { ApiPropertyOptional } from '@nestjs/swagger';
import { ClientPlatform, LeadStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';

export class ListAdminLeadsQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: LeadStatus })
  @IsOptional()
  @IsEnum(LeadStatus)
  status?: LeadStatus;

  @ApiPropertyOptional({ enum: ClientPlatform })
  @IsOptional()
  @IsEnum(ClientPlatform)
  platform?: ClientPlatform;

  @ApiPropertyOptional({ example: 'liu' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  keyword?: string;
}
