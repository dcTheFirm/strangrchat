import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/socket_client.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    this.imageFile,
    this.imageBytes,
    required this.isMe,
    required this.timestamp,
  });

  final String id;
  final String text;
  final File? imageFile;
  final Uint8List? imageBytes;
  final bool isMe;
  final DateTime timestamp;
}

class ChatState {
  const ChatState({
    this.isSearching = false,
    this.isConnected = false,
    this.messages = const [],
  });

  final bool isSearching;
  final bool isConnected;
  final List<ChatMessage> messages;

  ChatState copyWith({
    bool? isSearching,
    bool? isConnected,
    List<ChatMessage>? messages,
  }) {
    return ChatState(
      isSearching: isSearching ?? this.isSearching,
      isConnected: isConnected ?? this.isConnected,
      messages: messages ?? this.messages,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late final SocketClient _socketClient;
  String? _roomId;
  Map<String, String>? _lastQueueFilters;

  @override
  ChatState build() {
    _socketClient = ref.read(socketClientProvider);
    return const ChatState();
  }

  Future<void> joinQueue({
    required String intent,
    required String preferredGender,
    required String city,
  }) async {
    _lastQueueFilters = {
      'intent': intent,
      'preferredGender': preferredGender,
      'city': city,
    };
    _roomId = null;
    state = const ChatState(isSearching: true);

    try {
      final socket = await _socketClient.connect();
      _registerSocketListeners(socket);
      // The app does not collect a user's own gender yet, so matching remains
      // anonymous/random while preferredGender is a validated VIP filter.
      socket.emit('join_queue', {
        'intent': intent,
        'gender': 'ANY',
        'preferredGender': preferredGender,
        'city': city,
      });
    } catch (_) {
      state = const ChatState();
      rethrow;
    }
  }

  void _registerSocketListeners(dynamic socket) {
    socket
      ..off('match_found')
      ..on('match_found', _onMatchFound)
      ..off('waiting')
      ..on('waiting', (_) => state = const ChatState(isSearching: true))
      ..off('chat_message')
      ..on('chat_message', _onIncomingMessage)
      ..off('chat_image')
      ..on('chat_image', _onIncomingImage)
      ..off('partner_left')
      ..on('partner_left', (_) => _resetAfterPartnerLeft());
  }

  void _onMatchFound(dynamic data) {
    final payload = _asMap(data);
    final roomId = payload['roomId'];
    if (roomId is! String || roomId.isEmpty) return;

    _roomId = roomId;
    _socketClient.emit('join_room', {'roomId': roomId});
    state = const ChatState(isConnected: true);
  }

  void _onIncomingMessage(dynamic data) {
    final payload = _asMap(data);
    final text = payload['message'];
    if (text is! String || text.isEmpty) return;
    addMessage(ChatMessage(
      id: 'remote-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      isMe: false,
      timestamp: _timestampFrom(payload['timestamp']),
    ));
  }

  void _onIncomingImage(dynamic data) {
    final payload = _asMap(data);
    final encodedImage = payload['image'];
    if (encodedImage is! String || encodedImage.isEmpty) return;
    try {
      addMessage(ChatMessage(
        id: 'remote-image-${DateTime.now().microsecondsSinceEpoch}',
        text: '',
        imageBytes: base64Decode(encodedImage),
        isMe: false,
        timestamp: _timestampFrom(payload['timestamp']),
      ));
    } on FormatException {
      // Ignore malformed image payloads rather than writing them anywhere.
    }
  }

  void addMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void sendText(String text) {
    final message = text.trim();
    if (message.isEmpty || _roomId == null || !state.isConnected) return;
    addMessage(ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      text: message,
      isMe: true,
      timestamp: DateTime.now(),
    ));
    _socketClient.emit('chat_message', {'roomId': _roomId, 'message': message});
  }

  void sendImage(File imageFile, Uint8List imageBytes) {
    if (_roomId == null || !state.isConnected) return;
    addMessage(ChatMessage(
      id: 'local-image-${DateTime.now().microsecondsSinceEpoch}',
      text: '',
      imageFile: imageFile,
      isMe: true,
      timestamp: DateTime.now(),
    ));
    _socketClient.emit('chat_image', {
      'roomId': _roomId,
      'image': base64Encode(imageBytes),
    });
  }

  Future<void> skipPartner() async {
    if (_roomId != null) _socketClient.emit('leave_chat', {'roomId': _roomId});
    _roomId = null;
    final filters = _lastQueueFilters;
    if (filters == null) {
      state = const ChatState();
      return;
    }
    await joinQueue(
      intent: filters['intent']!,
      preferredGender: filters['preferredGender']!,
      city: filters['city']!,
    );
  }

  void _resetAfterPartnerLeft() {
    _roomId = null;
    state = const ChatState();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  DateTime _timestampFrom(dynamic value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    return DateTime.now();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
