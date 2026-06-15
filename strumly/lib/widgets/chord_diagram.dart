import 'package:flutter/material.dart';

class ChordDiagram extends StatelessWidget {
  final String chordName;
  final List<int?> positions; // 6 elements for strings E A D G B E, null = X, 0 = open, 1+ = fret
  final double size;

  const ChordDiagram({
    super.key,
    required this.chordName,
    required this.positions,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          chordName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: size,
          height: size * 1.2,
          child: CustomPaint(
            painter: _ChordPainter(positions: positions),
          ),
        ),
      ],
    );
  }
}

class _ChordPainter extends CustomPainter {
  final List<int?> positions;

  _ChordPainter({required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2.0;

    final Paint stringPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.0;
      
    final Paint nutPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0;

    final double startY = 20.0;
    final double stringSpacing = size.width / 5;
    final int frets = 5;
    final double fretSpacing = (size.height - startY) / frets;

    // Draw strings (vertical lines)
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(i * stringSpacing, startY),
        Offset(i * stringSpacing, size.height),
        stringPaint,
      );
    }

    // Draw frets (horizontal lines)
    for (int i = 0; i <= frets; i++) {
      canvas.drawLine(
        Offset(0, startY + i * fretSpacing),
        Offset(size.width, startY + i * fretSpacing),
        i == 0 ? nutPaint : linePaint,
      );
    }

    // Draw dots and open/muted strings
    final Paint dotPaint = Paint()..color = Colors.greenAccent;
    final Paint textPaint = Paint()..color = Colors.white70;

    for (int i = 0; i < 6; i++) {
      final pos = positions[i];
      final double x = i * stringSpacing;
      
      if (pos == null) {
        // Draw X
        _drawCross(canvas, x, startY - 10, textPaint);
      } else if (pos == 0) {
        // Draw O
        _drawCircle(canvas, x, startY - 10, textPaint);
      } else {
        // Draw dot on fret
        final double y = startY + (pos - 1) * fretSpacing + fretSpacing / 2;
        canvas.drawCircle(Offset(x, y), 6, dotPaint);
      }
    }
  }

  void _drawCross(Canvas canvas, double x, double y, Paint paint) {
    final double s = 4.0;
    canvas.drawLine(Offset(x - s, y - s), Offset(x + s, y + s), paint);
    canvas.drawLine(Offset(x + s, y - s), Offset(x - s, y + s), paint);
  }

  void _drawCircle(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawCircle(Offset(x, y), 4.0, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
    paint.style = PaintingStyle.fill; // Reset
  }

  @override
  bool shouldRepaint(covariant _ChordPainter oldDelegate) {
    return oldDelegate.positions != positions;
  }
}
