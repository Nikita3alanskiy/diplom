import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkTheme = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Налаштування', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('Вигляд'),
          SwitchListTile(
            title: const Text('Темна тема', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Використовувати темні кольори', style: TextStyle(color: Colors.white38)),
            value: _darkTheme,
            activeColor: Colors.greenAccent,
            onChanged: (val) => setState(() => _darkTheme = val),
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Сповіщення'),
          SwitchListTile(
            title: const Text('Увімкнути сповіщення', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Отримувати повідомлення', style: TextStyle(color: Colors.white38)),
            value: _notifications,
            activeColor: Colors.greenAccent,
            onChanged: (val) => setState(() => _notifications = val),
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Про додаток'),
          ListTile(
            title: const Text('Версія', style: TextStyle(color: Colors.white)),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.white38)),
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
