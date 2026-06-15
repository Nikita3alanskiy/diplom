import { Controller, Get, Post, Query, Body, Param } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('catalog')
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('search')
  @ApiOperation({ summary: 'Пошук пісень та виконавців в каталозі' })
  search(@Query('q') query: string) {
    return this.catalogService.search(query);
  }

  @Post('import')
  @ApiOperation({ summary: 'Імпортувати пісню з каталогу' })
  importSong(@Body('url') url: string) {
    return this.catalogService.importSong(url);
  }
}
