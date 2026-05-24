import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../shared/services/session_manager.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:5000/api/v1');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth Token Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SessionManager.token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            // Token expired or invalid, logout
            SessionManager.clearSession();
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException err) {
    String message = "Something went wrong";
    if (err.response != null) {
      final resData = err.response!.data;
      if (resData is Map && resData.containsKey('message')) {
        message = resData['message'];
      } else if (resData is Map && resData.containsKey('error')) {
        message = resData['error'];
      } else {
        message = "Server Error (${err.response!.statusCode})";
      }
    } else {
      if (err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.receiveTimeout) {
        message = "Connection timed out. Check your network.";
      } else if (err.type == DioExceptionType.connectionError) {
        message = "Cannot connect to server. Check if backend is running.";
      } else {
        message = "Network error occurred";
      }
    }
    return Exception(message);
  }
}
