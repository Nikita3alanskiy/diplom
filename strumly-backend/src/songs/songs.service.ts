import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateSongDto } from './dto/create-song.dto';
import axios from 'axios';
import * as cheerio from 'cheerio';

@Injectable()
export class SongsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateSongDto) {
    return this.prisma.song.create({
      data: {
        title: dto.title,
        artist: dto.artist ?? 'Unknown',
        chords: dto.chords,
        lyrics: dto.lyrics,
        audioUrl: dto.audioUrl ?? null,
        bpm: dto.bpm ? (typeof dto.bpm === 'string' ? parseInt(dto.bpm, 10) : dto.bpm) : null,
      },
    });
  }

  async findAll() {
    return this.prisma.song.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        title: true,
        artist: true,
        chords: true,
        createdAt: true,
        audioUrl: true,
        bpm: true,
      },
    });
  }

  async findOne(id: number) {
    const song = await this.prisma.song.findUnique({ where: { id } });
    if (!song) throw new NotFoundException(`Song with id ${id} not found`);
    return song;
  }

  async update(id: number, dto: Partial<CreateSongDto>) {
    await this.findOne(id); // throws if not found
    return this.prisma.song.update({ where: { id }, data: dto });
  }

  async remove(id: number) {
    await this.findOne(id);
    return this.prisma.song.delete({ where: { id } });
  }

  async parseFromUrl(url: string) {
    try {
      // Використовуємо заголовки реального браузера, щоб обійти простий захист від ботів
      const { data } = await axios.get(url, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'uk-UA,uk;q=0.9,en-US;q=0.8,en;q=0.7',
        },
      });

      const $ = cheerio.load(data);
      
      let fullTitle = $('title').text() || '';
      fullTitle = fullTitle.replace(/, аккорды.*/i, '').trim();
      
      let artist = 'Unknown';
      let title = 'Unknown';
      
      const parts = fullTitle.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts.slice(1).join(' - ').trim();
      } else {
        title = fullTitle;
      }

      // Специфічний пошук для mychords.net
      const h1Text = $('h1').first().text().trim();
      if (h1Text && h1Text.includes(' - ')) {
        const h1Parts = h1Text.split(' - ');
        artist = h1Parts[0].trim();
        title = h1Parts.slice(1).join(' - ').trim();
      }

      let lyrics = '';
      const chordsNode = $('.w-words__text');
      if (chordsNode.length) {
        // Замінюємо <br> на \n, щоб зберегти правильне форматування
        chordsNode.find('br').replaceWith('\n');
        lyrics = chordsNode.text();
      } else {
        // Універсальний пошук: найдовший блок <pre>
        let longestPre = '';
        $('pre').each((_, el) => {
          $(el).find('br').replaceWith('\n');
          const text = $(el).text();
          if (text.length > longestPre.length) {
            longestPre = text;
          }
        });
        lyrics = longestPre;
      }
      
      // Очищуємо зайві переноси на початку і в кінці
      lyrics = lyrics.replace(/^\s*\n|\n\s*$/g, '');

      if (!lyrics) {
        throw new Error('Не вдалося знайти текст з акордами на сторінці (блок <pre> порожній)');
      }

      // Витягування унікальних акордів
      const chordRegex = /\b[A-H](?:#|b)?(?:m|maj|dim|aug|sus)?\d*(?:\/[A-H](?:#|b)?)?\b/g;
      const foundChords = lyrics.match(chordRegex) || [];
      const uniqueChords = [...new Set(foundChords)].join(', ');

      // Витягування YouTube відео
      let youtubeUrl: string | null = null;
      const iframeSrc = $('iframe[src*="youtube.com/embed/"]').attr('src');
      if (iframeSrc) {
        const match = iframeSrc.match(/embed\/([^?]+)/);
        if (match && match[1]) {
          youtubeUrl = `https://www.youtube.com/watch?v=${match[1]}`;
        }
      }

      // Fallback на пошук YouTube, якщо відео немає на сторінці
      if (!youtubeUrl) {
        try {
          const ytSearch = require('yt-search');
          const searchResult = await ytSearch(`${artist} ${title} audio`);
          if (searchResult && searchResult.videos.length > 0) {
            youtubeUrl = searchResult.videos[0].url;
          }
        } catch (ytError) {
          console.log('Помилка пошуку в YouTube:', ytError.message);
        }
      }

      // Перевірка дублікатів в БД (нечутливо до регістру)
      const existing = await this.prisma.song.findFirst({
        where: {
          title: { equals: title, mode: 'insensitive' },
          artist: { equals: artist, mode: 'insensitive' },
        },
      });

      if (existing) {
        // Якщо пісня існує, але без youtubeUrl, а ми його знайшли - оновимо
        if (!existing.youtubeUrl && youtubeUrl) {
           await this.prisma.song.update({
             where: { id: existing.id },
             data: { youtubeUrl }
           });
           existing.youtubeUrl = youtubeUrl;
        }
        return existing;
      }

      return await this.prisma.song.create({
        data: {
          title,
          artist,
          lyrics,
          chords: uniqueChords,
          youtubeUrl,
        },
      });

    } catch (error) {
      throw new Error(`Помилка парсингу: ${error.message}`);
    }
  }
}
