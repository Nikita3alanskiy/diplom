import {
  Controller, Get, Put, Post, Delete,
  Req, Body, Param, ParseIntPipe,
  UseGuards, UseInterceptors, UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { ProfileService } from './profile.service';
import cloudinary from '../cloudinary.config';

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

  private uploadToCloudinary(buffer: Buffer, folder: string, resourceType: 'image' | 'video'): Promise<string> {
    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        { folder, resource_type: resourceType },
        (error, result) => {
          if (error || !result) return reject(error ?? new Error('Upload failed'));
          resolve(result.secure_url);
        },
      );
      stream.end(buffer);
    });
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
  @ApiOperation({ summary: 'Завантажити аватарку (зберігається в Cloudinary)' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', {
    storage: memoryStorage(),
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
    const avatarUrl = await this.uploadToCloudinary(file.buffer, 'strumly/avatars', 'image');
    return this.profileService.updateProfile(this.getUserId(req), undefined, avatarUrl);
  }

  @Get('videos')
  @ApiOperation({ summary: 'Отримати кавер-відео профілю' })
  getVideos(@Req() req) {
    return this.profileService.getCoverVideos(this.getUserId(req));
  }

  @Post('videos')
  @ApiOperation({ summary: 'Завантажити кавер-відео (зберігається в Cloudinary)' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file', {
    storage: memoryStorage(),
    fileFilter: (_, file, cb) => {
      if (!file.mimetype.match(/^video\//)) {
        return cb(new BadRequestException('Only video files allowed'), false);
      }
      cb(null, true);
    },
    limits: { fileSize: 200 * 1024 * 1024 },
  }))
  async uploadVideo(@Req() req, @UploadedFile() file: Express.Multer.File, @Body() body: { title?: string }) {
    if (!file) throw new BadRequestException('No file uploaded');
    const videoUrl = await this.uploadToCloudinary(file.buffer, 'strumly/covers', 'video');
    return this.profileService.addCoverVideo(this.getUserId(req), videoUrl, body.title);
  }

  @Delete('videos/:id')
  @ApiOperation({ summary: 'Видалити кавер-відео' })
  deleteVideo(@Req() req, @Param('id', ParseIntPipe) id: number) {
    return this.profileService.deleteCoverVideo(this.getUserId(req), id);
  }
}

