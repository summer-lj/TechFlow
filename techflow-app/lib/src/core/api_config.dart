const String _compileTimeLocalApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
);
const String _compileTimeServerHost = String.fromEnvironment('SERVER_HOST');
const String _fallbackLocalApiBaseUrl = 'http://172.16.81.118:3000/api/v1';
const String _fallbackServerHost = '101.133.135.17';
const String _pinnedProductionHost = '101.133.135.17';
const String _defaultH5RegistrationBusiness = 'techflow-app';

enum ApiEnvironment {
  local,
  staging,
  production;

  String get storageValue {
    switch (this) {
      case ApiEnvironment.local:
        return 'local';
      case ApiEnvironment.staging:
        return 'staging';
      case ApiEnvironment.production:
        return 'production';
    }
  }

  String get label {
    switch (this) {
      case ApiEnvironment.local:
        return '本地环境';
      case ApiEnvironment.staging:
        return '测试环境';
      case ApiEnvironment.production:
        return '生产环境';
    }
  }

  String get shortLabel {
    switch (this) {
      case ApiEnvironment.local:
        return '本地';
      case ApiEnvironment.staging:
        return '测试';
      case ApiEnvironment.production:
        return '生产';
    }
  }

  bool get requiresServerHost => this != ApiEnvironment.local;

  static ApiEnvironment fromStorage(String? value) {
    return ApiEnvironment.values.firstWhere(
      (environment) => environment.storageValue == value,
      orElse: () => ApiEnvironment.local,
    );
  }
}

class ApiEnvironmentConfig {
  const ApiEnvironmentConfig({
    required this.selectedEnvironment,
    required this.localApiBaseUrl,
    required this.serverHost,
  });

  final ApiEnvironment selectedEnvironment;
  final String localApiBaseUrl;
  final String serverHost;

  String get normalizedLocalApiBaseUrl => normalizeApiBaseUrl(localApiBaseUrl);

  bool get hasServerHost => serverHost.trim().isNotEmpty;

  bool get isSelectedEnvironmentConfigured {
    if (!selectedEnvironment.requiresServerHost) {
      return true;
    }

    return hasServerHost;
  }

  String? tryResolveApiBaseUrl([ApiEnvironment? environment]) {
    final target = environment ?? selectedEnvironment;

    try {
      return buildEnvironmentApiBaseUrl(
        environment: target,
        localApiBaseUrl: localApiBaseUrl,
        serverHost: serverHost,
      );
    } on FormatException {
      return null;
    }
  }

  String? endpointLabel([ApiEnvironment? environment]) {
    final baseUrl = tryResolveApiBaseUrl(environment);
    return baseUrl == null ? null : describeApiEndpoint(baseUrl);
  }

  ApiEnvironmentConfig copyWith({
    ApiEnvironment? selectedEnvironment,
    String? localApiBaseUrl,
    String? serverHost,
  }) {
    return ApiEnvironmentConfig(
      selectedEnvironment: selectedEnvironment ?? this.selectedEnvironment,
      localApiBaseUrl: localApiBaseUrl ?? this.localApiBaseUrl,
      serverHost: serverHost ?? this.serverHost,
    );
  }
}

String resolveInitialLocalApiBaseUrl() {
  final candidate = _compileTimeLocalApiBaseUrl.isNotEmpty
      ? _compileTimeLocalApiBaseUrl
      : _fallbackLocalApiBaseUrl;
  return normalizeApiBaseUrl(candidate);
}

String resolveInitialServerHost() {
  final candidate = _compileTimeServerHost.trim().isNotEmpty
      ? _compileTimeServerHost.trim()
      : _fallbackServerHost;

  return normalizeServerHost(candidate);
}

String normalizeApiBaseUrl(String input) {
  var value = input.trim();

  if (value.isEmpty) {
    throw const FormatException('接口地址不能为空');
  }

  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'http://$value';
  }

  value = value.replaceAll(RegExp(r'/+$'), '');

  final uri = Uri.parse(value);
  final normalized = uri.toString().replaceAll(RegExp(r'/+$'), '');

  if (normalized.endsWith('/api/v1')) {
    return normalized;
  }

  if (normalized.endsWith('/api')) {
    return '$normalized/v1';
  }

  if (normalized.contains('/api/')) {
    return normalized;
  }

  return '$normalized/api/v1';
}

String normalizeServerHost(String input) {
  var value = input.trim();

  if (value.isEmpty) {
    throw const FormatException('服务器主机不能为空');
  }

  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'http://$value';
  }

  final uri = Uri.parse(value);

  if (uri.host.isEmpty) {
    throw const FormatException('请输入有效的公网 IP 或域名');
  }

  return Uri(scheme: uri.scheme, host: uri.host).toString();
}

String buildEnvironmentApiBaseUrl({
  required ApiEnvironment environment,
  required String localApiBaseUrl,
  required String serverHost,
}) {
  switch (environment) {
    case ApiEnvironment.local:
      return normalizeApiBaseUrl(localApiBaseUrl);
    case ApiEnvironment.staging:
      return _buildRemoteApiBaseUrl(serverHost, port: 8080);
    case ApiEnvironment.production:
      return _buildRemoteApiBaseUrl(_pinnedProductionHost);
  }
}

String describeApiEndpoint(String baseUrl) {
  final uri = Uri.parse(normalizeApiBaseUrl(baseUrl));
  final portSuffix = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$portSuffix';
}

String buildH5RegistrationUrl(String apiBaseUrl) {
  final uri = Uri.parse(normalizeApiBaseUrl(apiBaseUrl));

  return uri
      .replace(
        path: '/h5/register/$_defaultH5RegistrationBusiness',
        queryParameters: {
          'apiBase': uri.toString(),
          'embedded': '1',
          'source': 'app',
        },
      )
      .toString();
}

String _buildRemoteApiBaseUrl(String serverHost, {int? port}) {
  final origin = Uri.parse(normalizeServerHost(serverHost));
  final uri = Uri(
    scheme: origin.scheme,
    host: origin.host,
    port: port,
    path: '/api/v1',
  );
  return uri.toString().replaceAll(RegExp(r'/+$'), '');
}
