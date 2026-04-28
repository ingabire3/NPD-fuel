import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api/v1');

  app.enableCors({ origin: '*', credentials: true });

  const config = app.get(ConfigService);
  const port = config.get<number>('port') || 3000;

  await app.listen(port);
  console.log(`\n✅ NPD Fuel API running at http://localhost:${port}/api/v1\n`);
}
bootstrap();
