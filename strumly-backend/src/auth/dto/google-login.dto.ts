import { ApiProperty } from '@nestjs/swagger';

export class GoogleLoginDto {
  @ApiProperty({
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjE0...',
    description: 'ID токен Google, отриманий від клієнта (Flutter)',
  })
  idToken: string;
}
