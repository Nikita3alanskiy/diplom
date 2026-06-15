import { Controller, Post, Body, Get, Req, HttpStatus, UnauthorizedException, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleLoginDto } from './dto/google-login.dto';

@ApiTags('Авторизація') // Групує методи в інтерфейсі
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}



  @Get('health')
  health() {
    return { status: HttpStatus.OK, message: 'Strumly API is up' };
  }

  @Post('register')
  @ApiOperation({
    summary: 'Реєстрація користувача',
    description: 'Створює нового юзера в Postgres і повертає JWT токен',
  })
  @ApiResponse({ status: 201, description: 'Успішно зареєстровано' })
  @ApiResponse({ status: 400, description: 'Email вже зайнятий' })
  async register(@Body() body: RegisterDto) {
    return this.authService.register(body);
  }

  @Post('login')
  @ApiOperation({
    summary: 'Вхід у систему (email + пароль)',
    description: 'Перевіряє email та пароль, повертає JWT токен',
  })
  @ApiResponse({ status: 200, description: 'Успішний вхід' })
  @ApiResponse({ status: 401, description: 'Невірні облікові дані' })
  @ApiResponse({ status: 400, description: 'Некоректний запит або акаунт Google' })
  async login(@Body() body: LoginDto) {
    return this.authService.login(body);
  }

  @Get('me')
  async me(@Req() req) {
    const userId = req?.user?.sub;
    if (!userId) {
      throw new UnauthorizedException('User not authenticated');
    }
    return this.authService.getProfile(userId);
  }
  @ApiOperation({
    summary: 'Вхід / реєстрація через Google',
    description: 'Приймає ID токен від Google, перевіряє його та повертає JWT токен. Якщо користувача немає — реєструє.',
  })
  @ApiResponse({ status: 200, description: 'Успішний вхід / реєстрація' })
  @ApiResponse({ status: 401, description: 'Недійсний Google токен' })
  async googleLogin(@Body() body: GoogleLoginDto) {
    return this.authService.googleLogin(body);
  }

  @Post('premium')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Купити преміум підписку',
    description: 'Mock-ендпоінт для активації преміум статусу користувача на 30 днів',
  })
  @ApiResponse({ status: 200, description: 'Успішна покупка преміуму' })
  async buyPremium(@Req() req) {
    const userId = req.user.sub;
    return this.authService.buyPremium(userId);
  }
}
