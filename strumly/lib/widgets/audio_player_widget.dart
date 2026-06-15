import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import '../services/songs_api_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Song song;
  const AudioPlayerWidget({super.key, required this.song});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  bool _isLoading = false;
  String? _error;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    
    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    
    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _prepareAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _prepareAudio() async {
    String? url = widget.song.audioUrl;
    if (url == null || url.isEmpty) return;

    // Перетворюємо відносний шлях на абсолютний
    if (url.startsWith('/uploads')) {
      url = '${SongsApiService.serverBaseUrl}$url';
    }

    setState(() { _isLoading = true; _error = null; });
    
    try {
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.last;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');

      if (!await file.exists()) {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to load audio: ${response.statusCode}');
        }
      }

      _localFilePath = file.path;
      await _audioPlayer.setSource(DeviceFileSource(_localFilePath!));
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Помилка завантаження аудіо');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_localFilePath == null) return;
    
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _onSeek(double value) {
    if (_duration.inMilliseconds > 0) {
      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.song.audioUrl == null || widget.song.audioUrl!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: const Text('Аудіофайл відсутній', style: TextStyle(color: Colors.white38)),
      );
    }

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          children: [
            SizedBox(
              width: 24, height: 24, 
              child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2)
            ),
            SizedBox(height: 8),
            Text('Завантаження аудіо...', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.greenAccent,
                  size: 48,
                ),
                padding: EdgeInsets.zero,
                onPressed: _toggleAudio,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.greenAccent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.greenAccent,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                    onChanged: _onSeek,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
