import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { SongsModule } from './songs/songs.module';
import { PlayedModule } from './played/played.module';
import { FriendsModule } from './friends/friends.module';

import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { CatalogModule } from './catalog/catalog.module';
import { ProfileModule } from './profile/profile.module';
import { FavoritesModule } from './favorites/favorites.module';
import { PlaylistsModule } from './playlists/playlists.module';
import { JamSessionModule } from './jam-session/jam-session.module';

@Module({
  imports: [
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
    }),
    AuthModule,
    SongsModule,
    PlayedModule,
    FriendsModule,
    CatalogModule,
    ProfileModule,
    FavoritesModule,
    PlaylistsModule,
    JamSessionModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
