import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ClientPlatform } from '@prisma/client';
import { IsEmail, IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateLeadDto {
  @ApiProperty({ example: 'Liu Jun' })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  name!: string;

  @ApiProperty({ example: 'founder@example.com' })
  @IsEmail()
  email!: string;

  @ApiPropertyOptional({ example: 'Startup Studio' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  company?: string;

  @ApiProperty({ enum: ClientPlatform, example: ClientPlatform.WEB })
  @IsEnum(ClientPlatform)
  platform!: ClientPlatform;

  @ApiPropertyOptional({ example: 'We want to launch a cross-platform membership product.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}
