import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String _desktopBaseUrl = 'http://localhost:5000/api';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api';
  static const String _androidPhysicalDeviceBaseUrl = 'http://192.168.1.10:5000/api';

  String get baseUrl {
    if (kIsWeb) {
      return _desktopBaseUrl;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Use physical device IP by default; change to _androidEmulatorBaseUrl if using emulator
        return _androidPhysicalDeviceBaseUrl;
      }
    } catch (_error) {
      // Ignore platform lookup issues and use the desktop default.
    }

    return _desktopBaseUrl;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: queryParameters.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<Map<String, String>> _headers({bool jsonBody = true}) async {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }

    final token = await AuthService.instance.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await http.get(_buildUri(path, queryParameters), headers: await _headers());
    return _decodeResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _buildUri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      _buildUri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      _buildUri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<ApiMultipartFile>? files,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri(path));

    final headers = await _headers(jsonBody: false);
    request.headers.addAll(headers);

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
          ),
        );
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = body is Map<String, dynamic> ? body['message']?.toString() : null;
      throw ApiClientException(message ?? 'Request failed', response.statusCode);
    }

    return body;
  }
}

class ApiMultipartFile {
  const ApiMultipartFile({
    required this.field,
    required this.filename,
    required this.bytes,
  });

  final String field;
  final String filename;
  final Uint8List bytes;
}

class ApiClientException implements Exception {
  ApiClientException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}
