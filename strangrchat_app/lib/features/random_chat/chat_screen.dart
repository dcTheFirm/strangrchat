import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../core/safety/image_guard.dart';
import '../../core/safety/profanity_filter.dart';
import 'chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (ProfanityFilter.hasProfanity(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warning: Inappropriate or abusive language is prohibited.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ref.read(chatProvider.notifier).addMessage(ChatMessage(
  Future<void> _pickAndSendImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final originalFile = File(pickedFile.path);
      final compressedFile = await ImageGuard.compressImage(originalFile);
      if (compressedFile == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image.')),
        );
        return;
      }

      final isSafe = await ImageGuard.isImageSafe(compressedFile);
      if (!isSafe) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image flagged as inappropriate and blocked.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      ref.read(chatProvider.notifier).addMessage(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '',
            imageFile: compressedFile,
            isMe: true,
            timestamp: DateTime.now(),
          ));

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Stranger'),
        content: const Text(
          'Are you sure you want to report this user for violating community guidelines?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider.notifier).skipPartner();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted. User blocked and partner skipped.'),
                  backgroundColor: AppTheme.primaryCoral,
                ),
              );
            },
            child: const Text('Report & Block'),
          ),
        ],
      ),
    );
  }

          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isMe: true,
          timestamp: DateTime.now(),
        ));

    _textController.clear();
    _scrollToBottom();
  }
}
