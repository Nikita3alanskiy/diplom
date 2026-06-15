import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors();
  app.setGlobalPrefix('api');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  // Налаштування Swagger
  const config = new DocumentBuilder()
    .setTitle('Strumly API')
    .setDescription('Документація API для музичного додатку Strumly')
    .setVersion('1.0')
    .addBearerAuth() // Додає можливість вводити JWT токен
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document); // Swagger will be available at /api/docs

  await app.listen(3000, '0.0.0.0');
  console.log(`🚀 API is running on: ${await app.getUrl()}/api`);
  console.log(`📄 Swagger Docs available at: ${await app.getUrl()}/docs`);
}
bootstrap();
