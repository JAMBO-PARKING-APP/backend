import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/constants.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'dart:async';

class ApiClient {
  late Dio dio;
  final StorageManager _storageManager = StorageManager();
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.path = _normalizePath(options.path);

          // Don't add token for public auth endpoints only
          final publicAuthPaths = [
            'auth/login/',
            'auth/register/',
            'auth/verify-otp/',
            'auth/resend-otp/',
            'auth/forgot-password/',
            'auth/reset-password/',
            'auth/token/refresh/',
          ];

          bool isPublicAuth = publicAuthPaths.any(
            (path) => options.path.contains(path),
          );

          if (!isPublicAuth) {
            final token = await _storageManager.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              debugPrint(
                '[ApiClient] added Bearer token (${token.substring(0, 5)}...) for ${options.path}',
              );
            } else {
              debugPrint(
                '[ApiClient] ⚠️ NO token found for ${options.path} - user may not be authenticated',
              );
            }
          } else {
            debugPrint(
              '[ApiClient] Skipping token for public auth endpoint: ${options.path}',
            );
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Check for internet connection errors
          if (e.type == DioExceptionType.connectionError ||
              (e.type == DioExceptionType.unknown &&
                  e.message?.contains('SocketException') == true)) {
            // Show No Internet Dialog (Only if it's a hard connection error)
            DialogService.showNoInternetDialog();
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
             debugPrint('[ApiClient] Timeout error: ${e.message}');
             // Don't show blocking dialog for timeouts, just log it.
          }

          if (e.response?.statusCode == 401) {
            debugPrint(
              '[ApiClient] 🔴 401 Unauthorized for ${e.requestOptions.path}',
            );
            debugPrint('[ApiClient] Response body: ${e.response?.data}');

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
            } else {
              final shouldRetry = !(e.requestOptions.extra['retried'] == true) &&
                  !e.requestOptions.path.contains('auth/token/refresh/');
              if (shouldRetry) {
                final refreshed = await _refreshToken();
                if (refreshed) {
                  try {
                    final retryOptions = Options(
                      method: e.requestOptions.method,
                      headers: Map<String, dynamic>.from(e.requestOptions.headers)
                        ..remove('Authorization'),
                      responseType: e.requestOptions.responseType,
                      contentType: e.requestOptions.contentType,
                      followRedirects: e.requestOptions.followRedirects,
                      receiveDataWhenStatusError:
                          e.requestOptions.receiveDataWhenStatusError,
                      extra: {
                        ...e.requestOptions.extra,
                        'retried': true,
                      },
                    );
                    final response = await dio.request(
                      e.requestOptions.path,
                      data: e.requestOptions.data,
                      queryParameters: e.requestOptions.queryParameters,
                      options: retryOptions,
                    );
                    return handler.resolve(response);
                  } catch (retryError) {
                    debugPrint('[ApiClient] Retry after refresh failed: $retryError');
                  }
                }
              }

              debugPrint('[ApiClient] 401 error and refresh/retry failed.');
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
    return await dio.get(
      _normalizePath(path),
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(_normalizePath(path), data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(_normalizePath(path), data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(_normalizePath(path), data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(_normalizePath(path), data: data);
  }

  // --- Rewards & Loyalty ---
  Future<Map<String, dynamic>> getLoyaltyBalance() async {
    final response = await dio.get('rewards/balance/');
    return response.data;
  }

  Future<List<dynamic>> getLoyaltyHistory() async {
    final response = await dio.get('rewards/history/');
    if (response.data is Map && response.data.containsKey('results')) {
      return response.data['results'];
    } else if (response.data is List) {
      return response.data;
    }
    return [];
  }

  String _normalizePath(String path) {
    var normalized = path.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    if (normalized.startsWith('/api/')) {
      // Keep absolute API-root paths (used by non-/api/user mounts like chat).
      return normalized;
    }

    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    if (normalized.startsWith('api/user/')) {
      normalized = normalized.substring('api/user/'.length);
    }

    if (normalized.startsWith('api/')) {
      normalized = normalized.substring('api/'.length);
    }

    return normalized;
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? false;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refresh = await _storageManager.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _storageManager.clearAuthData();
        _refreshCompleter?.complete(false);
        return false;
      }

      final response = await dio.post(
        'auth/token/refresh/',
        data: {'refresh': refresh},
        options: Options(headers: {'Authorization': null}),
      );

      final access = response.data['access']?.toString();
      final newRefresh = (response.data['refresh']?.toString() ?? refresh);

      if (access == null || access.isEmpty) {
        _refreshCompleter?.complete(false);
        return false;
      }

      await _storageManager.saveTokens(access, newRefresh);
      _refreshCompleter?.complete(true);
      return true;
    } catch (e) {
      debugPrint('[ApiClient] Token refresh failed: $e');
      await _storageManager.clearAuthData();
      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
