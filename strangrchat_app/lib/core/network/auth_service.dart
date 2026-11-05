import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class AnonymousSession {
  const AnonymousSession({required this.token, required this.deviceId});

  final String token;
  final String deviceId;
}

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<bool> hasCompletedProfile() =>
      _apiClient.sessionStorage.hasCompletedProfile();

  Future<AnonymousSession> completeProfile({
    required String name,
    required int age,
    required String country,
    required String captchaToken,
    String? city,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/anonymous',
      data: {
        'deviceId': deviceId,
        'name': name.trim(),
        'age': age,
        'country': country.trim(),
        'city': city?.trim().isNotEmpty == true ? city!.trim() : null,
        'captchaToken': captchaToken,
      },
    );
    final token = response.data?['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException(
        'Profile response did not include a JWT token.',
      );
    }

    await _apiClient.sessionStorage.saveToken(token);
    await _apiClient.sessionStorage.markProfileComplete();
    return AnonymousSession(token: token, deviceId: deviceId);
  }

  /// Reuses a secured session. New identities are only created after profile
  /// setup and server-verified CAPTCHA completion.
  Future<AnonymousSession> ensureAnonymousSession() async {
    final deviceId = await _getOrCreateDeviceId();
    final existingToken = await _apiClient.sessionStorage.readToken();
    if (existingToken != null && existingToken.isNotEmpty) {
      return AnonymousSession(token: existingToken, deviceId: deviceId);
    }
    throw StateError('Complete profile setup before starting a chat.');
  }

  Future<String> _getOrCreateDeviceId() async {
    final stored = await _apiClient.sessionStorage.readDeviceId();
    if (stored != null && stored.isNotEmpty) return stored;

    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final entropy = List<String>.generate(
      4,
      (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'),
    ).join();
    final deviceId = 'anon-$timestamp-$entropy';
    await _apiClient.sessionStorage.saveDeviceId(deviceId);
    return deviceId;
  }
}

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorage(),
);
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(sessionStorage: ref.watch(sessionStorageProvider)),
);
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(apiClient: ref.watch(apiClientProvider)),
);
