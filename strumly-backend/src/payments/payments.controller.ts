import {
  Controller,
  Post,
  Body,
  Headers,
  Req,
  Res,
  Get,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import type { Response } from 'express';
import type { RawBodyRequest } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('create-checkout-session')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create Stripe Checkout session (UAH)' })
  async createSession(@Body() body: { returnUrl?: string }, @Request() req: any) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: req.user.sub || req.user.id },
      select: { id: true, email: true },
    });
    return this.paymentsService.createCheckoutSession(user.id, user.email, body.returnUrl);
  }

  @Post('webhook')
  @ApiOperation({ summary: 'Stripe webhook (called by Stripe)' })
  async webhook(
    @Req() req: RawBodyRequest<any>,
    @Headers('stripe-signature') sig: string,
  ) {
    const result = await this.paymentsService.handleWebhook(req.rawBody, sig);
    if (result?.paid && result.userId) {
      await this.prisma.user.update({
        where: { id: result.userId },
        data: {
          isPremium: true,
          premiumUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });
    }
    return { received: true };
  }

  @Get('verify-session')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify payment after redirect from Stripe' })
  async verifySession(
    @Query('session_id') sessionId: string,
    @Request() req: any,
  ) {
    const result = await this.paymentsService.verifySession(sessionId);
    if (result.paid && result.userId === req.user.id) {
      await this.prisma.user.update({
        where: { id: req.user.id },
        data: {
          isPremium: true,
          premiumUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        },
      });
      return { success: true };
    }
    return { success: false };
  }

  @Get('success')
  @ApiOperation({ summary: 'Show success page in WebView' })
  successPage(@Res() res: Response) {
    res.send(`
      <html>
        <body style="background:#151515; color:#fff; display:flex; flex-direction:column; align-items:center; justify-content:center; height:100vh; font-family:sans-serif;">
          <h1 style="color:#4ade80;">Оплата успішна! 🎉</h1>
          <p>Ваша підписка Strumly Premium активована.</p>
          <p style="color:#aaa;">Ви можете закрити це вікно та повернутися в додаток.</p>
        </body>
      </html>
    `);
  }

  @Get('cancel')
  @ApiOperation({ summary: 'Show cancel page in WebView' })
  cancelPage(@Res() res: Response) {
    res.send(`
      <html>
        <body style="background:#151515; color:#fff; display:flex; flex-direction:column; align-items:center; justify-content:center; height:100vh; font-family:sans-serif;">
          <h1 style="color:#f87171;">Оплату скасовано ❌</h1>
          <p>Ви можете закрити це вікно та спробувати ще раз.</p>
        </body>
      </html>
    `);
  }
}
