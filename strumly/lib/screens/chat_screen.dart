import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/friends_api_service.dart';
import '../services/socket_service.dart';
import '../services/auth_api_service.dart';
import '../services/jam_session_service.dart';
import 'jam_session_screen.dart';

class ChatScreen extends StatefulWidget {
  final int friendshipId;
  final String friendName;

  const ChatScreen({
    super.key,
    required this.friendshipId,
    required this.friendName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _friendTyping = false;
  int? _myUserId;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Get my user id
    final token = await AuthApiService.getToken();
    if (token != null) {
      // Decode JWT payload to get user id
      final parts = token.split('.');
      if (parts.length == 3) {
        try {
          final payloadStr = utf8.decode(base64Url.decode(base64Pad(parts[1])));
          final payload = jsonDecode(payloadStr);
          _myUserId = payload['sub'] as int?;
        } catch (_) {}
      }
    }

    // Load history
    await _loadMessages();

    // Connect WebSocket
    await SocketService.instance.connect();
    SocketService.instance.joinRoom(widget.friendshipId);

    // Listen for new messages
    SocketService.instance.onNewMessage((msg) {
      if (msg['friendshipId'] == widget.friendshipId) {
        if (mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      }
    });

    // Typing indicator
    SocketService.instance.onUserTyping((data) {
      if (mounted) {
        setState(() => _friendTyping = data['isTyping'] == true);
      }
    });
  }

  String base64Pad(String str) {
    switch (str.length % 4) {
      case 2:
        return '$str==';
      case 3:
        return '$str=';
      default:
        return str;
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs =
          await FriendsApiService.getMessages(widget.friendshipId);
      if (mounted) {
        setState(() => _messages
          ..clear()
          ..addAll(msgs));
        _isLoading = false;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTyping(String value) {
    SocketService.instance.sendTyping(widget.friendshipId, value.isNotEmpty);
    _typingTimer?.cancel();
    if (value.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        SocketService.instance.sendTyping(widget.friendshipId, false);
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageCtrl.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageCtrl.clear();

    try {
      SocketService.instance.sendMessage(widget.friendshipId, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }



  @override
  void dispose() {
    _typingTimer?.cancel();
    SocketService.instance.offNewMessage();
    SocketService.instance.offUserTyping();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151515),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.greenAccent.withOpacity(0.2),
              child: Text(
                widget.friendName.isNotEmpty
                    ? widget.friendName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.friendName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _friendTyping
                      ? const Text(
                          'друкує...',
                          key: ValueKey('typing'),
                          style:
                              TextStyle(color: Colors.greenAccent, fontSize: 11),
                        )
                      : const Text(
                          'онлайн',
                          key: ValueKey('online'),
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub, color: Colors.orangeAccent),
            tooltip: 'Приєднатись до Jam Session',
            onPressed: () {
              final ctrl = TextEditingController();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text('Приєднатись до Jam', style: TextStyle(color: Colors.white)),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Код сесії (напр. X7B9M)',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати', style: TextStyle(color: Colors.white54))),
                    TextButton(
                      onPressed: () {
                        if (ctrl.text.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => JamSessionScreen(sessionCode: ctrl.text.trim().toUpperCase(), isHost: false)));
                        }
                      },
                      child: const Text('Вхід', style: TextStyle(color: Colors.orangeAccent)),
                    ),
                  ],
                )
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.greenAccent))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                color: Colors.white12, size: 64),
                            const SizedBox(height: 16),
                            const Text('Почни розмову!',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) =>
                            _buildMessageBubble(_messages[i]),
                      ),
          ),

          // Input area
          Container(
            color: const Color(0xFF151515),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SafeArea(
              top: false,
              child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: TextField(
                      controller: _messageCtrl,
                      onChanged: _onTyping,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Написати повідомлення...',
                        hintStyle:
                            TextStyle(color: Colors.white24, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF69FF81), Color(0xFF00E676)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final senderId = msg['senderId'] as int?;
    final isMe = senderId == _myUserId;
    final content = msg['content'] as String? ?? '';
    final senderName = msg['senderName'] as String? ??
        msg['sender']?['name'] as String? ??
        '';
    final createdAt = msg['createdAt'] != null
        ? DateTime.tryParse(msg['createdAt'] as String)
        : null;
    final timeStr = createdAt != null
        ? DateFormat('HH:mm').format(createdAt.toLocal())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.greenAccent.withOpacity(0.15),
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.greenAccent.withOpacity(0.85)
                    : const Color(0xFF252525),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (content.startsWith('[JAM_INVITE]')) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, color: isMe ? Colors.black54 : Colors.greenAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Запрошення в Jam Session',
                          style: TextStyle(
                              color: isMe ? Colors.black87 : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Код: ${content.replaceFirst('[JAM_INVITE]', '')}',
                      style: TextStyle(
                          color: isMe ? Colors.black87 : Colors.white,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMe ? Colors.black.withOpacity(0.1) : Colors.greenAccent,
                        foregroundColor: isMe ? Colors.black : Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JamSessionScreen(
                              sessionCode: content.replaceFirst('[JAM_INVITE]', ''),
                              isHost: false,
                            ),
                          ),
                        );
                      },
                      child: const Text('Приєднатись'),
                    ),
                  ] else
                    Text(
                      content,
                      style: TextStyle(
                          color: isMe ? Colors.black87 : Colors.white,
                          fontSize: 14,
                          height: 1.4),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                        color: isMe
                            ? Colors.black38
                            : Colors.white24,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
