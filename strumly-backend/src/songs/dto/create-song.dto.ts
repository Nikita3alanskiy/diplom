import { IsString, IsOptional, IsNumber } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateSongDto {
  @ApiProperty({ description: 'Назва пісні' })
  @IsString()
  title: string;

  @ApiPropertyOptional({ description: 'Виконавець' })
  @IsOptional()
  @IsString()
  artist?: string;

  @ApiProperty({ description: 'Акорди пісні (текст, наприклад "Am C G D")' })
  @IsString()
  chords: string;

  @ApiProperty({ description: 'Текст пісні (слова)' })
  @IsString()
  lyrics: string;

  @ApiPropertyOptional({ description: 'URL до аудіофайлу (опціонально)' })
  @IsOptional()
  @IsString()
  audioUrl?: string;

  @ApiPropertyOptional({ description: 'BPM (опціонально)' })
  @IsOptional()
  @IsNumber()
  bpm?: number;

  @ApiPropertyOptional({ description: 'ID користувача, який додав пісню' })
  @IsOptional()
  @IsNumber()
  userId?: number;
}
