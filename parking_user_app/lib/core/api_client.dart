import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:parking_officer_app/core/location_service.dart';
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
          return status != null;
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach auth header for all requests except pre-auth endpoints
          // (where the client won't yet have a token).
          final path = options.path;
          final shouldSkipAuthHeader =
              path.contains('auth/login/') ||
              path.contains('auth/register/') ||
              path.contains('auth/verify-otp/') ||
              path.contains('auth/resend-otp/') ||
              path.contains('auth/token/refresh/') ||
              path.contains('auth/refresh/');

          if (!shouldSkipAuthHeader) {
            final token = await _storageManager.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // Attach Country header to all requests for regional isolation
          // 1. Prioritize manual user selection
          String? country = await _storageManager.getSelectedCountryCode();
          
          // 2. Fallback to profile country if no manual selection
          if (country == null || country.isEmpty || country == 'null') {
            final userJson = await _storageManager.getUserJson();
            if (userJson != null) {
              try {
                final userMap = json.decode(userJson);
                country = userMap['country']?.toString();
              } catch (_) {}
            }
          }

          if (country != null && country.isNotEmpty && country != 'null') {
            if (country.length == 2) {
               options.headers['X-Country-Code'] = country;
            } else {
               options.headers['X-Country-ID'] = country;
            }
          }

          // 3. Inject GPS Location for automatic regional isolation
          final pos = LocationService.currentPosition;
          if (pos != null) {
            options.headers['X-Latitude'] = pos.latitude.toString();
            options.headers['X-Longitude'] = pos.longitude.toString();
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

            final sessionInvalidated = e.response?.headers.value(
              'X-Session-Invalidated',
            );
            if (sessionInvalidated == 'true') {
              debugPrint(
                '[ApiClient] 🚨 Session invalidated - user logged in from another device',
              );
              await _storageManager.clearAuthData();
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
