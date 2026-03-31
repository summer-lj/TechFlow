import { Module } from '@nestjs/common';

import { ClientConfigModule } from '../client-config/client-config.module';
import { SiteController } from './site.controller';
import { SitePageController } from './site-page.controller';
import { SiteService } from './site.service';

@Module({
  imports: [ClientConfigModule],
  controllers: [SiteController, SitePageController],
  providers: [SiteService],
})
export class SiteModule {}
