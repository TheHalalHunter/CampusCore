import { NestFactory, Reflector } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  const isProduction = config.get('NODE_ENV') === 'production';

  // Helmet — security headers (must be first middleware)
  // contentSecurityPolicy disabled so Swagger UI at /api/docs loads correctly
  app.use(helmet({ contentSecurityPolicy: false }));

  // Trust Railway / reverse-proxy headers (needed for correct IP logging)
  if (isProduction) {
    app.getHttpAdapter().getInstance().set('trust proxy', 1);
  }

  // Global prefix
  app.setGlobalPrefix('api/v1');

  // CORS — read allowed origins from env var (comma-separated); fall back to known prod + local dev origins
  const corsOriginsEnv = config.get<string>('CORS_ORIGINS');
  const allowedOrigins = corsOriginsEnv
    ? corsOriginsEnv.split(',').map((o) => o.trim())
    : [
        'https://campuscore-5658f.web.app',
        'https://campuscore-admin.web.app',
        'http://localhost:3000',
        'http://localhost:4200',
      ];
  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Global response interceptor
  app.useGlobalInterceptors(new ResponseInterceptor());

  // Swagger — dev only
  if (!isProduction) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('CampusCore API')
      .setDescription('CampusCore academic platform REST API')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = config.get<number>('PORT') || 3000;
  await app.listen(port, '0.0.0.0'); // bind to all interfaces for Docker/Railway
  console.log(`CampusCore API running on port ${port}`);
  if (!isProduction) {
    console.log(`Swagger docs at http://localhost:${port}/api/docs`);
  }
}

bootstrap();
