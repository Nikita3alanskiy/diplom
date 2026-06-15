class ChordDictionary {
  static final List<Map<String, dynamic>> chords = [
    // A
    {'name': 'A',  'pos': [null, 0, 2, 2, 2, 0]},
    {'name': 'Am', 'pos': [null, 0, 2, 2, 1, 0]},
    {'name': 'A7', 'pos': [null, 0, 2, 0, 2, 0]},
    {'name': 'A#', 'pos': [null, 1, 3, 3, 3, 1]},
    {'name': 'A#m','pos': [null, 1, 3, 3, 2, 1]},
    
    // B
    {'name': 'B',  'pos': [null, 2, 4, 4, 4, 2]},
    {'name': 'Bm', 'pos': [null, 2, 4, 4, 3, 2]},
    {'name': 'B7', 'pos': [null, 2, 1, 2, 0, 2]},
    
    // C
    {'name': 'C',  'pos': [null, 3, 2, 0, 1, 0]},
    {'name': 'Cm', 'pos': [null, 3, 5, 5, 4, 3]},
    {'name': 'C7', 'pos': [null, 3, 2, 3, 1, 0]},
    {'name': 'C#', 'pos': [null, 4, 6, 6, 6, 4]},
    {'name': 'C#m','pos': [null, 4, 6, 6, 5, 4]},

    // D
    {'name': 'D',  'pos': [null, null, 0, 2, 3, 2]},
    {'name': 'Dm', 'pos': [null, null, 0, 2, 3, 1]},
    {'name': 'D7', 'pos': [null, null, 0, 2, 1, 2]},
    {'name': 'D#', 'pos': [null, 6, 8, 8, 8, 6]},
    {'name': 'D#m','pos': [null, 6, 8, 8, 7, 6]},

    // E
    {'name': 'E',  'pos': [0, 2, 2, 1, 0, 0]},
    {'name': 'Em', 'pos': [0, 2, 2, 0, 0, 0]},
    {'name': 'E7', 'pos': [0, 2, 0, 1, 0, 0]},
    
    // F
    {'name': 'F',  'pos': [1, 3, 3, 2, 1, 1]},
    {'name': 'Fm', 'pos': [1, 3, 3, 1, 1, 1]},
    {'name': 'F7', 'pos': [1, 3, 1, 2, 1, 1]},
    {'name': 'F#', 'pos': [2, 4, 4, 3, 2, 2]},
    {'name': 'F#m','pos': [2, 4, 4, 2, 2, 2]},

    // G
    {'name': 'G',  'pos': [3, 2, 0, 0, 0, 3]},
    {'name': 'Gm', 'pos': [3, 5, 5, 3, 3, 3]},
    {'name': 'G7', 'pos': [3, 2, 0, 0, 0, 1]},
    {'name': 'G#', 'pos': [4, 6, 6, 5, 4, 4]},
    {'name': 'G#m','pos': [4, 6, 6, 4, 4, 4]},
  ];

  static Map<String, dynamic>? getChord(String name) {
    // Exact match
    try {
      return chords.firstWhere((c) => c['name'] == name);
    } catch (e) {
      // Return null if not found
      return null;
    }
  }
}
