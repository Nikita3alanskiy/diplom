import 'dart:io';
import 'package:flutter/material.dart';
import '../services/profile_api_service.dart';
import 'video_player_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final int userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  String _name = '';
  String _email = '';
  String? _avatarUrl;
  bool _isLoading = true;
  String _error = '';

  List<Map<String, dynamic>> _coverVideos = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await ProfileApiService.getUserProfile(widget.userId);
      setState(() {
        _name = data['name'] ?? 'Користувач';
        _email = data['email'] ?? '';
        _avatarUrl = data['avatarUrl'];
        _coverVideos = List<Map<String, dynamic>>.from(data['coverVideos'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Не вдалося завантажити профіль';
          _isLoading = false;
        });
      }
    }
  }

  String _fullAvatarUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'https://strumly-backend.onrender.com$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(_error, style: const TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // ── Avatar ──
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF1E1E1E),
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty 
                    ? NetworkImage(_fullAvatarUrl(_avatarUrl!)) 
                    : null,
                child: _avatarUrl == null || _avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.blueAccent)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _email,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // ── Stats row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      _coverVideos.length.toString(),
                      'каверів',
                      Icons.video_camera_back,
                      Colors.purpleAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // ── Cover Videos Section ──
            _buildSectionHeader('🎥 Кавери користувача'),
            const SizedBox(height: 12),
            if (_coverVideos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.videocam_off, color: Colors.white24, size: 48),
                      SizedBox(height: 16),
                      Text('Користувач ще не додав жодного відео',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _coverVideos.length,
                  itemBuilder: (ctx, i) {
                    final video = _coverVideos[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            videoUrl: video['videoUrl'] as String,
                            title: video['title'] as String? ?? 'Кавер',
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.play_circle_fill,
                                color: Colors.white38, size: 48),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(16)),
                                ),
                                child: Text(
                                  video['title'] as String? ?? 'Кавер',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String val, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
