import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back to home',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTokens.peach,
                          AppTokens.blush,
                          AppTokens.lavender,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 52,
                      color: AppTokens.ink,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space24),
                  Text(
                    'Your inbox is waiting',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    'Notifications aren’t available yet. When the inbox is connected, verified updates will appear here.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AppTokens.muted),
                  ),
                  const SizedBox(height: AppTokens.space16),
                  Text(
                    'Private chat messages are never shown in notifications.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
