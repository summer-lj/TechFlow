import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
    : baseUrl = normalizeApiBaseUrl(baseUrl),
      _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<AuthSession> login(LoginCredentials credentials) async {
    final envelope = await _request(
      method: 'POST',
      path: '/auth/login',
      body: {
        'phone': credentials.phone.replaceAll(RegExp(r'\D'), ''),
        'password': credentials.password,
      },
    );

    return AuthSession.fromJson(
      envelope['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> logout({required String refreshToken}) async {
    await _request(
      method: 'POST',
      path: '/auth/logout',
      body: {'refreshToken': refreshToken},
    );
  }

  Future<AppUser> fetchCurrentUser({required String accessToken}) async {
    final envelope = await _request(
      method: 'GET',
      path: '/users/me',
      accessToken: accessToken,
    );

    return AppUser.fromJson(
      envelope['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<AppHomePayload> fetchAppHome() async {
    final envelope = await _request(method: 'GET', path: '/app/home');

    return AppHomePayload.fromJson(
      envelope['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<Map<String, dynamic>> fetchHealth() async {
    return _requestRaw(
      method: 'GET',
      rawUrl: baseUrl.replaceFirst(RegExp(r'/api/v1$'), '/health'),
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');
    return _requestRaw(
      method: method,
      rawUrl: uri.toString(),
      body: body,
      accessToken: accessToken,
    );
  }

  Future<Map<String, dynamic>> _requestRaw({
    required String method,
    required String rawUrl,
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final uri = Uri.parse(rawUrl);
    final headers = <String, String>{'Accept': 'application/json'};

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    try {
      _logRequest(method: method, uri: uri, headers: headers, body: body);

      late final http.Response response;

      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? const <String, dynamic>{}),
              )
              .timeout(const Duration(seconds: 15));
        default:
          throw ApiException('不支持的请求方法: $method');
      }

      _logResponse(response);
      return _decodeEnvelope(response);
    } on TimeoutException {
      _emitLog('timeout ${uri.toString()}');
      throw ApiException('请求超时：$uri');
    } on SocketException catch (error) {
      _emitLog(
        'socket ${uri.toString()} | message=${error.message} | osError=${error.osError} | address=${error.address} | port=${error.port}',
      );
      throw ApiException(_describeSocketFailure(uri, error));
    } on http.ClientException catch (error) {
      _emitLog('client ${uri.toString()} | ${error.message}');
      throw ApiException('接口连接失败：$uri\n${error.message}');
    } on FormatException catch (error) {
      _emitLog('format ${uri.toString()} | ${error.message}');
      throw ApiException('接口地址无效：${error.message}');
    }
  }

  Map<String, dynamic> _decodeEnvelope(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      throw ApiException('服务端未返回内容', statusCode: response.statusCode);
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>? ??
        const {};

    final isSuccess = decoded['success'] == true;

    if (response.statusCode >= 200 && response.statusCode < 300 && isSuccess) {
      return decoded;
    }

    final error = decoded['error'] as Map<String, dynamic>? ?? const {};
    final details = error['details'];
    final detailMessage = details is List && details.isNotEmpty
        ? details.first.toString()
        : null;
    final message =
        error['message']?.toString() ??
        detailMessage ??
        decoded['message']?.toString() ??
        '请求失败';

    throw ApiException(message, statusCode: response.statusCode);
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) {
    final sanitizedHeaders = Map<String, String>.from(headers);
    if (sanitizedHeaders.containsKey('Authorization')) {
      sanitizedHeaders['Authorization'] = 'Bearer ***';
    }

    _emitLog(
      'request $method ${uri.toString()} | headers=$sanitizedHeaders | body=${_sanitizeBody(body)}',
    );
  }

  void _logResponse(http.Response response) {
    final responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
    final snippet = responseBody.length <= 400
        ? responseBody
        : '${responseBody.substring(0, 400)}...';

    _emitLog(
      'response ${response.statusCode} ${response.request?.url ?? 'unknown'} | body=$snippet',
    );
  }

  Object? _sanitizeBody(Map<String, dynamic>? body) {
    if (body == null) {
      return null;
    }

    final sanitized = <String, dynamic>{};
    for (final entry in body.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('password')) {
        sanitized[entry.key] = '***';
      } else if (key.contains('token')) {
        sanitized[entry.key] = '***';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  String _describeSocketFailure(Uri uri, SocketException error) {
    final message = error.message;
    final errorCode = error.osError?.errorCode;
    final normalizedMessage = message.toLowerCase();

    if (errorCode == 65 || normalizedMessage.contains('no route to host')) {
      return '设备当前网络无法到达服务器：$uri\n'
          'iPhone 系统返回 No route to host，请检查 Wi-Fi/蜂窝网络、VPN/代理，或先在 Safari 中打开这个地址验证。';
    }

    if (errorCode == 61 || normalizedMessage.contains('connection refused')) {
      return '服务器端口不可用：$uri\n'
          '设备已经连到服务器，但目标端口没有接受连接，请检查服务和安全组配置。';
    }

    return '网络连接失败：$uri\n$message';
  }

  void _emitLog(String message) {
    if (!kDebugMode) {
      return;
    }
    developer.log(message, name: 'TechFlow.Api');
    stdout.writeln('[TechFlow.Api] $message');
  }
}
