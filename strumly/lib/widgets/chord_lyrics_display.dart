import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/chord_parser.dart';

class ChordLyricsDisplay extends StatefulWidget {
  final String lyrics;
  final int transposeOffset;
  final Function(String) onChordTap;

  const ChordLyricsDisplay({
    super.key,
    required this.lyrics,
    required this.transposeOffset,
    required this.onChordTap,
  });

  @override
  State<ChordLyricsDisplay> createState() => _ChordLyricsDisplayState();
}

class _ChordLyricsDisplayState extends State<ChordLyricsDisplay> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (var r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Clean old recognizers
    for (var r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final lines = widget.lyrics.split('\n');
    final List<TextSpan> spans = [];

    for (var line in lines) {
      if (ChordParser.isChordLine(line)) {
        final matches = RegExp(r'(\S+)|(\s+)').allMatches(line);
        for (final match in matches) {
          final text = match.group(0)!;
          if (text.trim().isNotEmpty) {
            final transposed = ChordParser.transposeChord(text, widget.transposeOffset);
            final recognizer = TapGestureRecognizer()
              ..onTap = () => widget.onChordTap(transposed);
            _recognizers.add(recognizer);

            spans.add(TextSpan(
              text: transposed,
              style: const TextStyle(
                color: Color(0xFFE91E63), // Pink color like in screenshot
                fontWeight: FontWeight.bold,
              ),
              recognizer: recognizer,
            ));
          } else {
            // Spacing
            spans.add(TextSpan(
              text: text,
              style: const TextStyle(color: Colors.white70),
            ));
          }
        }
      } else {
        // Normal lyric line
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(color: Colors.white),
        ));
      }
      spans.add(const TextSpan(text: '\n'));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          height: 1.8,
          fontFamily: 'monospace',
        ),
        children: spans,
      ),
    );
  }
}
