import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: '13965026765' })
  @IsString()
  @Matches(/^1\d{10}$/, { message: 'phone must be a valid mainland China mobile number' })
  phone!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @MinLength(6)
  password!: string;
}
