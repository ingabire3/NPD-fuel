import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Set global prefix for all routes
  app.setGlobalPrefix('api/v1');

  // Enable CORS for mobile app
  app.enableCors({ 
    origin: '*', 
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  const config = app.get(ConfigService);
  const port = config.get<number>('port') || 3000;

  // Important: Bind to 0.0.0.0 for Render
  await app.listen(port, '0.0.0.0');
  console.log(`\n✅ NPD Fuel API running at http://localhost:${port}/api/v1\n`);
}
bootstrap();