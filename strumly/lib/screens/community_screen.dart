import 'package:flutter/material.dart';
import '../services/friends_api_service.dart';
import '../services/auth_api_service.dart';
import '../services/socket_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'other_user_profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _friendsLoading = true;
  bool _requestsLoading = true;
  bool _isAuthenticated = false;

  // Search
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAuthAndLoad();
    SocketService.instance.setUnreadListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoad() async {
    final auth = await AuthApiService.isAuthenticated();
    if (!auth) {
      if (!mounted) return;
      setState(() => _isAuthenticated = false);
      return;
    }
    setState(() => _isAuthenticated = true);
    _loadFriends();
    _loadRequests();
  }

  Future<void> _loadFriends() async {
    setState(() => _friendsLoading = true);
    try {
      final friends = await FriendsApiService.getFriends();
      if (mounted) setState(() => _friends = friends);
    } catch (_) {} finally {
      if (mounted) setState(() => _friendsLoading = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _requestsLoading = true);
    try {
      final reqs = await FriendsApiService.getRequests();
      if (mounted) setState(() => _requests = reqs);
    } catch (_) {} finally {
      if (mounted) setState(() => _requestsLoading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await FriendsApiService.searchUsers(query.trim());
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest(String email) async {
    try {
      await FriendsApiService.sendRequest(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запит надіслано!'),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _searchResults = [];
          _searchCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _acceptRequest(int friendshipId) async {
    try {
      await FriendsApiService.acceptRequest(friendshipId);
      _loadFriends();
      _loadRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(int friendshipId) async {
    try {
      await FriendsApiService.rejectOrRemove(friendshipId);
      _loadRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }

  void _showAddFriendDialog() {
    _searchCtrl.clear();
    _searchResults = [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Знайти друга',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Пошук за email або іменем',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Введіть email або ім\'я...',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (val) async {
                      await _searchUsers(val);
                      setModalState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Search results
                if (_searching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(
                          color: Colors.greenAccent, strokeWidth: 2),
                    ),
                  )
                else if (_searchResults.isNotEmpty)
                  ...(_searchResults.map((user) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.greenAccent.withOpacity(0.15),
                          backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                          child: user['avatarUrl'] == null ? Text(
                            (user['name'] as String? ?? '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold),
                          ) : null,
                        ),
                        title: Text(user['name'] as String? ?? '',
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(user['email'] as String? ?? '',
                            style:
                                const TextStyle(color: Colors.white38, fontSize: 12)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(80, 34),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _sendRequest(user['email'] as String);
                          },
                          child: const Text('Додати',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OtherUserProfileScreen(
                                userId: user['id'] as int,
                              ),
                            ),
                          );
                        },
                      )))
                else if (_searchCtrl.text.length >= 2)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('Нікого не знайдено',
                          style: TextStyle(color: Colors.white38)),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              const Text('Увійдіть щоб бачити спільноту',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14)),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()))
                      .then((_) => _checkAuthAndLoad());
                },
                child: const Text('Увійти',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text('СПІЛЬНОТА',
            style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: Colors.greenAccent),
            tooltip: 'Додати друга',
            onPressed: _showAddFriendDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(
              text: 'Друзі${_friends.isNotEmpty ? '  ${_friends.length}' : ''}',
            ),
            Tab(
              text:
                  'Запити${_requests.isNotEmpty ? '  ${_requests.length}' : ''}',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_friendsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent));
    }

    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_outlined, color: Colors.white12, size: 72),
            const SizedBox(height: 16),
            const Text('Ще немає друзів',
                style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Натисни + щоб знайти друзів',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.greenAccent),
                foregroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Додати друга'),
              onPressed: _showAddFriendDialog,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.greenAccent,
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _friends.length,
        itemBuilder: (ctx, i) {
          final item = _friends[i];
          final friend = item['friend'] as Map<String, dynamic>;
          final friendshipId = item['friendshipId'] as int;
          final name = friend['name'] as String? ?? '';
          final email = friend['email'] as String? ?? '';
          final avatarUrl = friend['avatarUrl'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtherUserProfileScreen(userId: friend['id'] as int),
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.greenAccent.withOpacity(0.15),
                  backgroundImage: friend['avatarUrl'] != null ? NetworkImage(friend['avatarUrl']) : null,
                  child: friend['avatarUrl'] == null ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ) : null,
                ),
              ),
              title: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtherUserProfileScreen(userId: friend['id'] as int),
                  ),
                ),
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              subtitle: Text(email,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.withOpacity(0.15),
                  foregroundColor: Colors.greenAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: Badge(
                  isLabelVisible: SocketService.instance.unreadCounts[friendshipId] != null && SocketService.instance.unreadCounts[friendshipId]! > 0,
                  label: Text('${SocketService.instance.unreadCounts[friendshipId] ?? 0}'),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.chat_bubble_outline, size: 16),
                ),
                label: const Text('Чат'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      friendshipId: friendshipId,
                      friendName: name,
                      friendAvatarUrl: avatarUrl,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_requestsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent));
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.white12, size: 72),
            SizedBox(height: 16),
            Text('Немає нових запитів',
                style: TextStyle(color: Colors.white38, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.greenAccent,
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (ctx, i) {
          final req = _requests[i];
          final sender = req['sender'] as Map<String, dynamic>;
          final name = sender['name'] as String? ?? '';
          final email = sender['email'] as String? ?? '';
          final friendshipId = req['id'] as int;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtherUserProfileScreen(userId: sender['id'] as int),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blueAccent.withOpacity(0.15),
                    backgroundImage: sender['avatarUrl'] != null ? NetworkImage(sender['avatarUrl']) : null,
                    child: sender['avatarUrl'] == null ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold),
                    ) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtherUserProfileScreen(userId: sender['id'] as int),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(email,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Accept
                GestureDetector(
                  onTap: () => _acceptRequest(friendshipId),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.greenAccent, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Reject
                GestureDetector(
                  onTap: () => _rejectRequest(friendshipId),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.redAccent, size: 20),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
