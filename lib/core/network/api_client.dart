import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient(this.dio, this.secureStorage) {
    dio.options.baseUrl = 'https://billway-api-a9ea.onrender.com/api/'; 
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token might be expired, try refreshing
          final refreshToken = await secureStorage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              final response = await dio.post('auth/refresh/', data: {'refresh': refreshToken});
              final newAccessToken = response.data['access'];
              await secureStorage.write(key: 'access_token', value: newAccessToken);
              
              // Retry the original request
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (refreshError) {
              await secureStorage.delete(key: 'access_token');
              await secureStorage.delete(key: 'refresh_token');
              // Navigate to login or emit unauthenticated state
            }
          }
        }
        return handler.next(e);
      }
    ));
  }

  Future<String?> uploadImage(String imagePath) async {
    try {
      final fileName = imagePath.split('/').last;
      
      final urlResponse = await dio.post('core/generate-upload-url/', data: {
        'file_name': fileName,
        'content_type': 'image/jpeg', 
      });
      
      final uploadUrl = urlResponse.data['upload_url'];
      final publicUrl = urlResponse.data['public_url'];
      
      final file = await MultipartFile.fromFile(imagePath);
      final rawDio = Dio(); 
      await rawDio.put(
        uploadUrl,
        data: file.finalize(),
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
            'Content-Length': file.length,
          },
        ),
      );
      
      final separator = publicUrl.toString().contains('?') ? '&' : '?';
      return '$publicUrl${separator}t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
