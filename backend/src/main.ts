import { NestFactory, Reflector } from "@nestjs/core";
import { ValidationPipe } from "@nestjs/common";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { ConfigService } from "@nestjs/config";
import { AppModule } from "./app.module";
import { ResponseInterceptor } from "./common/interceptors/response.interceptor";
import { AllExceptionsFilter } from "./common/filters/http-exception.filter";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  const isProduction = config.get("NODE_ENV") === "production";

  // Trust Railway / reverse-proxy headers (needed for correct IP logging)
  if (isProduction) {
    app.getHttpAdapter().getInstance().set("trust proxy", 1);
  }

  // Global prefix
  app.setGlobalPrefix("api/v1");

  // CORS — allow configured origins + localhost for development
  const allowedOrigins = config.get<string>("ALLOWED_ORIGINS");
  app.enableCors({
    origin: allowedOrigins
      ? allowedOrigins.split(",").map((o) => o.trim())
      : ["http://localhost:3001", "http://localhost:5080", "http://localhost:5081"],
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Accept"],
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

  // Global exception filter
  app.useGlobalFilters(new AllExceptionsFilter());

  // Swagger — dev only
  if (!isProduction) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle("CampusCore API")
      .setDescription("CampusCore academic platform REST API")
      .setVersion("1.0")
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup("api/docs", app, document);
  }

  const port = config.get<number>("PORT") || 3000;
  await app.listen(port, "0.0.0.0"); // bind to all interfaces for Docker/Railway
  console.log(`CampusCore API running on port ${port}`);
  if (!isProduction) {
    console.log(`Swagger docs at http://localhost:${port}/api/docs`);
  }
}

bootstrap();
