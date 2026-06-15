import 'package:flutter/material.dart';
import '../services/jam_session_service.dart';
import '../screens/jam_session_screen.dart';

class JamInviteBanner extends StatefulWidget {
  final Map<String, dynamic> inviteData;
  final VoidCallback onDismiss;

  const JamInviteBanner({
    super.key,
    required this.inviteData,
    required this.onDismiss,
  });

  @override
  State<JamInviteBanner> createState() => _JamInviteBannerState();
}

class _JamInviteBannerState extends State<JamInviteBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();

    // Auto-dismiss after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_dismissed) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    setState(() => _dismissed = true);
    _animCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _accept() {
    final code = widget.inviteData['sessionCode'] as String?;
    if (code == null) return;

    _dismiss();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JamSessionScreen(
          sessionCode: code,
          isHost: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hostName = widget.inviteData['hostName'] as String? ?? 'Друг';
    final songTitle = widget.inviteData['songTitle'] as String? ?? 'Пісня';
    final playlistTitle = widget.inviteData['playlistTitle'] as String?;

    return SafeArea(
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.music_note, color: Colors.greenAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$hostName запрошує в Jam Session!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playlistTitle != null ? 'Плейліст: $playlistTitle\nЗараз: $songTitle' : songTitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _accept,
                    child: const Text('Вхід', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _dismiss,
                    child: const Text('Сховати', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
