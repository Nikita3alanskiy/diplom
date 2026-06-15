import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_api_service.dart';
import '../services/auth_api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final String initialName;
  final String? initialAvatarUrl;

  const ProfileEditScreen({
    super.key,
    required this.initialName,
    this.initialAvatarUrl,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameCtrl;
  bool _saving = false;
  String? _avatarUrl;
  File? _localAvatar;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _avatarUrl = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _buildFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
    return '$base$path';
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;
    setState(() => _localAvatar = File(picked.path));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ім'я не може бути порожнім"), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Upload avatar first if picked
      if (_localAvatar != null) {
        final result = await ProfileApiService.uploadAvatar(_localAvatar!);
        _avatarUrl = result['avatarUrl'] as String?;
        await AuthApiService.saveUserData(
          name: name,
          avatarUrl: _avatarUrl,
        );
      }
      // Update name
      await ProfileApiService.updateName(name);
      await AuthApiService.saveUserData(name: name, avatarUrl: _avatarUrl);

      if (mounted) {
        Navigator.pop(context, true); // return true = refresh needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профіль оновлено!'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarFullUrl = _buildFullUrl(_avatarUrl);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Редагувати профіль', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Зберегти', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar picker
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 24, spreadRadius: 4),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: const Color(0xFF1E1E1E),
                      backgroundImage: _localAvatar != null
                          ? FileImage(_localAvatar!) as ImageProvider
                          : (avatarFullUrl.isNotEmpty ? NetworkImage(avatarFullUrl) : null),
                      child: (_localAvatar == null && avatarFullUrl.isEmpty)
                          ? const Icon(Icons.person, size: 64, color: Colors.greenAccent)
                          : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Натисни щоб змінити фото', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 32),
            // Name field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Ім'я / нікнейм",
                  labelStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.greenAccent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
