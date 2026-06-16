import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/song.dart';
import '../models/chord_dictionary.dart';
import '../widgets/chord_diagram.dart';
import '../widgets/chord_lyrics_display.dart';
import '../utils/chord_parser.dart';
import '../widgets/audio_player_widget.dart';
import '../services/played_api_service.dart';
import '../services/favorites_api_service.dart';
import '../services/playlists_api_service.dart';
import '../services/auth_api_service.dart';
import '../services/friends_api_service.dart';
import '../services/jam_session_service.dart';
import '../services/socket_service.dart';
import 'jam_session_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;
  // Playlist mode: list of songs + current index
  final List<Map<String, dynamic>>? playlist;
  final int playlistIndex;

  const SongDetailScreen({
    super.key,
    required this.song,
    this.playlist,
    this.playlistIndex = 0,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen>
    with TickerProviderStateMixin {
  // ── scroll ──
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  double _scrollSpeed = 40.0; // px per beat (when BPM) or px/s (manual)

  // ── metronome ──
  final AudioPlayer _tickPlayer = AudioPlayer();
  Timer? _scrollTimer;

  // ── count-in state ──
  bool _isCounting = false;
  int _countValue = 0;       // current countdown display (4,3,2,1 or 8..1)
  int _countBeats = 4;       // 4 or 8
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;

  // ── transpose ──
  int _transposeOffset = 0;

  // ── played ──
  bool _isPlayed = false;
  bool _playedLoading = false;

  // ── favorite ──
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  // ── YouTube player ──
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _tickPlayer.setSource(AssetSource('audio/tick.wav')).then((_) {
      _tickPlayer.setReleaseMode(ReleaseMode.stop);
    }).catchError((_) {});
    _loadPlayedStatus();
    _loadFavoriteStatus();
    _initYouTube();
  }

  void _initYouTube() {
    final ytUrl = widget.song.youtubeUrl;
    if (ytUrl == null || ytUrl.isEmpty) return;
    final videoId = YoutubePlayer.convertUrlToId(ytUrl);
    if (videoId == null) return;
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  Future<void> _loadPlayedStatus() async {
    final auth = await AuthApiService.isAuthenticated();
    if (!auth) return;
    try {
      final played = await PlayedApiService.isPlayed(widget.song.id);
      if (mounted) setState(() => _isPlayed = played);
    } catch (_) {}
  }

  Future<void> _loadFavoriteStatus() async {
    final auth = await AuthApiService.isAuthenticated();
    if (!auth) return;
    try {
      final fav = await FavoritesApiService.isFavorite(widget.song.id);
      if (mounted) setState(() => _isFavorite = fav);
    } catch (_) {}
  }

  Future<void> _togglePlayed() async {
    if (_playedLoading) return;
    setState(() => _playedLoading = true);
    try {
      if (_isPlayed) {
        await PlayedApiService.unmarkAsPlayed(widget.song.id);
        if (mounted) setState(() => _isPlayed = false);
      } else {
        await PlayedApiService.markAsPlayed(widget.song.id);
        if (mounted) setState(() => _isPlayed = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text('"${widget.song.title}" додано до зіграних!'),
                ],
              ),
              backgroundColor: Colors.greenAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _playedLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;
    setState(() => _favoriteLoading = true);
    try {
      if (_isFavorite) {
        await FavoritesApiService.removeFavorite(widget.song.id);
        if (mounted) setState(() => _isFavorite = false);
      } else {
        await FavoritesApiService.addFavorite(widget.song.id);
        if (mounted) setState(() => _isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Додано до обраних ❤️'),
              backgroundColor: Colors.pinkAccent,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _showAddToPlaylistDialog() async {
    final auth = await AuthApiService.isAuthenticated();
    if (!auth) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Увійдіть, щоб використовувати плейлісти'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    List<Map<String, dynamic>> playlists = [];
    try {
      playlists = await PlaylistsApiService.getPlaylists();
    } catch (_) {}

    if (!mounted) return;

    if (playlists.isEmpty) {
      // Ask to create
      final nameCtrl = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Немає плейлістів', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Назва нового плейліста',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати', style: TextStyle(color: Colors.white38))),
            TextButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()), child: const Text('Створити', style: TextStyle(color: Colors.greenAccent))),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        final newPl = await PlaylistsApiService.createPlaylist(name);
        await PlaylistsApiService.addSong(newPl['id'], widget.song.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Додано до «$name»'), backgroundColor: Colors.greenAccent),
        );
      }
      return;
    }

    // Show list
    if (!mounted) return;
    final chosen = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Додати до плейліста', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...playlists.map((pl) => ListTile(
              leading: const Icon(Icons.queue_music, color: Colors.greenAccent),
              title: Text(pl['title'] ?? '', style: const TextStyle(color: Colors.white)),
              subtitle: Text('${(pl['songs'] as List?)?.length ?? 0} пісень', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, pl),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) {
      try {
        await PlaylistsApiService.addSong(chosen['id'], widget.song.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Додано до «${chosen['title']}»'), backgroundColor: Colors.greenAccent, behavior: SnackBarBehavior.floating),
        );
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _showJamBottomSheet() async {
    final auth = await AuthApiService.isAuthenticated();
    if (!auth) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Увійдіть, щоб створити Jam Session')));
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        List<Map<String, dynamic>>? loadedFriends;
        final Set<int> invitedIds = {};

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (loadedFriends == null) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: FriendsApiService.getFriends(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.greenAccent)));
                  }
                  loadedFriends = snapshot.data ?? [];
                  return _buildJamModalContent(ctx, setModalState, loadedFriends!, invitedIds);
                },
              );
            }
            return _buildJamModalContent(ctx, setModalState, loadedFriends!, invitedIds);
          },
        );
      },
    );
  }

  Widget _buildJamModalContent(
    BuildContext ctx,
    StateSetter setModalState,
    List<Map<String, dynamic>> friends,
    Set<int> invitedIds,
  ) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Jam Session', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Оберіть друзів для запрошення', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            if (friends.isEmpty)
              const Text('У вас ще немає друзів', style: TextStyle(color: Colors.white38))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index]['friend'] as Map<String, dynamic>? ?? {};
                    final friendshipIdRaw = friends[index]['friendshipId'];
                    final fid = friendshipIdRaw is int
                        ? friendshipIdRaw
                        : int.tryParse(friendshipIdRaw?.toString() ?? '');
                    final isInvited = fid != null && invitedIds.contains(fid);
                    final avatarUrl = friend['avatarUrl'] as String?;
                    final name = friend['name'] as String? ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.greenAccent.withOpacity(0.2),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, color: Colors.greenAccent)
                            : null,
                      ),
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      trailing: isInvited
                        ? const Chip(
                            label: Text('Запрошено', style: TextStyle(color: Colors.black, fontSize: 12)),
                            backgroundColor: Colors.grey,
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: fid == null ? null : () async {
                              final friendUserId = friend['id'] as int?;
                              setModalState(() => invitedIds.add(fid));
                              await _sendInvite(fid, friendUserId: friendUserId);
                              // Оновлюємо модалку після того, як сесія може стати активною
                              await Future.delayed(const Duration(milliseconds: 800));
                              if (ctx.mounted) setModalState(() {});
                            },
                            child: const Text('Запросити'),
                          ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (_activeSessionCode != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JamSessionScreen(sessionCode: _activeSessionCode!, isHost: true),
                    ),
                  );
                },
                child: const Text('УВІЙТИ В JAM SESSION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _createWithoutInvite(ctx),
                child: const Text('Створити без запрошень (тільки за кодом)'),
              ),
          ],
        ),
      ),
    );
  }

  String? _activeSessionCode;

  Future<void> _sendInvite(int friendshipId, {int? friendUserId}) async {
    try {
      await SocketService.instance.connect();
      await JamSessionService.instance.connect();

      // Приєднуємось до кімнати чату щоб надіслати повідомлення
      SocketService.instance.joinRoom(friendshipId);

      if (_activeSessionCode == null) {
        // Знімаємо старий listener перед тим, як додати новий
        JamSessionService.instance.offAll();
        JamSessionService.instance.onSessionCreated((sessionCode) {
          if (mounted) {
            setState(() { _activeSessionCode = sessionCode; });
          }
          // Невелика затримка, щоб socket встиг обробити room join
          Future.delayed(const Duration(milliseconds: 300), () {
            // Надсилаємо в чат (з'явиться як повідомлення з кнопкою «Приєднатись»)
            SocketService.instance.sendMessage(
              friendshipId,
              '[JAM_INVITE]$sessionCode',
            );
            // Якщо маємо userId друга — надсилаємо і direct-invite (popup)
            if (friendUserId != null) {
              SocketService.instance.sendSessionInvite(
                friendUserId: friendUserId,
                sessionCode: sessionCode,
                songTitle: widget.song.title,
                songId: widget.song.id,
              );
            }
          });
        });
        JamSessionService.instance.createSession(songId: widget.song.id);
      } else {
        // Сесія вже є — просто надсилаємо ще одне запрошення
        await Future.delayed(const Duration(milliseconds: 200));
        SocketService.instance.sendMessage(
          friendshipId,
          '[JAM_INVITE]$_activeSessionCode',
        );
        if (friendUserId != null) {
          SocketService.instance.sendSessionInvite(
            friendUserId: friendUserId,
            sessionCode: _activeSessionCode!,
            songTitle: widget.song.title,
            songId: widget.song.id,
          );
        }
      }
    } catch (e) {
      debugPrint('Invite error: $e');
    }
  }


  void _createWithoutInvite(BuildContext modalContext) {
    Navigator.pop(modalContext);
    JamSessionService.instance.connect().then((_) {
      JamSessionService.instance.onSessionCreated((sessionCode) {
        JamSessionService.instance.offAll();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JamSessionScreen(sessionCode: sessionCode, isHost: true),
            ),
          );
        }
      });
      JamSessionService.instance.createSession(songId: widget.song.id);
    });
  }

  void _goToPrevSong() {
    final playlist = widget.playlist;
    if (playlist == null || widget.playlistIndex <= 0) return;
    final prevIndex = widget.playlistIndex - 1;
    final prevMap = playlist[prevIndex];
    final prevSong = Song.fromJson({...prevMap, 'createdAt': prevMap['createdAt'] ?? DateTime.now().toIso8601String()});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SongDetailScreen(song: prevSong, playlist: playlist, playlistIndex: prevIndex)),
    );
  }

  void _goToNextSong() {
    final playlist = widget.playlist;
    if (playlist == null || widget.playlistIndex >= playlist.length - 1) return;
    final nextIndex = widget.playlistIndex + 1;
    final nextMap = playlist[nextIndex];
    final nextSong = Song.fromJson({...nextMap, 'createdAt': nextMap['createdAt'] ?? DateTime.now().toIso8601String()});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SongDetailScreen(song: nextSong, playlist: playlist, playlistIndex: nextIndex)),
    );
  }

  void _initAnimations() {
    if (_pulseCtrl != null) return;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tickPlayer.dispose();
    _scrollTimer?.cancel();
    _pulseCtrl?.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────
  // TICK sound
  // ─────────────────────────────────────────────────────────
  Future<void> _playTick() async {
    try {
      await _tickPlayer.stop();
      await _tickPlayer.resume();
    } catch (_) {}
    HapticFeedback.lightImpact();
  }

  // ─────────────────────────────────────────────────────────
  // COUNT-IN then scroll
  // ─────────────────────────────────────────────────────────
  void _startAutoScroll() {
    final bpm = widget.song.bpm;

    // If no BPM — just toggle simple continuous scroll
    if (bpm == null || bpm <= 0) {
      _startContinuousScroll();
      return;
    }

    // Show beat selector dialog
    _showCountInDialog(bpm);
  }

  void _showCountInDialog(int bpm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Відлік перед початком',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$bpm BPM',
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Скільки ударів відліку?',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [4, 8].map((n) {
                final selected = _countBeats == n;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _countBeats = n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Colors.greenAccent
                            : Colors.white10,
                        border: Border.all(
                            color: selected
                                ? Colors.greenAccent
                                : Colors.white24,
                            width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('$n',
                          style: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('СКАСУВАТИ',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _runCountIn(bpm);
            },
            child: const Text('СТАРТ'),
          ),
        ],
      ),
    );
  }

  Future<void> _runCountIn(int bpm) async {
    if (!mounted) return;
    _initAnimations();
    final intervalMs = (60000 / bpm).round();

    setState(() {
      _isCounting = true;
      _countValue = _countBeats;
    });

    for (int i = _countBeats; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countValue = i);
      _pulseCtrl?.forward(from: 0.0);
      await _playTick();
      await Future.delayed(Duration(milliseconds: intervalMs));
    }

    if (!mounted) return;
    setState(() { _isCounting = false; _countValue = 0; });

    // Start scroll synced with BPM
    _startBpmScroll(bpm);
  }

  // ─────────────────────────────────────────────────────────
  // BPM-synced scroll (tick every beat)
  // ─────────────────────────────────────────────────────────
  void _startBpmScroll(int bpm) {
    if (!mounted) return;
    setState(() => _isScrolling = true);

    final intervalMs = (60000 / bpm).round();

    _scrollTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) async {
      if (!_isScrolling || !mounted) {
        t.cancel();
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      final cur = _scrollController.offset;
      if (cur >= max) {
        t.cancel();
        if (mounted) setState(() => _isScrolling = false);
        return;
      }
      await _playTick();
      _scrollController.animateTo(
        (cur + _scrollSpeed).clamp(0.0, max),
        duration: Duration(milliseconds: (intervalMs * 0.85).round()),
        curve: Curves.easeInOut,
      );
    });
  }

  // ─────────────────────────────────────────────────────────
  // Continuous scroll (no BPM)
  // ─────────────────────────────────────────────────────────
  void _startContinuousScroll() {
    setState(() => _isScrolling = true);
    _doContinuousScroll();
  }

  void _doContinuousScroll() async {
    while (_isScrolling && mounted) {
      final max = _scrollController.position.maxScrollExtent;
      final cur = _scrollController.offset;
      if (cur >= max) {
        setState(() => _isScrolling = false);
        break;
      }
      await _scrollController.animateTo(
        (cur + _scrollSpeed).clamp(0.0, max),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    setState(() { _isScrolling = false; _isCounting = false; });
  }

  void _toggleAutoScroll() {
    if (_isScrolling || _isCounting) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  // ─────────────────────────────────────────────────────────
  // Chord diagram
  // ─────────────────────────────────────────────────────────
  void _showChordDiagram(String chordName) {
    final chordData = ChordDictionary.getChord(chordName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.all(20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: chordData != null
            ? ChordDiagram(
                chordName: chordData['name'],
                positions: chordData['pos'],
                size: 150,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chordName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Аплікатура для цього акорду відсутня',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ЗАКРИТИ',
                style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final chordList = widget.song.chords
        .split(RegExp(r'[\s,]+'))
        .where((c) => c.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.song.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
            Text(widget.song.artist,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() => _transposeOffset--),
            tooltip: 'Нижче',
          ),
          Center(
            child: Text(
              _transposeOffset == 0
                  ? '0'
                  : (_transposeOffset > 0
                      ? '+$_transposeOffset'
                      : '$_transposeOffset'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _transposeOffset++),
            tooltip: 'Вище',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // YouTube player (if available) — wrapped so it doesn't break full-screen
              if (_ytController != null)
                YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _ytController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.greenAccent,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.greenAccent,
                      handleColor: Colors.greenAccent,
                    ),
                  ),
                  builder: (ctx, player) => player,
                )
              else
                // Fallback: audio player for uploaded files
                AudioPlayerWidget(song: widget.song),

              // Chords row
              if (chordList.isNotEmpty)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: chordList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final transposedChord = ChordParser.transposeChord(
                          chordList[index], _transposeOffset);
                      return GestureDetector(
                        onTap: () => _showChordDiagram(transposedChord),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text(transposedChord,
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                      );
                    },
                  ),
                ),

              const Divider(color: Colors.white10),

              // Lyrics
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                  child: ChordLyricsDisplay(
                    lyrics: widget.song.lyrics,
                    transposeOffset: _transposeOffset,
                    onChordTap: _showChordDiagram,
                  ),
                ),
              ),
            ],
          ),

          // ── Countdown overlay ──
          if (_isCounting)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ВІДЛІК',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                            letterSpacing: 4)),
                    const SizedBox(height: 16),
                    ScaleTransition(
                      scale: _pulseAnim ?? const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.greenAccent, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_countValue',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 60,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.song.bpm != null)
                      Text('${widget.song.bpm} BPM',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 16)),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _stopAutoScroll,
                      child: const Text('СКАСУВАТИ',
                          style: TextStyle(color: Colors.white38)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // ── Bottom Controls ──
      bottomNavigationBar: Container(
        color: const Color(0xFF151515),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Playlist navigation row
              if (widget.playlist != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: widget.playlistIndex > 0 ? _goToPrevSong : null,
                        icon: const Icon(Icons.skip_previous, size: 20),
                        label: const Text('Попередня', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: Colors.white54),
                      ),
                      Text(
                        '${widget.playlistIndex + 1} / ${widget.playlist!.length}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      TextButton.icon(
                        onPressed: widget.playlistIndex < widget.playlist!.length - 1 ? _goToNextSong : null,
                        icon: const Icon(Icons.skip_next, size: 20),
                        label: const Text('Наступна', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: Colors.white54),
                      ),
                    ],
                  ),
                ),

              // BPM info strip
              if (widget.song.bpm != null && !_isCounting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.speed, color: Colors.white24, size: 14),
                      const SizedBox(width: 4),
                      Text('${widget.song.bpm} BPM  •  відлік: $_countBeats удари',
                          style: const TextStyle(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                ),

              // Speed slider (only when scrolling without BPM or no BPM set)
              if (_isScrolling && (widget.song.bpm == null))
                Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.white38, size: 16),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.greenAccent,
                          inactiveTrackColor: Colors.white10,
                          thumbColor: Colors.greenAccent,
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: _scrollSpeed,
                          min: 5,
                          max: 200,
                          onChanged: (val) => setState(() => _scrollSpeed = val),
                        ),
                      ),
                    ),
                    Text('${_scrollSpeed.round()} px/s',
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),

              // Scroll pixels per beat slider (BPM mode)
              if (_isScrolling && widget.song.bpm != null)
                Row(
                  children: [
                    const Icon(Icons.swap_vert, color: Colors.white38, size: 16),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.greenAccent,
                          inactiveTrackColor: Colors.white10,
                          thumbColor: Colors.greenAccent,
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: _scrollSpeed,
                          min: 5,
                          max: 200,
                          onChanged: (val) => setState(() => _scrollSpeed = val),
                        ),
                      ),
                    ),
                    Text('${_scrollSpeed.round()} px/удар',
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BottomBtn(
                    icon: (_isScrolling || _isCounting) ? Icons.stop : Icons.play_arrow,
                    label: (_isScrolling || _isCounting) ? 'Стоп' : 'Автоскрол',
                    color: (_isScrolling || _isCounting) ? Colors.orangeAccent : Colors.greenAccent,
                    onTap: _toggleAutoScroll,
                  ),
                  // Favorite button
                  _favoriteLoading
                      ? const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent))
                      : BottomBtn(
                          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                          label: _isFavorite ? 'Обране' : 'В обрані',
                          color: _isFavorite ? Colors.pinkAccent : Colors.white38,
                          onTap: _toggleFavorite,
                        ),
                  // Played button
                  _playedLoading
                      ? const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                      : BottomBtn(
                          icon: _isPlayed ? Icons.check_circle : Icons.check_circle_outline,
                          label: _isPlayed ? 'Зіграно' : 'Зіграв',
                          color: _isPlayed ? Colors.greenAccent : Colors.white38,
                          onTap: _togglePlayed,
                        ),
                  // Jam
                  BottomBtn(
                    icon: Icons.hub,
                    label: 'Jam',
                    color: Colors.orangeAccent,
                    onTap: _showJamBottomSheet,
                  ),
                  // Add to playlist
                  BottomBtn(
                    icon: Icons.playlist_add,
                    label: 'Плейліст',
                    color: Colors.white38,
                    onTap: _showAddToPlaylistDialog,
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

class BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const BottomBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
