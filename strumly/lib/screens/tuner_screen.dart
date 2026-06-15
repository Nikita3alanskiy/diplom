import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/tuner_controller.dart';
import '../models/tuner_data.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final TunerController _controller = TunerController();
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initTuner();
  }

  void _initTuner() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        // ОДИН СТРІМБІЛДЕР НА ВСЕ
        child: StreamBuilder<TunerData>(
          stream: _controller.tunerStream,
          builder: (context, snapshot) {
            final data = snapshot.data;

            // Визначаємо, яка струна зараз активна (з мікрофона або з кліку)
            int activeIndex = _controller.isAutoMode
                ? (data?.stringIndex ?? 0)
                : _controller.manualStringIndex;

            double needleValue = (data != null) ? (data.distance * 2).clamp(-1.0, 1.0) : 0.0;

            return Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "STRUMLY PRO",
                  style: TextStyle(letterSpacing: 6, color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 30),

                // Перемикач режимів
                _buildModeToggle(),

                const Spacer(),

                // Шкала
                _buildGauge(needleValue, data?.isInTune ?? false),
                const SizedBox(height: 20),

                // Нота
                Text(
                  data?.note ?? "--",
                  style: const TextStyle(fontSize: 100, color: Colors.white, fontWeight: FontWeight.w100),
                ),
                Text(
                  data != null ? "${data.pitch.toStringAsFixed(1)} Hz" : "Waiting for sound...",
                  style: const TextStyle(color: Colors.white24, fontSize: 14),
                ),

                const Spacer(),

                // ГОЛОВА ГІТАРИ (Тепер вона частина Column всередині StreamBuilder)
                _buildGuitarHead(activeIndex),

                const Spacer(),
                const Text(
                  "STANDARD E TUNING",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeBtn("AUTO", _controller.isAutoMode, true),
          _modeBtn("MANUAL", !_controller.isAutoMode, false),
        ],
      ),
    );
  }

  Widget _modeBtn(String text, bool active, bool setAuto) {
    return GestureDetector(
      onTap: () {
        _controller.updateMode(auto: setAuto);
        // Ми не робимо тут setState, бо updateMode кине подію в потік
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.greenAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: active ? Colors.black : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGuitarHead(int activeIndex) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ГОЛОВА ГІТАРИ
            Container(
              width: 160,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            // ЛІВА СТОРОНА (Баси) (60 - 45 = 15)
            _buildPeg(15, 185, "E2", 0, activeIndex), // 6-та (НИЗ)
            _buildPeg(15, 105, "A2", 1, activeIndex), // 5-та
            _buildPeg(15, 25, "D3", 2, activeIndex),  // 4-та (ВЕРХ)

            // ПРАВА СТОРОНА (Тонкі) (60 + 165 = 225)
            _buildPeg(225, 25, "G3", 3, activeIndex),  // 3-тя (ВЕРХ)
            _buildPeg(225, 105, "B3", 4, activeIndex), // 2-га
            _buildPeg(225, 185, "E4", 5, activeIndex), // 1-ша (НИЗ)
          ],
        ),
      ),
    );
  }

  Widget _buildPeg(double x, double y, String label, int index, int activeIndex) {
    bool isSelected = activeIndex == index;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          print("!!! НАТИСНУТО СТРУНУ: $label");
          _controller.updateMode(auto: false, index: index);
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.greenAccent : const Color(0xFF2A2A2A),
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGauge(double distance, bool inTune) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(11, (i) => Container(
                width: 2,
                height: i == 5 ? 20 : 10,
                color: i == 5 ? Colors.greenAccent : Colors.white10
            )),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment(distance, 0),
            child: Icon(Icons.arrow_drop_up, color: inTune ? Colors.greenAccent : Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}