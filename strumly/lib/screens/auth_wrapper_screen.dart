import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import 'login_screen.dart';
import 'main_wrapper.dart';

class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({super.key});

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = await AuthApiService.isAuthenticated();
    setState(() => _isAuthenticated = auth);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      // loading
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isAuthenticated! ? const MainWrapper() : const LoginScreen();
  }
}
