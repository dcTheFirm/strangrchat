import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String id;
  final String text;
  final File? imageFile;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    this.imageFile,
    required this.isMe,
    required this.timestamp,
  });
}

class ChatState {
  final bool isSearching;
  final bool isConnected;
  final List<ChatMessage> messages;

  ChatState({
    this.isSearching = true,
    this.isConnected = false,
    this.messages = const [],
  });

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
  @override
  ChatState build() {
    // Simulate finding a partner after 3 seconds for UI demonstration
    Future.delayed(const Duration(seconds: 3), () {
      state = state.copyWith(isSearching: false, isConnected: true);
      addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Hey there! Nice to connect with you anonymously.',
        isMe: false,
        timestamp: DateTime.now(),
      ));
    });
    return ChatState();
  }

  void addMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void skipPartner() {
    state = ChatState(isSearching: true, isConnected: false, messages: []);
    Future.delayed(const Duration(seconds: 3), () {
      state = state.copyWith(isSearching: false, isConnected: true);
      addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Connected to a new stranger!',
        isMe: false,
        timestamp: DateTime.now(),
      ));
    });
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

