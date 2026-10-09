import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/storage_service.dart';

class ApiResponseException implements Exception {
  final String message;
  final int statusCode;
  ApiResponseException(this.message, {this.statusCode = 500});

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> get(String url, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.get(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiResponseException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc backend.');
    }
  }

  static Future<dynamic> post(String url, {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiResponseException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc backend.');
    }
  }

  static Future<dynamic> patch(String url, {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiResponseException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc backend.');
    }
  }

  static Future<dynamic> delete(String url, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiResponseException('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc backend.');
    }
  }

  static dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } catch (_) {
      jsonBody = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    } else if (response.statusCode == 401) {
      throw ApiResponseException('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.', statusCode: 401);
    } else {
      String msg = 'Yêu cầu thất bại';
      if (jsonBody is Map<String, dynamic>) {
        if (jsonBody.containsKey('message') && jsonBody['message'] != null) {
          msg = jsonBody['message'];
        } else if (jsonBody.containsKey('errors') && jsonBody['errors'] != null) {
          msg = jsonBody['errors'].toString();
        }
      }
      throw ApiResponseException(msg, statusCode: response.statusCode);
    }
  }
}
