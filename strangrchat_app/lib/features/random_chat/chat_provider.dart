import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/socket_client.dart';

enum ChatPhase { idle, searching, connected, ended, error }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
}

class ChatState {
  const ChatState({
    this.phase = ChatPhase.idle,
    this.errorMessage,
    this.messages = const [],
    this.partnerId,
  });

  final ChatPhase phase;
  final String? errorMessage;
  final List<ChatMessage> messages;
  final String? partnerId;

  bool get isSearching => phase == ChatPhase.searching;
  bool get isConnected => phase == ChatPhase.connected;

  ChatState withMessage(ChatMessage message) => ChatState(
    phase: phase,
    errorMessage: null,
    messages: [...messages, message],
    partnerId: partnerId,
  );
}

class ChatNotifier extends Notifier<ChatState> {
  late final SocketClient _socketClient;
  String? _roomId;
  String? _lastIntent;

  @override
  ChatState build() {
    _socketClient = ref.read(socketClientProvider);
    return const ChatState();
  }

  Future<void> joinQueue({required String intent}) async {
    _lastIntent = intent;
    _roomId = null;
    state = const ChatState(phase: ChatPhase.searching);

    try {
      final socket = await _socketClient.connect();
      _registerSocketListeners(socket);
      socket.emit('join_queue', {
        'intent': intent,
        'gender': 'ANY',
        'preferredGender': 'ANY',
      });
    } catch (error) {
      state = const ChatState(
        phase: ChatPhase.error,
        errorMessage:
            'Could not start matching. Check your connection and try again.',
      );
      debugPrint('Matching connection failed: $error');
    }
  }

  void _registerSocketListeners(dynamic socket) {
    socket
      ..off('match_found')
      ..on('match_found', _onMatchFound)
      ..off('disconnect')
      ..on('disconnect', (_) {
        _roomId = null;
        if (state.isConnected) {
          state = const ChatState(
            phase: ChatPhase.ended,
            errorMessage: 'Connection lost. This private chat has ended.',
          );
        } else if (state.isSearching) {
          state = const ChatState(
            phase: ChatPhase.error,
            errorMessage: 'Connection lost while finding a chat.',
          );
        }
      })
      ..off('operation_error')
      ..on('operation_error', (data) {
        final payload = _asMap(data);
        final message = payload['message'];
        final operation = payload['operation'];
        state = ChatState(
          phase: operation == 'chat_message' && state.isConnected
              ? ChatPhase.connected
              : ChatPhase.error,
          errorMessage: message is String
              ? message
              : 'That action could not be completed.',
          messages: state.messages,
          partnerId: state.partnerId,
        );
      })
      ..off('waiting')
      ..on(
        'waiting',
        (_) => state = const ChatState(phase: ChatPhase.searching),
      )
      ..off('chat_message')
      ..on('chat_message', _onIncomingMessage)
      ..off('partner_left')
      ..on('partner_left', (_) => _resetAfterPartnerLeft());
  }

  void _onMatchFound(dynamic data) {
    final payload = _asMap(data);
    final roomId = payload['roomId'];
    if (roomId is! String || roomId.isEmpty) return;

    _roomId = roomId;
    _socketClient.emit('join_room', {'roomId': roomId});
    final partnerId = payload['partnerId'];
    state = ChatState(
      phase: ChatPhase.connected,
      partnerId: partnerId is String ? partnerId : null,
    );
  }

  void _onIncomingMessage(dynamic data) {
    final payload = _asMap(data);
    final text = payload['message'];
    if (text is! String || text.isEmpty || !state.isConnected) return;
    _addMessage(
      ChatMessage(
        id: 'remote-${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        isMe: false,
        timestamp: _timestampFrom(payload['timestamp']),
      ),
    );
  }

  void _addMessage(ChatMessage message) {
    state = state.withMessage(message);
  }

  void sendText(String text) {
    final message = text.trim();
    if (message.isEmpty || _roomId == null || !state.isConnected) return;
    _addMessage(
      ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        text: message,
        isMe: true,
        timestamp: DateTime.now(),
      ),
    );
    _socketClient.emit('chat_message', {'roomId': _roomId, 'message': message});
  }

  void clearTransientError() {
    if (state.errorMessage == null) return;
    state = ChatState(
      phase: state.phase,
      messages: state.messages,
      partnerId: state.partnerId,
    );
  }

  Future<void> skipPartner() async {
    if (_roomId != null) {
      _socketClient.emit('leave_chat', {'roomId': _roomId});
    }
    _roomId = null;
    final intent = _lastIntent;
    if (intent == null) {
      state = const ChatState(phase: ChatPhase.ended);
      return;
    }
    await joinQueue(intent: intent);
  }

  void leaveChat() {
    if (_roomId != null) {
      _socketClient.emit('leave_chat', {'roomId': _roomId});
    }
    _roomId = null;
    state = const ChatState(phase: ChatPhase.ended);
  }

  void _resetAfterPartnerLeft() {
    _roomId = null;
    state = const ChatState(phase: ChatPhase.ended);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  DateTime _timestampFrom(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
