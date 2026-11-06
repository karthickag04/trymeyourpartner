import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ApiConfig } from './config';

/** Shared by main.ts and the tests: CORS and OpenAPI docs at /docs. */
export function configureApp(app: INestApplication, config: ApiConfig) {
  app.enableCors({ origin: config.corsOrigins.length ? config.corsOrigins : false });
  const doc = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle('TryMeYourPartner API')
      .setDescription(
        'Member API. Sign in with Supabase and send the access token as a Bearer token.',
      )
      .setVersion('0.1.0')
      .addBearerAuth()
      .build(),
  );
  SwaggerModule.setup('docs', app, doc, { jsonDocumentUrl: 'docs/openapi.json' });
}
