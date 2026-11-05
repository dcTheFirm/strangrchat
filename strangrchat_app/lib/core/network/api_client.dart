import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local development endpoints. Override with a compile-time value, e.g.
/// `--dart-define=API_BASE_URL=http://192.168.1.42:3000` on a physical phone.
class ApiConfig {
  static const chromeLocalhost = 'http://localhost:3000';
  static const androidEmulator = 'http://10.0.2.2:3000';
  static const wifiDeviceExample = 'http://192.168.1.X:3000';

  /// Chrome defaults to localhost. Use API_BASE_URL for Android emulator/Wi-Fi.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: chromeLocalhost,
  );
}

class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'session_jwt';
  static const _deviceIdKey = 'anonymous_device_id';
  static const _profileCompleteKey = 'profile_complete';
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _profileCompleteKey);
  }

  Future<bool> hasCompletedProfile() async =>
      await _storage.read(key: _profileCompleteKey) == 'true';
  Future<void> markProfileComplete() =>
      _storage.write(key: _profileCompleteKey, value: 'true');

  Future<String?> readDeviceId() => _storage.read(key: _deviceIdKey);
  Future<void> saveDeviceId(String deviceId) =>
      _storage.write(key: _deviceIdKey, value: deviceId);
}

class ApiClient {
  ApiClient({Dio? dio, SessionStorage? sessionStorage})
    : sessionStorage = sessionStorage ?? SessionStorage(),
      dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)) {
    this.dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..headers['Content-Type'] = Headers.jsonContentType;

    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await this.sessionStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final SessionStorage sessionStorage;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      dio.post<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => dio.delete<T>(path);
}
