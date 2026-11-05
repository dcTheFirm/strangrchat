import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/sticker_avatar.dart';
import '../../app/tokens.dart';
import '../../core/network/socket_client.dart';
import '../../core/safety/profanity_filter.dart';

class _FriendMessage {
  const _FriendMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final DateTime time;
}

class FriendChatScreen extends ConsumerStatefulWidget {
  const FriendChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  final String friendId;
  final String friendName;

  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final _controller = TextEditingController();
  final _messages = <_FriendMessage>[];
  SocketClient? _socketClient;
  bool _isConnected = false;
  bool _isJoined = false;
  bool _sending = false;
  bool _listenersRegistered = false;
  String? _errorMessage;
  Timer? _sendTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      final socketClient = ref.read(socketClientProvider);
      _socketClient = socketClient;
      final socket = await socketClient.connect();
      if (!_listenersRegistered) {
        socketClient.on('connect', _handleReconnect);
        socketClient.on('disconnect', _handleDisconnect);
        socketClient.on('friend_joined', _handleJoined);
        socketClient.on('friend_message', _onMessage);
        socketClient.on('operation_error', _handleOperationError);
        _listenersRegistered = true;
      }
      if (socket.connected) {
        _isConnected = true;
        socketClient.emit('friend_join', {'friendId': widget.friendId});
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not connect. Check your connection and retry.';
        });
      }
    }
  }

  void _handleReconnect(dynamic _) {
    _isConnected = true;
    _isJoined = false;
    _socketClient?.emit('friend_join', {'friendId': widget.friendId});
    if (mounted) setState(() {});
  }

  void _handleDisconnect(dynamic _) {
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isJoined = false;
      });
    }
  }

  void _handleJoined(dynamic data) {
    if (data is Map && data['friendId'] == widget.friendId && mounted) {
      setState(() {
        _isJoined = true;
        _errorMessage = null;
      });
    }
  }

  void _handleOperationError(dynamic data) {
    if (!mounted || data is! Map) return;
    final operation = data['operation'];
    if (operation != 'friend_join' && operation != 'friend_message') return;
    final message = data['message'];
    setState(() {
      _errorMessage = message is String ? message : 'Could not open this chat.';
      _isJoined = false;
    });
  }

  void _onMessage(dynamic data) {
    if (data is! Map || data['senderId'] == null || data['senderId'] == '') {
      return;
    }
    final text = data['message'];
    if (text is! String || text.isEmpty || !mounted) return;
    setState(() {
      _messages.add(
        _FriendMessage(
          text: text,
          isMe: false,
          time: _parseTime(data['timestamp']),
        ),
      );
    });
  }

  DateTime _parseTime(dynamic value) => value is String
      ? DateTime.tryParse(value)?.toLocal() ?? DateTime.now()
      : DateTime.now();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isJoined || _sending) return;
    if (text.length > 4000 || ProfanityFilter.hasProfanity(text)) {
      setState(() {
        _errorMessage = text.length > 4000
            ? 'Keep messages under 4,000 characters.'
            : 'Please keep the conversation respectful.';
      });
      return;
    }
    setState(() => _sending = true);
    _sendTimer?.cancel();
    _sendTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errorMessage = 'Message could not be confirmed. Please try again.';
      });
    });
    _socketClient?.emitWithAck(
      'friend_message',
      {'friendId': widget.friendId, 'message': text},
      (response) {
        if (!mounted) return;
        _sendTimer?.cancel();
        setState(() {
          _sending = false;
          if (response is Map && response['ok'] == true) {
            _messages.add(
              _FriendMessage(text: text, isMe: true, time: DateTime.now()),
            );
            if (_controller.text.trim() == text) _controller.clear();
          } else {
            _errorMessage = 'Message could not be sent. Please try again.';
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _socketClient
      ?..off('connect', _handleReconnect)
      ..off('disconnect', _handleDisconnect)
      ..off('friend_joined', _handleJoined)
      ..off('friend_message', _onMessage)
      ..off('operation_error', _handleOperationError);
    _controller.dispose();
    _messages.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTokens.bg,
    appBar: AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          const StickerAvatar(variant: 1, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friendName),
                Text(
                  _isJoined ? 'Friend chat' : 'Connecting…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          if (_errorMessage != null)
            MaterialBanner(
              content: Text(_errorMessage!),
              actions: [
                TextButton(onPressed: _connect, child: const Text('Retry')),
              ],
            ),
          if (!_isConnected && _errorMessage == null)
            const LinearProgressIndicator(),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        _isJoined ? 'Say hello to your friend.' : 'Private chat messages are not saved and will disappear when you leave.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: message.isMe
                                ? AppTokens.coralDeep
                                : AppTokens.surfaceHigh,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.isMe
                                  ? Colors.white
                                  : AppTokens.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: _isJoined,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isJoined && !_sending ? _send : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
