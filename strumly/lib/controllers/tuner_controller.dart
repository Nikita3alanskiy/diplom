import 'dart:async';
import 'dart:math';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import '../models/tuner_data.dart';
import '../services/pitch_detector.dart';

class TunerController {
  final _audioCapture = FlutterAudioCapture();
  late PitchDetector _pitchDetector;

  final _tunerStreamController = StreamController<TunerData>.broadcast();
  Stream<TunerData> get tunerStream => _tunerStreamController.stream;

  bool isAutoMode = true;
  int manualStringIndex = 0;
  bool _isInitialized = false;

  // Частоти та назви для Standard Tuning (EADGBE)
  List<double> _frequencies = [82.41, 110.00, 146.83, 196.00, 246.94, 329.63];
  List<String> _noteNames = ["E2", "A2", "D3", "G3", "B3", "E4"];
  String currentTuningName = "STANDARD E TUNING";

  TunerController() {
    _pitchDetector = PitchDetector(44100, 2048);
  }

  void setTuning(String name, List<double> freqs, List<String> notes) {
    currentTuningName = name;
    _frequencies = freqs;
    _noteNames = notes;
    _tunerStreamController.add(TunerData(
      note: _noteNames[manualStringIndex],
      pitch: _frequencies[manualStringIndex],
      distance: 0.0,
      isInTune: false,
      stringIndex: manualStringIndex,
    ));
  }

  // ОНОВЛЕНИЙ МЕТОД: тепер він "штовхає" UI відразу після кліку
  void updateMode({required bool auto, int? index}) {
    isAutoMode = auto;
    if (index != null) manualStringIndex = index;

    // Створюємо "фейковий" об'єкт даних, щоб екран миттєво оновив підсвітку кнопок
    _tunerStreamController.add(TunerData(
      note: _noteNames[manualStringIndex],
      pitch: _frequencies[manualStringIndex],
      distance: 0.0,
      isInTune: false,
      stringIndex: manualStringIndex,
    ));
  }

  void start() async {
    try {
      // Ініціалізуємо плагін перед першим запуском (обов'язково для flutter_audio_capture)
      if (!_isInitialized) {
        await _audioCapture.init();
        _isInitialized = true;
      }
      await _audioCapture.start(_onAudioData, _onError, sampleRate: 44100, bufferSize: 2048);
    } catch (e) {
      print("Tuner Start Error: $e");
    }
  }

  void stop() async {
    await _audioCapture.stop();
  }

  void _onAudioData(dynamic obj) {
    if (obj is! List) return;
    final List<double> buffer = obj.map((e) => double.parse(e.toString())).toList();

    // Розрахунок гучності (RMS)
    double rms = sqrt(buffer.map((x) => x * x).reduce((a, b) => a + b) / buffer.length);

    // Якщо занадто тихо — нічого не шлемо (ігноруємо шум)
    if (rms < 0.01) return;

    final result = _pitchDetector.getPitch(buffer);

    // Якщо знайдено чітку частоту в межах гітарного діапазону
    if (result.pitched && result.pitch > 40 && result.pitch < 1000) {
      _tunerStreamController.add(_processPitch(result.pitch));
    }
  }

  TunerData _processPitch(double pitch) {
    int targetIndex = 0;

    if (isAutoMode) {
      // Шукаємо найближчу струну автоматично
      double minDiff = double.infinity;
      for (int i = 0; i < _frequencies.length; i++) {
        double diff = (pitch - _frequencies[i]).abs();
        if (diff < minDiff) {
          minDiff = diff;
          targetIndex = i;
        }
      }
    } else {
      // В ручному режимі використовуємо тільки вибраний індекс
      targetIndex = manualStringIndex;
    }

    // Відхилення від ідеальної частоти (для стрілки)
    // Ділимо на 5.0, щоб отримати діапазон приблизно від -1.0 до 1.0 при відхиленні в 5 Гц
    double distance = (pitch - _frequencies[targetIndex]) / 5.0;

    return TunerData(
      note: _noteNames[targetIndex],
      pitch: pitch,
      distance: distance.clamp(-1.0, 1.0),
      isInTune: distance.abs() < 0.05, // Точність налаштування
      stringIndex: targetIndex,
    );
  }

  void _onError(Object e) => print("Audio Stream Error: $e");
}