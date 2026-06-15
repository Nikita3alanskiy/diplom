import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/auth_wrapper_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const StrumlyApp());
}

class StrumlyApp extends StatelessWidget {
  const StrumlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Strumly Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorSchemeSeed: Colors.greenAccent,
        useMaterial3: true,
      ),
      home: const AuthWrapperScreen(),
    );
  }
}