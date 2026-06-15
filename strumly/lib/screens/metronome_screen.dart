import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> with SingleTickerProviderStateMixin {
  int _bpm = 120;
  bool _isPlaying = false;
  Timer? _timer;
  
  // We use multiple audio players to avoid overlap clipping at high BPMs
  final List<AudioPlayer> _players = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  int _currentPlayerIndex = 0;
  
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Pre-load the audio source
    for (var player in _players) {
      player.setSource(AssetSource('audio/tick.wav'));
      player.setReleaseMode(ReleaseMode.stop);
    }
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var player in _players) {
      player.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _playTick() async {
    // Pulse animation
    _animController.forward(from: 0.0).then((_) {
      _animController.reverse();
    });

    // Play sound using round-robin to avoid clipping
    final player = _players[_currentPlayerIndex];
    if (player.state == PlayerState.playing) {
      await player.stop();
    }
    await player.resume();
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _playTick(); // Play immediately on start
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    final interval = (60000 / _bpm).round();
    _timer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      _playTick();
    });
  }

  void _updateBpm(int newBpm) {
    setState(() {
      _bpm = newBpm.clamp(40, 240);
      if (_isPlaying) {
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("МЕТРОНОМ",
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Visual Indicator
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPlaying ? Colors.greenAccent : const Color(0xFF2A2A2A),
                  boxShadow: _isPlaying 
                      ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  _bpm.toString(),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: _isPlaying ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              "BPM",
              style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            
            const Spacer(),
            
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlBtn(Icons.remove, () => _updateBpm(_bpm - 1)),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.greenAccent,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Expanded(
                      child: Slider(
                        value: _bpm.toDouble(),
                        min: 40,
                        max: 240,
                        onChanged: (val) => _updateBpm(val.toInt()),
                      ),
                    ),
                  ),
                  _buildControlBtn(Icons.add, () => _updateBpm(_bpm + 1)),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Play Button
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isPlaying ? Colors.redAccent : Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                  color: Colors.black,
                ),
              ),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
