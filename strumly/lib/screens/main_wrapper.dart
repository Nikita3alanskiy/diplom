import 'package:flutter/material.dart';
import 'tuner_screen.dart';
import 'education_screen.dart';
import 'song_list_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import '../services/socket_service.dart';
import '../widgets/jam_invite_banner.dart';


class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TunerScreen(),
    const EducationScreen(),
    const SongListScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  OverlayEntry? _inviteOverlay;

  @override
  void initState() {
    super.initState();
    _connectAndListenForInvites();
  }

  Future<void> _connectAndListenForInvites() async {
    await SocketService.instance.connect();
    SocketService.instance.onSessionInviteReceived(_showInviteBanner);
  }

  void _showInviteBanner(Map<String, dynamic> data) {
    if (_inviteOverlay != null) return; // already showing one
    _inviteOverlay = OverlayEntry(
      builder: (context) => JamInviteBanner(
        inviteData: data,
        onDismiss: () {
          _inviteOverlay?.remove();
          _inviteOverlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_inviteOverlay!);
  }

  @override
  void dispose() {
    SocketService.instance.offSessionInviteReceived();
    _inviteOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Використовуй IndexedStack, щоб не перевантажувати сторінки щоразу
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF151515),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.tune), label: 'Тюнер'),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Навчання'),
          NavigationDestination(icon: Icon(Icons.music_note_outlined), label: 'Пісні'),
          NavigationDestination(icon: Icon(Icons.hub_outlined), label: 'Спільнота'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Акаунт'),
        ],
      ),
    );
  }
}