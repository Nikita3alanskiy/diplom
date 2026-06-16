import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/jam_session_service.dart';
import '../services/songs_api_service.dart';
import '../services/auth_api_service.dart';
import '../models/song.dart';
import '../widgets/chord_lyrics_display.dart';
import '../widgets/chord_diagram.dart';
import '../models/chord_dictionary.dart';
import 'premium_screen.dart';

class JamSessionScreen extends StatefulWidget {
  final String sessionCode;
  final bool isHost;
  
  const JamSessionScreen({
    super.key,
    required this.sessionCode,
    required this.isHost,
  });

  @override
  State<JamSessionScreen> createState() => _JamSessionScreenState();
}

class _JamSessionScreenState extends State<JamSessionScreen> {
  final JamSessionService _jamService = JamSessionService.instance;
  final ScrollController _scrollController = ScrollController();
  
  // State
  Map<String, dynamic>? _sessionState;
  Song? _currentSong;
  bool _isLoading = true;
  String _error = '';

  // Scroll & Metronome
  bool _isScrolling = false;
  double _scrollSpeed = 40.0;
  int? _bpm;
  Timer? _scrollTimer;
  final List<AudioPlayer> _tickPlayers = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  int _currentPlayerIndex = 0;
  bool _isBeatVisual = false;

  // Playlist
  List<dynamic> _playlistSongs = [];
  int _currentSongIndex = 0;

