import {
  Controller, Get, Put, Post, Delete,
  Req, Body, Param, ParseIntPipe,
  UseGuards, UseInterceptors, UploadedFile, UploadedFiles,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { ProfileService } from './profile.service';

@ApiTags('Профіль')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  private getUserId(req: any): number {
    const id = Number(req.user?.sub ?? req.user?.id);
    if (!id || isNaN(id)) throw new BadRequestException('Invalid token. Please re-login.');
    return id;
  }

  @Put('me')
  @ApiOperation({ summary: 'Оновити ім\'я профілю' })
  updateName(@Req() req, @Body() body: { name?: string }) {
    return this.profileService.updateProfile(this.getUserId(req), body.name);
  }

  @Get('user/:id')
  @ApiOperation({ summary: 'Отримати публічний профіль іншого користувача' })
  getPublicProfile(@Param('id', ParseIntPipe) id: number) {
    return this.profileService.getPublicProfile(id);
  }

  @Post('avatar')
  @ApiOperation({ summary: 'Завантажити аватарку' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: join(process.cwd(), 'uploads', 'avatars'),
      filename: (_, file, cb) => {
        const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, unique + extname(file.originalname));
      },
    }),
    fileFilter: (_, file, cb) => {
      if (!file.mimetype.match(/\/(jpg|jpeg|png|gif|webp)$/)) {
        return cb(new BadRequestException('Only image files allowed'), false);
      }
      cb(null, true);
    },
    limits: { fileSize: 5 * 1024 * 1024 },
  }))
  async uploadAvatar(@Req() req, @UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file uploaded');
    const avatarUrl = `/uploads/avatars/${file.filename}`;
    return this.profileService.updateProfile(this.getUserId(req), undefined, avatarUrl);
  }

  @Get('videos')
  @ApiOperation({ summary: 'Отримати кавер-відео профілю' })
  getVideos(@Req() req) {
    return this.profileService.getCoverVideos(this.getUserId(req));
  }

  @Post('videos')
  @ApiOperation({ summary: 'Завантажити кавер-відео (файл)' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: join(process.cwd(), 'uploads', 'covers'),
      filename: (_, file, cb) => {
        const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, unique + extname(file.originalname));
      },
    }),
    fileFilter: (_, file, cb) => {
      if (!file.mimetype.match(/^video\//)) {
        return cb(new BadRequestException('Only video files allowed'), false);
      }
      cb(null, true);
    },
    limits: { fileSize: 200 * 1024 * 1024 }, // 200MB
  }))
  async uploadVideo(@Req() req, @UploadedFile() file: Express.Multer.File, @Body() body: { title?: string }) {
    if (!file) throw new BadRequestException('No file uploaded');
    const videoUrl = `/uploads/covers/${file.filename}`;
    return this.profileService.addCoverVideo(this.getUserId(req), videoUrl, body.title);
  }

  @Delete('videos/:id')
  @ApiOperation({ summary: 'Видалити кавер-відео' })
  deleteVideo(@Req() req, @Param('id', ParseIntPipe) id: number) {
    return this.profileService.deleteCoverVideo(this.getUserId(req), id);
  }
}
