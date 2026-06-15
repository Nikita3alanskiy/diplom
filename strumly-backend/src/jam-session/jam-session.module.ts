import { Module } from '@nestjs/common';
import { JamSessionGateway } from './jam-session.gateway';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  providers: [JamSessionGateway],
})
export class JamSessionModule {}
