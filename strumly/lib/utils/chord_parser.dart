import 'package:flutter/foundation.dart';

class ChordParser {
  static final List<String> notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  // Match chords like C, C#, Db, Dm, Dmaj7, C/E, H, Hm
  static final RegExp _chordRegex = RegExp(
    r'^([CDEFGABH][#b]?)(m|dim|aug|sus2|sus4|maj7|min7|7|9|6|maj|min)?(\/[CDEFGABH][#b]?)?$',
  );

  static bool isChordLine(String line) {
    if (line.trim().isEmpty) return false;
    
    final words = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (words.isEmpty) return false;

    for (var word in words) {
      if (!_chordRegex.hasMatch(word)) {
        return false; // Not all words are chords
      }
    }
    return true; // All words match chord pattern
  }

  static String transposeChord(String chord, int semitones) {
    if (semitones == 0) return chord;
    final match = _chordRegex.firstMatch(chord);
    if (match == null) return chord;

    final rootNote = match.group(1)!;
    final modifier = match.group(2) ?? '';
    final bassNote = match.group(3);

    final newRoot = _transposeNote(rootNote, semitones);
    String newBass = '';
    if (bassNote != null) {
      newBass = '/' + _transposeNote(bassNote.substring(1), semitones);
    }
    return newRoot + modifier + newBass;
  }

  static String _transposeNote(String note, int semitones) {
    String normalized = note;
    
    // Normalize H to B
    if (normalized == 'H') normalized = 'B';
    if (normalized == 'Hb') normalized = 'A#'; // although rarely used
    if (normalized == 'H#') normalized = 'C';

    // Normalize flats to sharps
    const flats = {'Cb': 'B', 'Db': 'C#', 'Eb': 'D#', 'Fb': 'E', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#'};
    if (flats.containsKey(normalized)) {
      normalized = flats[normalized]!;
    }
    
    int index = notes.indexOf(normalized);
    if (index == -1) return note; // fallback

    // Calculate new index
    int newIndex = (index + semitones) % 12;
    if (newIndex < 0) newIndex += 12;

    return notes[newIndex];
  }
}
