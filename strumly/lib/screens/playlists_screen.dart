import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/playlists_api_service.dart';
import '../models/song.dart';
import 'song_detail_screen.dart';
import '../services/friends_api_service.dart';
import '../services/socket_service.dart';
import '../services/auth_api_service.dart';
import '../services/jam_session_service.dart';
import 'jam_session_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Map<String, dynamic>> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await PlaylistsApiService.getPlaylists();
      if (mounted) setState(() => _playlists = data);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPlaylist() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Новий плейліст', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Назва плейліста',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Створити', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await PlaylistsApiService.createPlaylist(result);
        _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _deletePlaylist(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Видалити плейліст?', style: TextStyle(color: Colors.white)),
        content: Text('«$title» буде видалено назавжди.', style: const TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Видалити', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await PlaylistsApiService.deletePlaylist(id);
      _load();
    }
  }

  void _openPlaylist(Map<String, dynamic> playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)),
    ).then((_) => _load());
  }

  Future<void> _showJamBottomSheet(Map<String, dynamic> playlist) async {
    final auth = await AuthApiService.isAuthenticated();
    if (!auth) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Увійдіть, щоб створити Jam Session')));
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: FriendsApiService.getFriends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.greenAccent)));
                }
                final friends = snapshot.data ?? [];
                
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Jam Session (Плейліст)', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Оберіть друзів для запрошення', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      if (friends.isEmpty)
                         const Text('У вас ще немає друзів', style: TextStyle(color: Colors.white38))
                      else
                         ConstrainedBox(
                           constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                           child: ListView.builder(
                             shrinkWrap: true,
                             itemCount: friends.length,
                             itemBuilder: (context, index) {
                               final friend = friends[index]['friend'];
                               return ListTile(
                                 leading: CircleAvatar(
                                   backgroundColor: Colors.greenAccent.withOpacity(0.2),
                                   child: const Icon(Icons.person, color: Colors.greenAccent),
                                 ),
                                 title: Text(friend['name'] ?? '', style: const TextStyle(color: Colors.white)),
                                 trailing: ElevatedButton(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                                   onPressed: () => _createAndInvite(friends[index]['id'] as int, playlist, ctx),
                                   child: const Text('Запросити'),
                                 ),
                               );
                             },
                           ),
                         ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white10,
                           foregroundColor: Colors.white,
                           minimumSize: const Size(double.infinity, 48),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         onPressed: () => _createWithoutInvite(playlist, ctx),
                         child: const Text('Створити без запрошень (тільки за кодом)'),
                      )
                    ],
                  ),
                );
              }
            );
          }
        );
      }
    );
  }

  void _createAndInvite(int friendshipId, Map<String, dynamic> playlist, BuildContext modalContext) async {
    Navigator.pop(modalContext);
    
    // 1. Fetch playlist songs
    final songs = await PlaylistsApiService.getPlaylistSongs(playlist['id']);
    if (songs.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Плейліст порожній!')));
      return;
    }

    try {
      // Ensure chat socket is connected first
      await SocketService.instance.connect();
      await JamSessionService.instance.connect();

      JamSessionService.instance.onSessionCreated((sessionCode) {
        JamSessionService.instance.offAll();
        
        SocketService.instance.sendMessage(
          friendshipId,
          '[JAM_INVITE]$sessionCode'
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JamSessionScreen(sessionCode: sessionCode, isHost: true),
            ),
          );
        }
      });
      JamSessionService.instance.createSession(
        playlistId: playlist['id'],
        playlistSongs: songs,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _createWithoutInvite(Map<String, dynamic> playlist, BuildContext modalContext) async {
    Navigator.pop(modalContext);
    
    // 1. Fetch playlist songs
    final songs = await PlaylistsApiService.getPlaylistSongs(playlist['id']);
    if (songs.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Плейліст порожній!')));
      return;
    }

    JamSessionService.instance.connect().then((_) {
      JamSessionService.instance.onSessionCreated((sessionCode) {
        JamSessionService.instance.offAll();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JamSessionScreen(sessionCode: sessionCode, isHost: true),
            ),
          );
        }
      });
      JamSessionService.instance.createSession(
        playlistId: playlist['id'],
        playlistSongs: songs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Мої плейлісти', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.greenAccent),
            onPressed: _createPlaylist,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : _playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.queue_music, color: Colors.white12, size: 72),
                      const SizedBox(height: 16),
                      const Text('Немає плейлістів', style: TextStyle(color: Colors.white38, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _createPlaylist,
                        icon: const Icon(Icons.add, color: Colors.greenAccent),
                        label: const Text('Створити перший', style: TextStyle(color: Colors.greenAccent)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.greenAccent,
                  backgroundColor: const Color(0xFF1A1A1A),
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _playlists.length,
                    itemBuilder: (ctx, i) {
                      final pl = _playlists[i];
                      final songCount = (pl['songs'] as List?)?.length ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.15)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.queue_music, color: Colors.greenAccent),
                          ),
                          title: Text(pl['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('$songCount ${_songWord(songCount)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.playlist_play, color: Colors.orangeAccent),
                                onPressed: () => _showJamBottomSheet(pl),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.white24),
                                onPressed: () => _deletePlaylist(pl['id'], pl['title'] ?? ''),
                              ),
                            ],
                          ),
                          onTap: () => _openPlaylist(pl),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _songWord(int count) {
    if (count == 1) return 'пісня';
    if (count >= 2 && count <= 4) return 'пісні';
    return 'пісень';
  }
}

// ─────────────────────────────────────────────
// Playlist detail — shows songs in order with prev/next navigation
// ─────────────────────────────────────────────
class PlaylistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Map<String, dynamic>> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final songs = await PlaylistsApiService.getPlaylistSongs(widget.playlist['id']);
      if (mounted) setState(() => _songs = songs);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSong(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongDetailScreen(
          song: Song.fromJson(_songs[index]),
          playlist: _songs,
          playlistIndex: index,
        ),
      ),
    ).then((_) => _load());
  }

  Future<void> _removeSong(int songId) async {
    await PlaylistsApiService.removeSong(widget.playlist['id'], songId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(widget.playlist['title'] ?? 'Плейліст', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : _songs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_off, color: Colors.white12, size: 64),
                      SizedBox(height: 16),
                      Text('Плейліст порожній', style: TextStyle(color: Colors.white38)),
                      SizedBox(height: 8),
                      Text('Додай пісні з екрану пісні', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _songs.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _songs.removeAt(oldIndex);
                      _songs.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (ctx, i) {
                    final song = _songs[i];
                    return Container(
                      key: ValueKey(song['id']),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        title: Text(song['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(song['artist'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                              onPressed: () => _removeSong(song['id']),
                            ),
                            const Icon(Icons.drag_handle, color: Colors.white24),
                          ],
                        ),
                        onTap: () => _openSong(i),
                      ),
                    );
                  },
                ),
    );
  }
}
