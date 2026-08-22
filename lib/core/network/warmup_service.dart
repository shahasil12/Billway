import 'package:dio/dio.dart';

/// Silently warms up the Render server in the background so it's
/// awake before the user hits "Login". The free Render plan spins
/// the server down after 15 minutes of inactivity; a cold start
/// can take 30–60 seconds. This ping is fire-and-forget.
class WarmupService {
  final Dio _dio;
  final String _baseUrl;

  WarmupService(this._dio, this._baseUrl);

  /// Fire and forget — called from main.dart initState.
  void warmup() {
    _ping();
  }

  Future<void> _ping() async {
    try {
      // /api/core/ping/ has AllowAny — no auth needed, no JSON body.
      // Just hitting it over TCP is enough to wake Render from sleep.
      await _dio.get(
        '${_baseUrl}core/ping/',
        options: Options(
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
          // Don't follow redirects that might need auth
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (_) {
      // Ignore all errors — if the server is completely down we still
      // don't want to block the user; they'll see API errors on login.
    }
  }
}
