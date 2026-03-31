import { Module } from '@nestjs/common';

import { ClientConfigModule } from '../client-config/client-config.module';
import { AppClientController } from './app-client.controller';
import { AppClientService } from './app-client.service';

@Module({
  imports: [ClientConfigModule],
  controllers: [AppClientController],
  providers: [AppClientService],
})
export class AppClientModule {}
