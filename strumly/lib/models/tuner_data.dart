class TunerData {
  final String note;         // Назва ноти (напр. "E2")
  final double pitch;        // Частота в Гц (напр. 82.41)
  final double distance;     // Відхилення від ідеалу (від -1.0 до 1.0)
  final bool isInTune;       // Чи потрапив користувач у ноту
  final int? stringIndex;    // Індекс струни (0-5), щоб підсвітити кілок

  TunerData({
    required this.note,
    required this.pitch,
    required this.distance,
    this.isInTune = false,
    this.stringIndex,
  });
}