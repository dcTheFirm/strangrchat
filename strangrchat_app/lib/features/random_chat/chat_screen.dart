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

    ref.read(chatProvider.notifier).sendText(text);

    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final originalFile = File(pickedFile.path);
      final compressedFile = await ImageGuard.compressImage(originalFile);
      if (compressedFile == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to compress image.')),
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

      final imageBytes = await compressedFile.readAsBytes();
      ref.read(chatProvider.notifier).sendImage(compressedFile, imageBytes);

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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
            child: const Text('Report & Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Stranger'),
        content: const Text('Are you sure you want to block this user? You will not be matched again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider.notifier).skipPartner();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User blocked. Finding a new partner...'),
                  backgroundColor: AppTheme.primaryCoral,
                ),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chatState.isConnected ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              chatState.isConnected ? 'Stranger' : 'Searching...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryCoral),
            tooltip: 'Add Friend',
            onPressed: chatState.isConnected
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Friend request sent to partner!'),
                        backgroundColor: AppTheme.primaryCoral,
                      ),
                    );
                  }
                : null,
          ),
          TextButton.icon(
            onPressed: () => ref.read(chatProvider.notifier).skipPartner(),
            icon: const Icon(Icons.skip_next_rounded, color: AppTheme.deepPlum),
            label: const Text(
              'Skip',
              style: TextStyle(color: AppTheme.deepPlum, fontWeight: FontWeight.bold),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.mainText),
            onSelected: (val) {
              if (val == 'report') {
                _showReportDialog();
              } else if (val == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Report User', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: AppTheme.mainText, size: 20),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: chatState.isSearching
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppTheme.softBlush,
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: AppTheme.primaryCoral,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Searching for a stranger...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.mainText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Matching based on your selected filters & interests',
                      style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
                  ),
                  _buildInputBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primaryCoral : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          border: msg.isMe ? null : Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.imageFile != null || msg.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: msg.imageFile != null
                    ? Image.file(
                        msg.imageFile!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Image.memory(
                        msg.imageBytes!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              if (msg.text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(
                  color: msg.isMe ? Colors.white : AppTheme.mainText,
                  fontSize: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: AppTheme.primaryCoral),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: AppTheme.secondaryText),
                filled: true,
                fillColor: AppTheme.warmIvory,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryCoral,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
