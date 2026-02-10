import 'package:dio/dio.dart';
import 'package:parking_user_app/core/constants.dart';
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
              print('[ApiClient] Added auth token for ${options.path}');
            } else {
              print('[ApiClient] ⚠️ No token found for ${options.path} - user may not be authenticated');
            }
          } else {
            print('[ApiClient] Skipping token for auth endpoint: ${options.path}');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            print('[ApiClient] 401 Unauthorized for ${e.requestOptions.path}');
            // TODO: Implement Token Refresh Logic
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
