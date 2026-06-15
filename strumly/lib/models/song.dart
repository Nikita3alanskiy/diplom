class Song {
  final int id;
  final String title;
  final String artist;
  final String chords;
  final String lyrics;
  final String? audioUrl;
  final String? youtubeUrl;
  final int? bpm;
  final DateTime createdAt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.chords,
    required this.lyrics,
    this.audioUrl,
    this.youtubeUrl,
    this.bpm,
    required this.createdAt,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? 'Unknown',
      chords: json['chords'] as String? ?? '',
      lyrics: json['lyrics'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      bpm: json['bpm'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'chords': chords,
      'lyrics': lyrics,
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (bpm != null) 'bpm': bpm,
    };
  }
}
