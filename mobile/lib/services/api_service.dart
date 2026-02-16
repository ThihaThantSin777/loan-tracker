import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Custom exception classes for better error handling
class ApiException implements Exception {
  final String message;
  final String errorCode;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.errorCode = 'UNKNOWN_ERROR',
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException({String message = 'No internet connection. Please check your network.'})
      : super(message: message, errorCode: 'NETWORK_ERROR');
}

class TimeoutException extends ApiException {
  TimeoutException({String message = 'Request timed out. Please try again.'})
      : super(message: message, errorCode: 'TIMEOUT_ERROR');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String message = 'Session expired. Please login again.'})
      : super(message: message, errorCode: 'UNAUTHENTICATED', statusCode: 401);
}

class ValidationException extends ApiException {
  ValidationException({
    String message = 'Please check your input.',
    Map<String, dynamic>? errors,
  }) : super(message: message, errorCode: 'VALIDATION_ERROR', statusCode: 422, errors: errors);
}

class ServerException extends ApiException {
  ServerException({String message = 'Server error. Please try again later.'})
      : super(message: message, errorCode: 'SERVER_ERROR', statusCode: 500);
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
    this.errors,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message, {String? errorCode, Map<String, dynamic>? errors}) {
    return ApiResponse(success: false, message: message, errorCode: errorCode, errors: errors);
  }
}

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const Duration _timeout = Duration(seconds: 30);

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      String? token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(String endpoint, {bool withAuth = true}) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: await _getHeaders(withAuth: withAuth),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: await _getHeaders(withAuth: withAuth),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: await _getHeaders(withAuth: withAuth),
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint, {bool withAuth = true}) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: await _getHeaders(withAuth: withAuth),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> postWithFile(
    String endpoint,
    Map<String, String> data,
    File file,
    String fileField, {
    bool withAuth = true,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      );

      String? token = await getToken();
      if (withAuth && token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      data.forEach((key, value) {
        request.fields[key] = value;
      });

      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body);
    } catch (e) {
      body = {'message': 'Invalid response from server'};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': body['data'] ?? body,
        'message': body['message'],
      };
    }

    // Handle different error status codes
    String message = body['message'] ?? _getDefaultErrorMessage(response.statusCode);
    String errorCode = body['error_code'] ?? _getErrorCode(response.statusCode);

    return {
      'success': false,
      'error': message,
      'error_code': errorCode,
      'errors': body['errors'],
      'status_code': response.statusCode,
    };
  }

  Map<String, dynamic> _handleError(dynamic e) {
    if (e is SocketException) {
      return {
        'success': false,
        'error': 'No internet connection. Please check your network.',
        'error_code': 'NETWORK_ERROR',
      };
    } else if (e is TimeoutException || e.toString().contains('TimeoutException')) {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
        'error_code': 'TIMEOUT_ERROR',
      };
    } else if (e is FormatException) {
      return {
        'success': false,
        'error': 'Invalid response from server.',
        'error_code': 'PARSE_ERROR',
      };
    } else {
      return {
        'success': false,
        'error': 'Something went wrong. Please try again.',
        'error_code': 'UNKNOWN_ERROR',
      };
    }
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You don\'t have permission to do this.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Please check your input and try again.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _getErrorCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHENTICATED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 422:
        return 'VALIDATION_ERROR';
      case 429:
        return 'RATE_LIMITED';
      case 500:
        return 'SERVER_ERROR';
      default:
        return 'UNKNOWN_ERROR';
    }
  }
}
