import { Injectable } from '@nestjs/common';
import { SongsService } from '../songs/songs.service';
import axios from 'axios';
import * as cheerio from 'cheerio';

@Injectable()
export class CatalogService {
  constructor(private readonly songsService: SongsService) {}

  async search(query: string) {
    try {
      const url = `https://amdm.ru/search/?q=${encodeURIComponent(query)}`;
      const { data } = await axios.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        },
      });
      const $ = cheerio.load(data);
      const results: { title: string; url: string }[] = [];
      
      $('table.items tr').each((_, el) => {
        const link = $(el).find('a.artist').attr('href');
        let title = $(el).find('a.artist').text().trim();
        
        // На amdm текст може бути злитий "АртистНазва", але зазвичай це просто Назва
        // або там два теги <a>: один на артиста, інший на пісню
        const links = $(el).find('a.artist');
        if (links.length >= 2) {
          const artist = $(links[0]).text().trim();
          const songTitle = $(links[1]).text().trim();
          const songUrl = $(links[1]).attr('href');
          
          if (songUrl && songTitle) {
            results.push({
              title: `${artist} - ${songTitle}`,
              url: songUrl.startsWith('http') ? songUrl : `https:${songUrl}`,
            });
          }
        }
      });
      
      return results;
    } catch (e) {
      throw new Error(`Помилка пошуку в каталозі: ${e.message}`);
    }
  }

  async importSong(url: string) {
    return this.songsService.parseFromUrl(url);
  }
}