  // Members
  List<dynamic> _members = [];
  int _memberCount = 1;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _connectAndJoin();
  }

  Future<void> _initAudio() async {
    for (var p in _tickPlayers) {
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setSource(AssetSource('audio/tick.wav'));
      p.setReleaseMode(ReleaseMode.stop);
    }
  }

  Future<void> _connectAndJoin() async {
    try {
      await _jamService.connect();

      _jamService.onJoinError((msg) {
        if (mounted) setState(() { _error = msg; _isLoading = false; });
      });

      _jamService.onSessionState((state) async {
        if (!mounted) return;
        _sessionState = state;
        _members = state['members'] ?? [];
        _memberCount = state['memberCount'] ?? 1;
        _bpm = state['bpm'];
        _scrollSpeed = (state['scrollSpeed'] as num?)?.toDouble() ?? 40.0;
        _playlistSongs = state['playlistSongs'] ?? [];
        _currentSongIndex = state['currentSongIndex'] ?? 0;
        
        await _loadSong(state['songId']);
        
        if (state['isScrolling'] == true && state['startTimestamp'] != null) {
           _startLocalScroll(
             bpm: _bpm, 
             speed: _scrollSpeed, 
             startTimestamp: state['startTimestamp']
           );
        }
      });

      _jamService.onMemberJoined((data) {
        if (mounted) {
          setState(() {
            _members = data['members'] ?? [];
            _memberCount = data['memberCount'] ?? 1;
          });
        }
      });

      _jamService.onMemberLeft((data) {
        if (mounted) {
          setState(() {
            _members = data['members'] ?? [];
            _memberCount = data['memberCount'] ?? 1;
          });
        }
      });

      _jamService.onSessionEnded((reason) {
        if (mounted) {
          _stopLocalScroll();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Сесія завершена', style: TextStyle(color: Colors.white)),
              content: const Text('Хост завершив сесію.', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // close dialog
                    Navigator.pop(context); // exit screen
                  }, 
                  child: const Text('ОК', style: TextStyle(color: Colors.greenAccent))
                )
              ],
            )
          );
        }
      });

      _jamService.onScrollStarted((data) {
        _startLocalScroll(
          bpm: data['bpm'],
          speed: (data['scrollSpeed'] as num).toDouble(),
          startTimestamp: data['startTimestamp'],
        );
      });

      _jamService.onScrollStopped(() {
        _stopLocalScroll();
      });

      _jamService.onScrollSpeedUpdated((speed) {
        if (mounted) setState(() => _scrollSpeed = speed);
      });

      _jamService.onBpmUpdated((bpm) {
        if (mounted) setState(() => _bpm = bpm);
      });

      _jamService.onSongChanged((songIndex, songId) {
        if (mounted) {
          _stopLocalScroll();
          setState(() => _currentSongIndex = songIndex);
          _loadSong(songId);
        }
      });

      // Join the session
      _jamService.joinSession(widget.sessionCode);

    } catch (e) {
      if (mounted) setState(() { _error = 'Помилка підключення: $e'; _isLoading = false; });
    }
  }

  Future<void> _loadSong(int? songId) async {
    if (songId == null) {
      setState(() { _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final songData = await SongsApiService.getSong(songId);
      if (mounted) {
        setState(() {
          _currentSong = songData;
          if (widget.isHost) {
            // Always ensure a BPM value for host (default 120 if song has none)
            _bpm = _currentSong?.bpm ?? _bpm ?? 120;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Не вдалось завантажити пісню'; _isLoading = false; });
    }
  }

  // ─── Scrolling Logic ───────────────────────────────────────

  void _playTick() async {
    try {
      final player = _tickPlayers[_currentPlayerIndex];
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      await player.resume();
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _tickPlayers.length;
      
      if (mounted) {
        setState(() => _isBeatVisual = true);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _isBeatVisual = false);
        });
      }
    } catch (_) {}
  }

  void _startLocalScroll({required int? bpm, required double speed, required int startTimestamp}) {
    if (!mounted) return;
    _scrollTimer?.cancel();
    
    setState(() {
      _isScrolling = true;
      _bpm = bpm;
      _scrollSpeed = speed;
    });

    if (bpm != null && bpm > 0) {
      final intervalMs = (60000 / bpm).round();
      int ticksPlayed = 0;
      
      // Count-in: 4 beats before scroll
      _playTick();
      ticksPlayed++;
      
      _scrollTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
        if (!_isScrolling || !mounted) { t.cancel(); return; }
        
        _playTick();
        ticksPlayed++;
        
        if (ticksPlayed > 4) {
          _doScrollTick(speed, intervalMs);
        }
      });

    } else {
      // Continuous smooth scroll
      _doContinuousScroll();
    }
  }

  void _doScrollTick(double speed, int intervalMs) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.offset;
    if (cur >= max) {
      _stopLocalScroll();
      if (widget.isHost) _jamService.stopScroll();
      return;
    }
    _scrollController.animateTo(
      (cur + speed).clamp(0.0, max),
      duration: Duration(milliseconds: (intervalMs * 0.85).round()),
      curve: Curves.easeInOut,
    );
  }

  void _doContinuousScroll() async {
    while (_isScrolling && mounted) {
      if (!_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      final max = _scrollController.position.maxScrollExtent;
      final cur = _scrollController.offset;
      if (cur >= max) {
        _stopLocalScroll();
        if (widget.isHost) _jamService.stopScroll();
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

  void _stopLocalScroll() {
    _scrollTimer?.cancel();
    if (mounted) setState(() => _isScrolling = false);
  }

  // ─── Host Actions ──────────────────────────────────────────

  void _toggleHostScroll() async {
    if (_isScrolling) {
      _jamService.stopScroll();
      _stopLocalScroll(); // optimistically stop local
    } else {
      bool isPremium = await AuthApiService.isPremium();
      if (!isPremium) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text('Преміум функція', style: TextStyle(color: Colors.orangeAccent)),
            content: const Text('Автоскрол для учасників сесії доступний лише з Premium підпискою.', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                },
                child: const Text('ПРИДБАТИ', style: TextStyle(color: Colors.orangeAccent))
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ОК', style: TextStyle(color: Colors.greenAccent))
              )
            ],
          )
        );
        return;
      }
      _jamService.startScroll(bpm: _bpm, scrollSpeed: _scrollSpeed);
    }
  }

  void _onHostSpeedChanged(double speed) {
    setState(() => _scrollSpeed = speed);
    _jamService.updateScrollSpeed(speed);
  }

  void _changePlaylistSong(int delta) {
    if (_playlistSongs.isEmpty || _isScrolling) return;
    final newIndex = _currentSongIndex + delta;
    if (newIndex >= 0 && newIndex < _playlistSongs.length) {
      final newSongId = _playlistSongs[newIndex]['id'];
      _jamService.changeSong(newIndex, newSongId);
    }
  }

  void _changeBpm(int delta) {
    if (_bpm == null || _isScrolling) return; // don't change while scrolling
    final newBpm = (_bpm! + delta).clamp(30, 300);
    setState(() => _bpm = newBpm);
    _jamService.updateBpm(newBpm);
  }

  void _showMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Учасники Jam Session ($_memberCount/8)', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('Код: ${widget.sessionCode}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          ..._members.map((m) {
            final isHost = m['userId'] == _sessionState?['hostUserId'];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isHost ? Colors.orangeAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                child: Icon(isHost ? Icons.star : Icons.person, color: isHost ? Colors.orangeAccent : Colors.greenAccent, size: 20),
              ),
              title: Text(m['name'] ?? 'Учасник', style: const TextStyle(color: Colors.white)),
              trailing: isHost ? const Text('Хост', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)) : null,
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
      )
    );
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    for (var p in _tickPlayers) { p.dispose(); }
    _jamService.leaveSession();
    _jamService.offAll();
    super.dispose();
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
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_error, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Назад'))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: _isBeatVisual ? const Color(0xFF1A3320) : const Color(0xFF151515),
        elevation: 0,
        title: Column(
          children: [
            const Text('JAM SESSION', style: TextStyle(color: Colors.greenAccent, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
            Text(_currentSong?.title ?? '...', style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: _showMembers,
          )
        ],
      ),
      body: Column(
        children: [
          if (_currentSong != null)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: ChordLyricsDisplay(
                  lyrics: _currentSong!.lyrics,
                  transposeOffset: 0,
                  onChordTap: (chord) {
                    // Minimal chord tap
                    final chordData = ChordDictionary.getChord(chord);
                    if (chordData != null) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A1A),
                          content: ChordDiagram(chordName: chordData['name'], positions: chordData['pos'], size: 150),
                        )
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
      
      bottomNavigationBar: Container(
        color: const Color(0xFF151515),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_playlistSongs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.isHost)
                        IconButton(
                          icon: const Icon(Icons.skip_previous, color: Colors.white),
                          onPressed: (_isScrolling || _currentSongIndex <= 0) ? null : () => _changePlaylistSong(-1),
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          '${_currentSongIndex + 1} / ${_playlistSongs.length} пісень',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                      if (widget.isHost)
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: (_isScrolling || _currentSongIndex >= _playlistSongs.length - 1) ? null : () => _changePlaylistSong(1),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

              // Always show BPM controls for host; show for guests when BPM is set
              if (widget.isHost || _bpm != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isHost)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.greenAccent),
                          onPressed: _isScrolling ? null : () => _changeBpm(-5),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.speed, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text('${_bpm ?? 120} BPM', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      if (widget.isHost)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                          onPressed: _isScrolling ? null : () => _changeBpm(5),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                    ],
                  ),
                ),
                
              if (widget.isHost) ...[
                Row(
                  children: [
                    const Icon(Icons.swap_vert, color: Colors.white38, size: 16),
                    Expanded(
                      child: Slider(
                        activeColor: Colors.greenAccent,
                        inactiveColor: Colors.white10,
                        value: _scrollSpeed,
                        min: 5,
                        max: 200,
                        onChanged: _onHostSpeedChanged,
                      ),
                    ),
                    Text('${_scrollSpeed.round()} px/s', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScrolling ? Colors.orangeAccent : Colors.greenAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(_isScrolling ? Icons.stop : Icons.play_arrow),
                  label: Text(_isScrolling ? 'ЗУПИНИТИ' : 'СТАРТ', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                  onPressed: _toggleHostScroll,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isScrolling) ...[
                        const SizedBox(
                          width: 16, height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent)
                        ),
                        const SizedBox(width: 12),
                        const Text('Автоскрол працює...', style: TextStyle(color: Colors.greenAccent)),
                      ] else ...[
                        const Icon(Icons.hourglass_empty, color: Colors.white38, size: 18),
                        const SizedBox(width: 8),
                        const Text('Очікування дій хоста...', style: TextStyle(color: Colors.white54)),
                      ]
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
