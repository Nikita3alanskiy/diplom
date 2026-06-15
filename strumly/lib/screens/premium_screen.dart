import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/payment_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  void _checkPremium() async {
    bool isPremium = await AuthApiService.isPremium();
    if (mounted) setState(() => _isPremium = isPremium);
  }

  void _buyPremium() async {
    setState(() => _isLoading = true);
    try {
      // 1. Відкриваємо Stripe Checkout у WebView
      await PaymentService.createCheckoutSession();
      // Після повернення з браузера, перевіряємо статус (або можна додати кнопку "Я оплатив")
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Перевіряємо статус оплати...')),
      );
      // Затримка, щоб вебхук встиг обробитись (краще б додати long-polling, але для демо піде)
      await Future.delayed(const Duration(seconds: 3));
      _checkPremium();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка активації: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Strumly Premium'),
        backgroundColor: const Color(0xFF151515),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 80, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              const Text(
                'Отримайте більше можливостей',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeatureRow('Автоскрол у Jam Session (для хоста)'),
              _buildFeatureRow('Нестандартні строї в тюнері (Drop D, Half Step Down)'),
              _buildFeatureRow('Можливість додавати власні пісні'),
              const SizedBox(height: 48),
              if (_isPremium)
                const Text(
                  'У вас вже активовано Premium!',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                )
              else
                ElevatedButton(
                  onPressed: _isLoading ? null : _buyPremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Купити за 99 ₴ / міс', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16))),
        ],
      ),
    );
  }
}
