import 'package:dio/dio.dart';

/// Silently warms up the Render server in the background so it's
/// awake before the user hits "Login". The free Render plan spins
/// the server down after 15 minutes of inactivity; a cold start
/// can take 30–60 seconds. This ping is fire-and-forget.
class WarmupService {
  final Dio _dio;
  final String _baseUrl;

  WarmupService(this._dio, this._baseUrl);

  /// Fire and forget — call this from main.dart initState or app launch.
  void warmup() {
    _ping();
  }

  Future<void> _ping() async {
    try {
      await _dio.get(
        '${_baseUrl}health/', // lightweight endpoint; falls back silently
        options: Options(
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
    } catch (_) {
      // Ignore all errors — the server may not have a /health/ endpoint,
      // but the TCP connection alone wakes it from sleep.
    }
  }
}
