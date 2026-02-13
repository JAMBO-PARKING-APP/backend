import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/constants.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/core/storage_manager.dart';

class ApiClient {
  late Dio dio;
  final StorageManager _storageManager = StorageManager();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Don't add token for auth endpoints
          if (!options.path.contains('auth/')) {
            final token = await _storageManager.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              debugPrint('[ApiClient] Added auth token for ${options.path}');
            } else {
              debugPrint(
                '[ApiClient] ⚠️ No token found for ${options.path} - user may not be authenticated',
              );
            }
          } else {
            debugPrint(
              '[ApiClient] Skipping token for auth endpoint: ${options.path}',
            );
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Check for internet connection errors
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError ||
              (e.type == DioExceptionType.unknown &&
                  e.message?.contains('SocketException') == true)) {
            // Show No Internet Dialog
            DialogService.showNoInternetDialog();
          }

          if (e.response?.statusCode == 401) {
            debugPrint(
              '[ApiClient] 401 Unauthorized for ${e.requestOptions.path}',
            );

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

  // --- Rewards & Loyalty ---
  Future<Map<String, dynamic>> getLoyaltyBalance() async {
    final response = await dio.get('rewards/balance/');
    return response.data;
  }

  Future<List<dynamic>> getLoyaltyHistory() async {
    final response = await dio.get('rewards/history/');
    return response.data;
  }
}
