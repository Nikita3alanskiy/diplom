import { Module } from '@nestjs/common';
import { PlayedService } from './played.service';
import { PlayedController } from './played.controller';
import { AuthModule } from '../auth/auth.module';
import { PrismaService } from '../prisma.service';

@Module({
  imports: [AuthModule],
  controllers: [PlayedController],
  providers: [PlayedService, PrismaService],
  exports: [PlayedService],
})
export class PlayedModule {}
