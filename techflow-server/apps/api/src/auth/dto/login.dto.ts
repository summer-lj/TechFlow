import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MinLength } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: '13965026764' })
  @IsString()
  @Matches(/^1\d{10}$/, { message: 'phone must be a valid mainland China mobile number' })
  phone!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @MinLength(6)
  password!: string;
}
