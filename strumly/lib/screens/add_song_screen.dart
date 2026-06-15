import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/songs_api_service.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({super.key});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _chordsCtrl = TextEditingController();
  final _lyricsCtrl = TextEditingController();
  final _audioUrlCtrl = TextEditingController();
  final _bpmCtrl = TextEditingController();
  bool _isSaving = false;
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _chordsCtrl.dispose();
    _lyricsCtrl.dispose();
    _audioUrlCtrl.dispose();
    _bpmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? audioUrl = _audioUrlCtrl.text.trim();
      if (_selectedFilePath != null) {
        audioUrl = await SongsApiService.uploadAudio(_selectedFilePath!);
      }

      await SongsApiService.createSong({
        'title': _titleCtrl.text.trim(),
        'artist': _artistCtrl.text.trim().isEmpty ? 'Unknown' : _artistCtrl.text.trim(),
        'chords': _chordsCtrl.text.trim(),
        'lyrics': _lyricsCtrl.text.trim(),
        if (audioUrl.isNotEmpty) 'audioUrl': audioUrl,
        if (_bpmCtrl.text.trim().isNotEmpty) 'bpm': int.tryParse(_bpmCtrl.text.trim()),
      });
      if (mounted) Navigator.pop(context, true); // true = reload list
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('НОВА ПІСНЯ',
            style: TextStyle(
                letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _save,
              child: const Text('ЗБЕРЕГТИ',
                  style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildField(_titleCtrl, 'Назва пісні *', Icons.music_note, required: true),
            const SizedBox(height: 16),
            _buildField(_artistCtrl, 'Виконавець', Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(
              _chordsCtrl,
              'Акорди (через пробіл, напр: Am C G D) *',
              Icons.piano,
              required: true,
              hint: 'Am C G D Em F',
            ),
            const SizedBox(height: 16),
            _buildField(
              _lyricsCtrl,
              'Текст пісні *',
              Icons.article_outlined,
              required: true,
              maxLines: 12,
            ),
            const SizedBox(height: 16),
            _buildField(
              _audioUrlCtrl,
              'URL аудіо (або виберіть файл нижче)',
              Icons.audiotrack_outlined,
              hint: 'https://example.com/song.mp3',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                // Request storage permission on Android
                if (Platform.isAndroid) {
                  PermissionStatus status;
                  // Android 13+
                  status = await Permission.audio.request();
                  if (!status.isGranted) {
                    // Fallback for older Android
                    status = await Permission.storage.request();
                  }
                  if (!status.isGranted) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Потрібен дозвіл на читання файлів')),
                      );
                    }
                    return;
                  }
                }
                final result = await FilePicker.pickFiles(type: FileType.audio);
                if (result != null && result.files.single.path != null) {
                  setState(() {
                    _selectedFilePath = result.files.single.path;
                    _selectedFileName = result.files.single.name;
                    _audioUrlCtrl.clear();
                  });
                }
              },
              icon: const Icon(Icons.upload_file),
              label: Text(_selectedFileName ?? 'ВИБРАТИ АУДІОФАЙЛ З ПРИСТРОЮ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.greenAccent,
                side: const BorderSide(color: Colors.greenAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_selectedFileName != null)
              TextButton(
                onPressed: () => setState(() {
                  _selectedFilePath = null;
                  _selectedFileName = null;
                }),
                child: const Text('Видалити файл', style: TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 16),
            _buildField(
              _bpmCtrl,
              'BPM (швидкість, опціонально)',
              Icons.speed,
              hint: '120',
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('ЗБЕРЕГТИ ПІСНЮ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12),
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 1.5),
        ),
      ),
      validator: required
          ? (val) => (val == null || val.trim().isEmpty) ? 'Заповніть це поле' : null
          : null,
    );
  }
}
