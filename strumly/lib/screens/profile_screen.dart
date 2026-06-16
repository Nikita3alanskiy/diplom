import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_api_service.dart';
import '../services/played_api_service.dart';
import '../services/profile_api_service.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart';
import 'playlists_screen.dart';
import 'video_player_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String? _avatarUrl;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _playedSongs = [];
  bool _playedLoading = false;
  
  List<Map<String, dynamic>> _coverVideos = [];
  bool _videosLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    final authenticated = await AuthApiService.isAuthenticated();
    if (!authenticated) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        ).then((_) => _checkAuth());
      });
    } else {
      final name = await AuthApiService.getUserName();
      final email = await AuthApiService.getUserEmail();
      final avatar = await AuthApiService.getUserAvatarUrl();
      setState(() {
        _name = name ?? 'Користувач';
        _email = email ?? '';
        _avatarUrl = avatar;
        _isLoading = false;
      });
      _loadPlayedSongs();
      _loadCoverVideos();
    }
  }

  Future<void> _loadCoverVideos() async {
    setState(() => _videosLoading = true);
    try {
      final videos = await ProfileApiService.getCoverVideos();
      if (mounted) setState(() => _coverVideos = videos);
    } catch (_) {} finally {
      if (mounted) setState(() => _videosLoading = false);
    }
  }

  Future<void> _loadPlayedSongs() async {
    setState(() => _playedLoading = true);
    try {
      final songs = await PlayedApiService.getPlayedSongs();
      if (mounted) setState(() => _playedSongs = songs);
    } catch (_) {} finally {
      if (mounted) setState(() => _playedLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthApiService.logout();
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.greenAccent,
          backgroundColor: const Color(0xFF1A1A1A),
          onRefresh: _loadPlayedSongs,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Avatar ──
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.3),
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
                        ? const Icon(Icons.person, size: 50, color: Colors.greenAccent)
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
                          _playedSongs.length.toString(),
                          'зіграних',
                          Icons.music_note,
                          Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
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

                // ── Played Songs Section ──
                _buildSectionHeader('🎸 Зіграні пісні'),
                const SizedBox(height: 12),

                if (_playedLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  )
                else if (_playedSongs.isEmpty)
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
                          Icon(Icons.music_off, color: Colors.white24, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Ще жодної зіграної пісні',
                            style: TextStyle(color: Colors.white38, fontSize: 15),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Відкрий пісню і натисни ✓ Зіграв',
                            style: TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _playedSongs.length,
                      itemBuilder: (ctx, i) =>
                          _buildPlayedSongCard(_playedSongs[i]),
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Cover Videos Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        '🎥 Мої кавери',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.purpleAccent),
                        onPressed: _uploadVideo,
                        tooltip: 'Додати кавер',
                      ),
                    ],
                  ),
                ),
                
                if (_videosLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  )
                else if (_coverVideos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.videocam_off, color: Colors.white24, size: 48),
                          SizedBox(height: 12),
                          Text('Ще немає каверів', style: TextStyle(color: Colors.white38, fontSize: 15)),
                          SizedBox(height: 6),
                          Text('Завантаж своє перше відео!', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _coverVideos.length,
                    itemBuilder: (ctx, i) => _buildVideoCard(_coverVideos[i]),
                  ),

                const SizedBox(height: 28),

                // ── Menu ──
                _buildProfileMenu(
                  Icons.playlist_play,
                  'Мої плейлісти',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistsScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileMenu(
                  Icons.edit,
                  'Налаштування профілю',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditScreen(
                          initialName: _name,
                          initialAvatarUrl: _avatarUrl,
                        ),
                      ),
                    ).then((_) => _checkAuth());
                  },
                ),

                const SizedBox(height: 28),

                // ── Logout ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: ListTile(
                    onTap: _handleLogout,
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Вийти',
                        style: TextStyle(color: Colors.redAccent)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    tileColor: Colors.white.withOpacity(0.05),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_playedSongs.isNotEmpty)
            Text(
              '${_playedSongs.length} пісень',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayedSongCard(Map<String, dynamic> song) {
    final chords = (song['chords'] as String? ?? '')
        .split(RegExp(r'[\s,]+'))
        .where((c) => c.isNotEmpty)
        .take(3)
        .join(' • ');

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.greenAccent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            song['title'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song['artist'] ?? '',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (chords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                chords,
                style: const TextStyle(
                    color: Colors.greenAccent, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.greenAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: Colors.white.withOpacity(0.05),
      ),
    );
  }

  // ── Cover Videos Helpers ──
  String _fullAvatarUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'https://strumly-backend.onrender.com$path';
  }

  String _fullVideoUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'https://strumly-backend.onrender.com$path';
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              videoUrl: _fullVideoUrl(video['videoUrl'] ?? ''),
              title: video['title'] ?? 'Мій кавер',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.15)),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.3), size: 48),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Text(
                  video['title'] ?? 'Без назви',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned(
              top: 0, right: 0,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                onPressed: () => _deleteVideo(video['id']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final titleCtrl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Назва каверу', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Введіть назву',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(ctx, titleCtrl.text.trim()), child: const Text('Завантажити', style: TextStyle(color: Colors.purpleAccent))),
        ],
      ),
    );

    if (title != null) {
      setState(() => _videosLoading = true);
      try {
        await ProfileApiService.uploadCoverVideo(File(pickedFile.path), title: title);
        _loadCoverVideos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent));
          setState(() => _videosLoading = false);
        }
      }
    }
  }

  Future<void> _deleteVideo(int videoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Видалити кавер?', style: TextStyle(color: Colors.white)),
        content: const Text('Ця дія невідворотна.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Видалити', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _videosLoading = true);
      try {
        await ProfileApiService.deleteCoverVideo(videoId);
        _loadCoverVideos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent));
          setState(() => _videosLoading = false);
        }
      }
    }
  }
}