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

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState()) {
    // Simulate finding a partner after 3 seconds for UI demonstration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(isSearching: false, isConnected: true);
        // Add a welcome message from stranger
        addMessage(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Hey there! Nice to connect with you anonymously.',
          isMe: false,
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  void addMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void skipPartner() {
    state = ChatState(isSearching: true, isConnected: false, messages: []);
    // Simulate re-matching after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(isSearching: false, isConnected: true);
        addMessage(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Connected to a new stranger!',
          isMe: false,
          timestamp: DateTime.now(),
        ));
      }
    });
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
