import { Module } from '@nestjs/common';
import { FriendsService } from './friends.service';
import { FriendsController } from './friends.controller';
import { ChatGateway } from './friends.gateway';
import { AuthModule } from '../auth/auth.module';
import { PrismaService } from '../prisma.service';

@Module({
  imports: [AuthModule],
  controllers: [FriendsController],
  providers: [FriendsService, ChatGateway, PrismaService],
  exports: [FriendsService],
})
export class FriendsModule {}
