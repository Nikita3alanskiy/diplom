import 'dart:math';

class PitchDetectorResult {
  final double pitch;
  final bool pitched;
  PitchDetectorResult(this.pitch, this.pitched);
}

class PitchDetector {
  final double sampleRate;
  final int bufferSize;

  PitchDetector(this.sampleRate, this.bufferSize);

  PitchDetectorResult getPitch(List<double> audioBuffer) {
    // 1. Знаходимо автокореляцію (пошук повторюваних шаблонів у сигналі)
    int bestLag = -1;
    double bestCorrelation = -1.0;

    // Гітарний діапазон частот: від ~70 Гц (E2) до ~1000 Гц
    // Обчислюємо межі зміщення (lag) на основі sampleRate
    int minLag = (sampleRate / 1000).floor(); // Для високих частот
    int maxLag = (sampleRate / 70).floor();   // Для низьких частот

    for (int lag = minLag; lag < maxLag; lag++) {
      double correlation = 0;
      for (int i = 0; i < bufferSize - lag; i++) {
        correlation += audioBuffer[i] * audioBuffer[i + lag];
      }

      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestLag = lag;
      }
    }

    // 2. Вираховуємо частоту
    if (bestLag != -1 && bestCorrelation > 0.1) { // 0.1 - поріг впевненості
      double frequency = sampleRate / bestLag;

      // Додаткова перевірка, чи частота в межах розумного для гітари
      if (frequency >= 70 && frequency <= 1000) {
        return PitchDetectorResult(frequency, true);
      }
    }

    return PitchDetectorResult(0.0, false);
  }
}