import { Controller, Get, Header, Res } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import type { Response } from 'express';

import { Public } from '../common/decorators/public.decorator';
import { getDemoPageHtml, getDemoPageScript, getDemoPageStyles } from './page/demo-page.templates';

@ApiExcludeController()
@Controller('demo')
export class SitePageController {
  @Public()
  @Get()
  @Header('Content-Type', 'text/html; charset=utf-8')
  getDemoPage(@Res() response: Response) {
    response.send(getDemoPageHtml());
  }

  @Public()
  @Get('app.js')
  @Header('Content-Type', 'application/javascript; charset=utf-8')
  getDemoScript(@Res() response: Response) {
    response.send(getDemoPageScript());
  }

  @Public()
  @Get('style.css')
  @Header('Content-Type', 'text/css; charset=utf-8')
  getDemoStyles(@Res() response: Response) {
    response.send(getDemoPageStyles());
  }
}
