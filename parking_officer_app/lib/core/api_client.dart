import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:parking_officer_app/core/constants.dart';
import 'package:parking_officer_app/core/storage_manager.dart';

class ApiClient {
  late Dio dio;
  final StorageManager _storageManager = StorageManager();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (status) {
          // Don't throw on any status code; we'll handle them manually
          return status != null;
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('auth/')) {
            final token = await _storageManager.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          debugPrint('[ApiClient] ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '[ApiClient] Response ${response.statusCode}: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          debugPrint('[ApiClient] Error: ${e.type} - ${e.message}');
          debugPrint('[ApiClient] Status: ${e.response?.statusCode}');
          if (e.response?.statusCode == 401) {
            debugPrint('[ApiClient] 401 Unauthorized - Token may be invalid');

            // Check if session was invalidated (logged in from another device)
            final sessionInvalidated = e.response?.headers.value(
              'X-Session-Invalidated',
            );
            if (sessionInvalidated == 'true') {
              debugPrint(
                '[ApiClient] 🚨 Session invalidated - user logged in from another device',
              );
              // Clear local storage and navigate to login
              await _storageManager.clearAuthData();
              // The app will handle navigation to login via auth state listener
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }
}
