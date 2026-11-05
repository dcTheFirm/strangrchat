import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/sticker_avatar.dart';
import '../../app/tokens.dart';
import '../../core/network/friend_service.dart';
import '../../core/safety/profanity_filter.dart';
import '../home/match_filter_provider.dart';
import 'chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _leaveConfirmationTimer;
  bool _confirmingLeave = false;

  @override
  void dispose() {
    _leaveConfirmationTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppTokens.base,
          curve: AppTokens.enter,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (ProfanityFilter.hasProfanity(text)) {
      _showNotice('Please keep the conversation respectful.');
      return;
    }

    ref.read(chatProvider.notifier).sendText(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _requestNext() {
    if (!_confirmingLeave) {
      setState(() => _confirmingLeave = true);
      _leaveConfirmationTimer?.cancel();
      _leaveConfirmationTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _confirmingLeave = false);
      });
      return;
    }

    _leaveConfirmationTimer?.cancel();
    setState(() => _confirmingLeave = false);
    unawaited(ref.read(chatProvider.notifier).skipPartner());
  }

  void _showSafetySheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Your comfort comes first',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what feels right. A report is sent to StrangrChat; blocking prevents future matches.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (ref.read(chatProvider).partnerId
                case final String partnerId) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_reportPartner(partnerId));
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report this person'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_blockPartner(partnerId));
                  },
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('Block and leave'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _reportPartner(String partnerId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Why are you reporting?'),
        children: [
          for (final reason in [
            'Inappropriate behavior',
            'Harassment',
            'Spam or scam',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, reason),
              child: Text(reason),
            ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(friendServiceProvider).report(partnerId, reason);
      if (mounted) {
        _showNotice('Report sent. Thank you for helping keep chat safe.');
      }
    } catch (_) {
      if (mounted) _showNotice('Report could not be sent. Please try again.');
    }
  }

  Future<void> _blockPartner(String partnerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this person?'),
        content: const Text(
          'They will no longer be eligible to match with you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(friendServiceProvider).block(partnerId);
      if (!mounted) return;
      _showNotice('Person blocked.');
      await ref.read(chatProvider.notifier).skipPartner();
    } catch (_) {
      if (mounted) {
        _showNotice('Could not block this person. Please try again.');
      }
    }
  }

  Future<void> _sendFriendRequest(String partnerId) async {
    try {
      await ref.read(friendServiceProvider).sendRequest(partnerId);
      if (mounted) {
        ref.invalidate(friendsProvider);
        _showNotice('Friend request sent.');
      }
    } catch (_) {
      if (mounted) {
        _showNotice('Request could not be sent. It may already be pending.');
      }
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isConnected = chatState.phase == ChatPhase.connected;
    final isSearching = chatState.phase == ChatPhase.searching;
    final title = switch (chatState.phase) {
      ChatPhase.connected => 'Stranger',
      ChatPhase.searching => 'Finding someone',
      ChatPhase.ended => 'Chat ended',
      ChatPhase.error => 'Connection issue',
      ChatPhase.idle => 'Your chat',
    };

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            const StickerAvatar(
              variant: 1,
              size: 40,
              semanticLabel: 'StrangrChat sticker artwork',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    isConnected
                        ? 'Connected'
                        : isSearching
                        ? 'Matching in progress'
                        : 'Anonymous conversations',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isConnected && chatState.partnerId != null)
            IconButton(
              tooltip: 'Send friend request',
              onPressed: () =>
                  unawaited(_sendFriendRequest(chatState.partnerId!)),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              color: AppTokens.coralDeep,
            ),
          IconButton(
            tooltip: 'Safety options',
            onPressed: isConnected ? _showSafetySheet : null,
            icon: const Icon(Icons.shield_outlined),
            color: AppTokens.coralDeep,
          ),
          if (isConnected)
            Semantics(
              button: true,
              label: _confirmingLeave ? 'Tap again to leave chat' : 'Next chat',
              child: IconButton(
                tooltip: _confirmingLeave ? 'Tap again to leave' : 'Next chat',
                onPressed: _requestNext,
                icon: const Icon(Icons.skip_next_rounded),
                color: AppTokens.coralDeep,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: switch (chatState.phase) {
          ChatPhase.searching => const _SearchingView(),
          ChatPhase.connected => _ConversationView(
            messages: chatState.messages,
            errorMessage: chatState.errorMessage,
            onDismissError: () =>
                ref.read(chatProvider.notifier).clearTransientError(),
            scrollController: _scrollController,
            textController: _textController,
            onSend: _sendMessage,
          ),
          ChatPhase.error => _EndedView(
            title: 'Could not connect',
            message:
                chatState.errorMessage ??
                'Matching is temporarily unavailable. Please try again.',
            actionLabel: 'Try again',
            onAction: () => ref
                .read(chatProvider.notifier)
                .joinQueue(intent: ref.read(matchFilterProvider).intent),
          ),
          ChatPhase.ended => _EndedView(
            title: 'This conversation has ended',
            message: 'Your chat content has been cleared from this session.',
            actionLabel: 'Find someone new',
            onAction: () => ref
                .read(chatProvider.notifier)
                .joinQueue(intent: ref.read(matchFilterProvider).intent),
          ),
          ChatPhase.idle => _EndedView(
            title: 'No active chat',
            message: 'Start a new conversation whenever you are ready.',
            actionLabel: 'Find someone',
            onAction: () => ref
                .read(chatProvider.notifier)
                .joinQueue(intent: ref.read(matchFilterProvider).intent),
          ),
        },
      ),
    );
  }
}

class _SearchingView extends StatelessWidget {
  const _SearchingView();

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StickerAvatar(variant: 2, size: 142),
            const SizedBox(height: 20),
            Text(
              'Finding someone new',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your next conversation is just around the corner.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            reduceMotion
                ? const Icon(
                    Icons.more_horiz_rounded,
                    color: AppTokens.coralDeep,
                  )
                : const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTokens.coralDeep,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({
    required this.messages,
    required this.errorMessage,
    required this.onDismissError,
    required this.scrollController,
    required this.textController,
    required this.onSend,
  });

  final List<ChatMessage> messages;
  final String? errorMessage;
  final VoidCallback onDismissError;
  final ScrollController scrollController;
  final TextEditingController textController;
  final VoidCallback onSend;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final Set<String> _seenMessageIds = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.errorMessage != null)
          MaterialBanner(
            content: Text(widget.errorMessage!),
            actions: [
              TextButton(
                onPressed: widget.onDismissError,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StickerAvatar(variant: 0, size: 92),
                        const SizedBox(height: 12),
                        Text(
                          'You’re connected',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Say hello and see where the conversation goes.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) => _ChatBubble(
                    message: widget.messages[index],
                    showTimestamp:
                        index == widget.messages.length - 1 ||
                        widget.messages[index].isMe !=
                            widget.messages[index + 1].isMe,
                    animate: _seenMessageIds.add(widget.messages[index].id),
                  ),
                ),
        ),
        _ChatComposer(controller: widget.textController, onSend: widget.onSend),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.showTimestamp,
    required this.animate,
  });

  final ChatMessage message;
  final bool showTimestamp;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final color = message.isMe ? AppTokens.coralDeep : AppTokens.surfaceHigh;
    final textColor = message.isMe ? Colors.white : AppTokens.ink;
    final time = TimeOfDay.fromDateTime(message.timestamp).format(context);
    final bubble = Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isMe ? 20 : 6),
            bottomRight: Radius.circular(message.isMe ? 6 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 16, height: 1.35),
              ),
            if (showTimestamp) ...[
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  color: message.isMe
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppTokens.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (!animate || MediaQuery.disableAnimationsOf(context)) return bubble;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppTokens.base,
      curve: AppTokens.enter,
      child: bubble,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(
            (message.isMe ? 8 : -8) * (1 - progress),
            6 * (1 - progress),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(top: BorderSide(color: AppTokens.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Write a message',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppTokens.surfaceHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTokens.outlineStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTokens.coralDeep),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final enabled = value.text.trim().isNotEmpty;
              return Material(
                color: enabled ? AppTokens.coralDeep : AppTokens.line,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Send message',
                  onPressed: enabled ? onSend : null,
                  color: enabled ? Colors.white : AppTokens.muted,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EndedView extends StatelessWidget {
  const _EndedView({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StickerAvatar(variant: 3, size: 120),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.favorite_rounded),
              label: Text(actionLabel),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to discovery'),
            ),
          ],
        ),
      ),
    );
  }
}
