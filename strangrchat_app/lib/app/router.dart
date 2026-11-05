import 'package:go_router/go_router.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/profile_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/friends/friend_chat_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/random_chat/chat_screen.dart';
import '../features/vip/vip_paywall_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      name: 'profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/friends/:friendId',
      name: 'friend-chat',
      builder: (context, state) => FriendChatScreen(
        friendId: state.pathParameters['friendId']!,
        friendName: state.extra is String ? state.extra! as String : 'Friend',
      ),
    ),
    GoRoute(
      path: '/vip',
      name: 'vip',
      builder: (context, state) => const VipPaywallScreen(),
    ),
  ],
);
