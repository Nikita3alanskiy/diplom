import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/songs_api_service.dart';
import '../services/favorites_api_service.dart';
import 'song_detail_screen.dart';
import 'add_song_screen.dart';
import 'catalog_screen.dart';
import '../services/auth_api_service.dart';
import 'premium_screen.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Song> _songs = [];
  List<Song> _favoriteSongs = [];
  List<Song> _filtered = [];
  bool _isLoading = true;
  String? _error;
  bool _searchVisible = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSongs();
    _searchCtrl.addListener(_onSearch);
  }

  void _onTabChanged() {
    _onSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    final isFavoritesTab = _tabController.index == 1;
    final sourceList = isFavoritesTab ? _favoriteSongs : _songs;
    
    setState(() {
      _filtered = q.isEmpty
          ? sourceList
          : sourceList.where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _loadSongs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final songs = await SongsApiService.getSongs();
      List<Song> favorites = [];
      try {
        final favMaps = await FavoritesApiService.getFavorites();
        favorites = favMaps.map((m) => Song.fromJson({...m, 'createdAt': m['createdAt'] ?? DateTime.now().toIso8601String()})).toList();
      } catch (_) {} // Ignore if not logged in
      
      if (mounted) {
        setState(() {
          _songs = songs;
          _favoriteSongs = favorites;
          _onSearch(); // update _filtered based on current tab
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteSong(int id) async {
    try {
      await SongsApiService.deleteSong(id);
      _loadSongs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _openAddSong() async {
    bool isPremium = await AuthApiService.isPremium();
    if (!isPremium) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Преміум функція', style: TextStyle(color: Colors.orangeAccent)),
          content: const Text('Додавання власних пісень доступне лише з Premium підпискою.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
              },
              child: const Text('ПРИДБАТИ', style: TextStyle(color: Colors.orangeAccent))
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ОК', style: TextStyle(color: Colors.greenAccent))
            )
          ],
        )
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddSongScreen()),
    );
    if (result == true) _loadSongs();
  }

  void _openCatalog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CatalogScreen()),
    );
    _loadSongs(); // Оновити список, якщо щось додали
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Назва або виконавець...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              )
            : const Text('ПІСНІ',
                style: TextStyle(
                    letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: !_searchVisible,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.travel_explore, color: Colors.greenAccent),
            tooltip: 'Онлайн каталог',
            onPressed: _openCatalog,
          ),
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search,
                color: Colors.white70),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchCtrl.clear();
                  _onSearch();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'УСІ'),
            Tab(text: 'ОБРАНІ'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSong,
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            const Text('Помилка завантаження',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadSongs,
              child: const Text('Повторити',
                  style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchCtrl.text.isNotEmpty ? Icons.search_off : Icons.music_off,
              color: Colors.white12,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Нічого не знайдено'
                  : 'Ще немає жодної пісні',
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
            if (_searchCtrl.text.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Натисніть + щоб додати першу',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.greenAccent,
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadSongs,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _filtered.length,
        itemBuilder: (context, index) => _buildSongCard(_filtered[index]),
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    final chords = song.chords
        .split(RegExp(r'[\s,]+'))
        .where((c) => c.isNotEmpty)
        .take(4)
        .join(' • ');

    return Dismissible(
      key: Key('song_${song.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => _deleteSong(song.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          onTap: () async {
            final fullSong = await SongsApiService.getSong(song.id);
            if (mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SongDetailScreen(
                          song: fullSong,
                        )),
              );
              _loadSongs(); // refresh favorites status
            }
          },
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: song.audioUrl != null
                ? const Icon(Icons.audiotrack, color: Colors.greenAccent)
                : const Icon(Icons.music_note, color: Colors.greenAccent),
          ),
          title: Text(song.title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.artist,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              if (chords.isNotEmpty)
                Text(chords,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11)),
              if (song.bpm != null)
                Text('♩ ${song.bpm} BPM',
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 10)),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white10),
        ),
      ),
    );
  }
}
