import { Module } from '@nestjs/common';

import { SiteController } from './site.controller';
import { SitePageController } from './site-page.controller';
import { SiteService } from './site.service';

@Module({
  controllers: [SiteController, SitePageController],
  providers: [SiteService],
})
export class SiteModule {}
