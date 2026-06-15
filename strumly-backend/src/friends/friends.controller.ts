import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  Req,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { FriendsService } from './friends.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { IsString } from 'class-validator';

class SendRequestDto {
  @IsString()
  email: string;
}

@ApiTags('Друзі')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('friends')
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @Get('search')
  @ApiOperation({ summary: 'Пошук користувачів за email або ім\'ям' })
  @ApiQuery({ name: 'q', description: 'Пошуковий запит' })
  searchUsers(@Query('q') query: string, @Req() req) {
    if (!query || query.trim().length < 2) return [];
    return this.friendsService.searchUser(query.trim(), Number(req.user.sub || req.user.id));
  }

  @Get()
  @ApiOperation({ summary: 'Список друзів' })
  getFriends(@Req() req) {
    return this.friendsService.getFriends(Number(req.user.sub || req.user.id));
  }

  @Get('requests')
  @ApiOperation({ summary: 'Вхідні запити в друзі' })
  getRequests(@Req() req) {
    return this.friendsService.getIncomingRequests(Number(req.user.sub || req.user.id));
  }

  @Post('request')
  @ApiOperation({ summary: 'Надіслати запит у друзі за email' })
  sendRequest(@Req() req, @Body() body: SendRequestDto) {
    return this.friendsService.sendRequest(Number(req.user.sub || req.user.id), body.email);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: 'Прийняти запит у друзі' })
  acceptRequest(@Param('id', ParseIntPipe) id: number, @Req() req) {
    return this.friendsService.acceptRequest(id, Number(req.user.sub || req.user.id));
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Відхилити запит або видалити друга' })
  reject(@Param('id', ParseIntPipe) id: number, @Req() req) {
    return this.friendsService.rejectOrRemove(id, Number(req.user.sub || req.user.id));
  }

  @Get(':friendshipId/messages')
  @ApiOperation({ summary: 'Отримати повідомлення чату' })
  getMessages(
    @Param('friendshipId', ParseIntPipe) friendshipId: number,
    @Req() req,
  ) {
    return this.friendsService.getMessages(friendshipId, Number(req.user.sub || req.user.id));
  }
}
