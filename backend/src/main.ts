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

  // Global prefix
  app.setGlobalPrefix("api/v1");

  // CORS
  const allowedOrigins = config.get<string>("ALLOWED_ORIGINS");
  app.enableCors({
    origin: allowedOrigins ? allowedOrigins.split(",") : ["http://localhost:3001"],
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // strip unknown properties
      forbidNonWhitelisted: true,
      transform: true, // auto-transform payloads to DTO types
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global response interceptor — wraps all success responses in { success, data }
  app.useGlobalInterceptors(new ResponseInterceptor());

  // Global exception filter — formats all errors in { success, statusCode, message }
  app.useGlobalFilters(new AllExceptionsFilter());

  // Swagger API docs (development only)
  if (config.get("NODE_ENV") !== "production") {
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
  await app.listen(port);
  console.log(`CampusCore API running on http://localhost:${port}/api/v1`);
  console.log(`Swagger docs at http://localhost:${port}/api/docs`);
}

bootstrap();
