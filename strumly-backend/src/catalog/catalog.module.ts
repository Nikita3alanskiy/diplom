import { Module } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { CatalogController } from './catalog.controller';
import { SongsModule } from '../songs/songs.module';

@Module({
  imports: [SongsModule],
  providers: [CatalogService],
  controllers: [CatalogController],
})
export class CatalogModule {}
