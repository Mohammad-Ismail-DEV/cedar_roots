import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'logger.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  /// 0 means the server could not be reached.
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => message;
}

/// The only place that talks HTTP. Returns decoded JSON or throws [ApiException].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenReader,
    this.onUnauthorized,
    http.Client? client,
  }) : _http = client ?? http.Client();

  final String baseUrl;
  final String? Function() tokenReader;
  final void Function()? onUnauthorized;
  final http.Client _http;

  static const _timeout = Duration(seconds: 20);

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  /// Uploads an image and returns its public URL.
  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final mimeType =
        lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
    final request =
        http.MultipartRequest('POST', _uri('/upload'))
          ..headers.addAll(_headers(json: false))
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: file.name,
              contentType: MediaType.parse(mimeType),
            ),
          );

    final response = await _guard(
      () async => http.Response.fromStream(await _http.send(request)),
    );
    final data = _decode(response);
    return data['url'] as String;
  }

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final params = <String, String>{
      for (final e in (query ?? {}).entries)
        if (e.value != null) e.key: '${e.value}',
    };
    return Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  Map<String, String> _headers({bool json = true}) {
    final token = tokenReader();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(_headers());
    if (body != null) request.body = jsonEncode(body);

    final response = await _guard(
      () async => http.Response.fromStream(await _http.send(request)),
    );
    return _decode(response);
  }

  Future<http.Response> _guard(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      AppLog.w('Network error: $e', 'api');
      throw const ApiException(0, 'Could not reach the server');
    }
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        data = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    if (response.statusCode == 401 && tokenReader() != null) {
      onUnauthorized?.call();
    }
    final message =
        data is Map
            ? (data['error'] ?? data['message'] ?? 'Request failed').toString()
            : 'Request failed (${response.statusCode})';
    throw ApiException(response.statusCode, message);
  }
}
