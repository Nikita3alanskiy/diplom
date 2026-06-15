import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  ParseIntPipe,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import * as fs from 'fs';
import { SongsService } from './songs.service';
import { CreateSongDto } from './dto/create-song.dto';

@ApiTags('songs')
@Controller('songs')
export class SongsController {
  constructor(private readonly songsService: SongsService) {}

  @Post('upload')
  @ApiOperation({ summary: 'Завантажити аудіофайл' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, file, cb) => {
          const uploadPath = './uploads';
          if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath);
          }
          cb(null, uploadPath);
        },
        filename: (req, file, cb) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          cb(null, `${uniqueSuffix}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  uploadAudio(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new Error('Файл не знайдено');
    }
    // Повертаємо відносний шлях, фронтенд сам додасть свій baseUrl
    const fileUrl = `/uploads/${file.filename}`;
    return { url: fileUrl };
  }

  @Post('parse')
  @ApiOperation({ summary: 'Спарсити пісню за посиланням' })
  parseSong(@Body('url') url: string) {
    return this.songsService.parseFromUrl(url);
  }

  @Post()
  @ApiOperation({ summary: 'Додати нову пісню' })
  create(@Body() dto: CreateSongDto) {
    return this.songsService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Отримати список усіх пісень' })
  findAll() {
    return this.songsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Отримати пісню за ID' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.songsService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Оновити пісню' })
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: CreateSongDto) {
    return this.songsService.update(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Видалити пісню' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.songsService.remove(id);
  }
}
