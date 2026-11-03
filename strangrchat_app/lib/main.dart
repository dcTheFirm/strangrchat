import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';
import 'app/theme.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce FLAG_SECURE globally to block screenshots and screen recordings on Android
  try {
    await ScreenProtector.preventScreenshotOn();
  } catch (e) {
    debugPrint('Screenshot protection could not be set: $e');
  }

  runApp(const ProviderScope(child: StrangrChatApp()));
}

class StrangrChatApp extends StatelessWidget {
  const StrangrChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StrangrChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}