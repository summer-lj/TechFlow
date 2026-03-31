import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techflow_app/src/core/api_config.dart';
import 'package:techflow_app/src/core/models.dart';
import 'package:techflow_app/src/ui/login_page.dart';

void main() {
  test('normalizeApiBaseUrl appends api prefix when omitted', () {
    expect(
      normalizeApiBaseUrl('172.16.81.118:3000'),
      'http://172.16.81.118:3000/api/v1',
    );
  });

  test('staging and production urls follow deployment topology', () {
    expect(
      buildEnvironmentApiBaseUrl(
        environment: ApiEnvironment.staging,
        localApiBaseUrl: 'http://172.16.81.118:3000/api/v1',
        serverHost: 'api.techflow.example',
      ),
      'http://api.techflow.example:8080/api/v1',
    );

    expect(
      buildEnvironmentApiBaseUrl(
        environment: ApiEnvironment.production,
        localApiBaseUrl: 'http://172.16.81.118:3000/api/v1',
        serverHost: 'api.techflow.example',
      ),
      'http://101.133.135.17/api/v1',
    );
  });

  test('registration h5 url follows selected api base', () {
    expect(
      buildH5RegistrationUrl('http://172.16.81.118:3000/api/v1'),
      'http://172.16.81.118:3000/h5/register/techflow-app?apiBase=http%3A%2F%2F172.16.81.118%3A3000%2Fapi%2Fv1&embedded=1&source=app',
    );
  });

  testWidgets('login page renders real login flow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginEntryScreen(
          environmentConfig: const ApiEnvironmentConfig(
            selectedEnvironment: ApiEnvironment.local,
            localApiBaseUrl: 'http://172.16.81.118:3000/api/v1',
            serverHost: '',
          ),
          isSubmitting: false,
          onSelectEnvironment: (_) async {},
          onSaveLocalApiBaseUrl: (_) async {},
          onSaveServerHost: (_) async {},
          onLogin: (_) async {},
          onRegisterSession: (_) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TechFlow Mobile Workspace'), findsOneWidget);
    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('登录并进入本地环境'), findsOneWidget);
    expect(find.text('打开 H5 注册页'), findsOneWidget);
    expect(find.text('填充演示账号'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('登录密码'), findsOneWidget);
    expect(find.text('测试'), findsOneWidget);
    expect(find.text('生产'), findsOneWidget);
  });

  test('auth session round-trips through json', () {
    const session = AuthSession(
      user: AppUser(
        id: 'u_1',
        name: 'Founder Admin',
        email: 'admin@techflow.local',
        phone: '13965026764',
        role: 'ADMIN',
        isActive: true,
      ),
      tokens: AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
        expiresIn: 7200,
      ),
    );

    expect(AuthSession.decode(session.encode()).user.phone, '13965026764');
    expect(AuthSession.decode(session.encode()).tokens.refreshToken, 'refresh');
  });
}
