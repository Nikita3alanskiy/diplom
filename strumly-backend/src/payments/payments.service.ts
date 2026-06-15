import { Injectable } from '@nestjs/common';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const Stripe = require('stripe');

@Injectable()
export class PaymentsService {
  private stripe: any;

  constructor() {
    this.stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '');
  }

  async createCheckoutSession(userId: number, userEmail: string, returnUrl?: string) {
    const backendUrl =
      returnUrl || process.env.API_URL || 'http://localhost:3000/api';

    const session = await this.stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'payment',
      currency: 'uah',
      customer_email: userEmail,
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: 'uah',
            unit_amount: 9900, // 99.00 UAH у копійках
            product_data: {
              name: 'Strumly Premium — 30 днів',
              description: 'Повний доступ до всіх преміум функцій Strumly',
              images: [],
            },
          },
        },
      ],
      metadata: { userId: String(userId) },
      success_url: `${backendUrl}/payments/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${backendUrl}/payments/cancel`,
    });

    return { url: session.url, sessionId: session.id };
  }

  async handleWebhook(rawBody: Buffer, signature: string) {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
    let event: any;

    try {
      event = this.stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
    } catch {
      throw new Error('Invalid webhook signature');
    }

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      const userId = Number(session.metadata?.userId);
      return { userId, paid: true };
    }

    return null;
  }

  async verifySession(sessionId: string) {
    const session = await this.stripe.checkout.sessions.retrieve(sessionId);
    return {
      paid: session.payment_status === 'paid',
      userId: Number(session.metadata?.userId),
    };
  }
}
