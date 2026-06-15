import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import type { User } from '@prisma/client';
import { PrismaService } from '../prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { OAuth2Client } from 'google-auth-library';

@Injectable()
export class AuthService {
  private googleClient = new OAuth2Client();

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  /**
   * Реєстрація нового користувача
   */
  async register(data: RegisterDto) {
    // 1. Перевіряємо, чи такий емейл вже існує в системі
    const userExists = await this.prisma.user.findUnique({
      where: { email: data.email },
    });

    if (userExists) {
      throw new BadRequestException('Користувач з таким Email вже існує');
    }

    // 2. Хешуємо пароль перед збереженням у базу
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(data.password, saltRounds);

    // 3. Створюємо запис у PostgreSQL через Prisma
    const user = await this.prisma.user.create({
      data: {
        email: data.email,
        name: data.name,
        password: hashedPassword,
        isPremium: false, // Значення за замовчуванням
      },
    });

    // Повертаємо токен, щоб користувач відразу був залогінений після реєстрації
    return this.generateToken(user);
  }

  /**
   * Авторизація існуючого користувача
   */
  async login(data: LoginDto) {
    if (!data || !data.email || !data.password) {
      throw new BadRequestException('Email та пароль є обов’язковими');
    }

    // 1. Шукаємо користувача за Email
    const user = await this.prisma.user.findUnique({
      where: { email: data.email },
    });

    if (!user) {
      throw new UnauthorizedException('Невірний Email або пароль');
    }

    // Якщо користувач зареєструвався через Google і не має пароля
    if (!user.password) {
      throw new BadRequestException(
        'Цей акаунт зареєстрований через Google. Увійдіть за допомогою Google.',
      );
    }

    // 2. Порівнюємо введений пароль із хешем у базі
    const isPasswordValid = await bcrypt.compare(data.password, user.password);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Невірний Email або пароль');
    }

    // 3. Якщо все ок — генеримо JWT
    return this.generateToken(user);
  }

  /**
   * Авторизація / реєстрація через Google
   */
  async googleLogin(data: GoogleLoginDto) {
    if (!data || !data.idToken) {
      throw new BadRequestException('ID токен є обов’язковим');
    }

    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (!clientId) {
      console.warn('⚠️ GOOGLE_CLIENT_ID is not set in environment variables. Token audience verification is skipped.');
    }

    let payload: { sub?: string; email?: string; name?: string } | undefined;
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken: data.idToken,
        audience: clientId || undefined,
      });
      payload = ticket.getPayload();
    } catch (e) {
      throw new UnauthorizedException('Недійсний Google токен: ' + (e as Error).message);
    }

    // Перевіряємо, що payload має необхідні поля
    if (!payload?.sub || !payload?.email) {
      throw new BadRequestException('Недійсні дані Google токена');
    }
    const googleId = payload.sub!;
    const email = payload.email!;
    const name = payload.name;

    // 1. Спочатку шукаємо за googleId
    let user = await this.prisma.user.findUnique({
      where: { googleId: googleId },
    });

    if (!user) {
      // 2. Якщо за googleId не знайшли, шукаємо за email
      user = await this.prisma.user.findUnique({
        where: { email },
      });

      if (user) {
        // Якщо знайшли за email, але googleId ще не прив'язаний
        user = await this.prisma.user.update({
          where: { email: email },
          data: { googleId: googleId },
        });
      } else {
        // 3. Якщо користувача взагалі немає — створюємо нового
        user = await this.prisma.user.create({
          data: {
            email: email,
            name: name || 'Google User',
            googleId: googleId,
            password: null as any,
            isPremium: false,
          },
        });
      }
    }

    return this.generateToken(user);
  }

  /**
   * Допоміжний метод для створення JWT токена та об'єкта користувача
   */
  private generateToken(user: User) {
    const payload = { sub: user.id, email: user.email };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        isPremium: user.isPremium,
        avatarUrl: (user as any).avatarUrl ?? null,
      },
    };
  }

  /**
   * Отримати профіль користувача за його ID
   */
  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: parseInt(userId, 10) },
      select: {
        id: true,
        email: true,
        name: true,
        isPremium: true,
        googleId: true,
        avatarUrl: true,
      },
    });
    if (!user) {
      throw new UnauthorizedException('User not found');
    }
    return user;
  }

  async updateProfile(userId: number, name?: string, avatarUrl?: string) {
    const data: any = {};
    if (name !== undefined) data.name = name;
    if (avatarUrl !== undefined) data.avatarUrl = avatarUrl;
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, name: true, email: true, avatarUrl: true, isPremium: true },
    });
  }

  async buyPremium(userId: number) {
    const nextMonth = new Date();
    nextMonth.setMonth(nextMonth.getMonth() + 1);
    
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        isPremium: true,
        premiumUntil: nextMonth,
      },
      select: { id: true, isPremium: true, premiumUntil: true },
    });
  }
}
