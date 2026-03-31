import { Logger } from 'nestjs-pino';
import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';
import { configureApplication } from './app.setup';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bufferLogs: true,
  });

  app.useLogger(app.get(Logger));
  configureApplication(app);

  const port = Number(process.env.PORT ?? 3000);
  const host = process.env.APP_HOST ?? '0.0.0.0';

  await app.listen(port, host);
}

void bootstrap();
