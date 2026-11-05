import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_protector/screen_protector.dart';

import 'app/theme.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const allowScreenshots = bool.fromEnvironment('ALLOW_SCREENSHOTS');
  if (!kDebugMode || !allowScreenshots) {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (error) {
      debugPrint('Screenshot protection could not be set: $error');
    }
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
