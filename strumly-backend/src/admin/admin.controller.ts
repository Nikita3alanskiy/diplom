import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  ParseIntPipe,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBody } from '@nestjs/swagger';
import { AdminService } from './admin.service';

@ApiTags('Admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ── Stats ──────────────────────────────────────────────────────────

  @Get('stats')
  @ApiOperation({ summary: 'Get dashboard stats' })
  getStats() {
    return this.adminService.getStats();
  }

  // ── Users ──────────────────────────────────────────────────────────

  @Get('users')
  @ApiOperation({ summary: 'Get all users' })
  getUsers() {
    return this.adminService.getUsers();
  }

  @Put('users/:id/premium')
  @ApiOperation({ summary: 'Toggle premium status for user' })
  @ApiBody({ schema: { example: { isPremium: true } } })
  togglePremium(
    @Param('id', ParseIntPipe) id: number,
    @Body('isPremium') isPremium: boolean,
  ) {
    return this.adminService.togglePremium(id, isPremium);
  }

  @Delete('users/:id')
  @ApiOperation({ summary: 'Delete user' })
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteUser(@Param('id', ParseIntPipe) id: number) {
    return this.adminService.deleteUser(id);
  }

  // ── Songs ──────────────────────────────────────────────────────────

  @Get('songs')
  @ApiOperation({ summary: 'Get all songs' })
  getSongs() {
    return this.adminService.getSongs();
  }

  @Post('songs')
  @ApiOperation({ summary: 'Create a song' })
  createSong(@Body() body: {
    title: string;
    artist?: string;
    lyrics: string;
    chords: string;
    audioUrl?: string;
    youtubeUrl?: string;
    bpm?: number;
  }) {
    return this.adminService.createSong(body);
  }

  @Put('songs/:id')
  @ApiOperation({ summary: 'Update a song' })
  updateSong(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: {
      title?: string;
      artist?: string;
      lyrics?: string;
      chords?: string;
      audioUrl?: string;
      youtubeUrl?: string;
      bpm?: number;
    },
  ) {
    return this.adminService.updateSong(id, body);
  }

  @Delete('songs/:id')
  @ApiOperation({ summary: 'Delete a song' })
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteSong(@Param('id', ParseIntPipe) id: number) {
    return this.adminService.deleteSong(id);
  }

  // ── Chords ─────────────────────────────────────────────────────────

  @Get('chords')
  @ApiOperation({ summary: 'Get all chords' })
  getChords() {
    return this.adminService.getChords();
  }

  @Post('chords')
  @ApiOperation({ summary: 'Create a chord' })
  createChord(@Body() body: {
    name: string;
    fingering: string;
    category?: string;
    difficulty?: string;
    description?: string;
  }) {
    return this.adminService.createChord(body);
  }

  @Put('chords/:id')
  @ApiOperation({ summary: 'Update a chord' })
  updateChord(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: {
      name?: string;
      fingering?: string;
      category?: string;
      difficulty?: string;
      description?: string;
    },
  ) {
    return this.adminService.updateChord(id, body);
  }

  @Delete('chords/:id')
  @ApiOperation({ summary: 'Delete a chord' })
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteChord(@Param('id', ParseIntPipe) id: number) {
    return this.adminService.deleteChord(id);
  }
}
