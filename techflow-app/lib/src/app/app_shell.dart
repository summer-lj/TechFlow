import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../ui/home_page.dart';
import '../ui/login_page.dart';

class TechFlowApp extends StatefulWidget {
  const TechFlowApp({
    super.key,
    required this.preferences,
  });

  final SharedPreferences preferences;

  @override
  State<TechFlowApp> createState() => _TechFlowAppState();
}

class _TechFlowAppState extends State<TechFlowApp> {
  static const _sessionKey = 'techflow.auth.session';
  static const _legacyApiBaseUrlKey = 'techflow.api.base_url';
  static const _environmentKey = 'techflow.api.environment';
  static const _localApiBaseUrlKey = 'techflow.api.local_base_url';
  static const _serverHostKey = 'techflow.api.server_host';

  AuthSession? _session;
  ApiEnvironmentConfig _environmentConfig = ApiEnvironmentConfig(
    selectedEnvironment: ApiEnvironment.local,
    localApiBaseUrl: resolveInitialLocalApiBaseUrl(),
    serverHost: resolveInitialServerHost(),
  );
  String? _noticeMessage;
  bool _isReady = false;
  bool _isSubmitting = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  void _restoreState() {
    final storedEnvironment = widget.preferences.getString(_environmentKey);
    final storedApiBaseUrl = widget.preferences.getString(_localApiBaseUrlKey) ??
        widget.preferences.getString(_legacyApiBaseUrlKey);
    final storedServerHost = widget.preferences.getString(_serverHostKey);
    final storedSession = widget.preferences.getString(_sessionKey);
    AuthSession? session;

    if (storedSession != null && storedSession.isNotEmpty) {
      try {
        session = AuthSession.decode(storedSession);
      } catch (_) {
        widget.preferences.remove(_sessionKey);
      }
    }

    setState(() {
      _environmentConfig = ApiEnvironmentConfig(
        selectedEnvironment: ApiEnvironment.fromStorage(storedEnvironment),
        localApiBaseUrl: storedApiBaseUrl != null && storedApiBaseUrl.isNotEmpty
            ? normalizeApiBaseUrl(storedApiBaseUrl)
            : resolveInitialLocalApiBaseUrl(),
        serverHost: storedServerHost != null && storedServerHost.isNotEmpty
            ? normalizeServerHost(storedServerHost)
            : resolveInitialServerHost(),
      );
      _session = session;
      _isReady = true;
    });
  }

  Future<void> _persistSession(AuthSession session) async {
    await widget.preferences.setString(_sessionKey, session.encode());
  }

  Future<void> _selectEnvironment(ApiEnvironment environment) async {
    setState(() {
      _environmentConfig = _environmentConfig.copyWith(
        selectedEnvironment: environment,
      );
    });

    await widget.preferences.setString(_environmentKey, environment.storageValue);
  }

  Future<void> _updateLocalApiBaseUrl(String nextUrl) async {
    final normalized = normalizeApiBaseUrl(nextUrl);
    setState(() {
      _environmentConfig = _environmentConfig.copyWith(
        localApiBaseUrl: normalized,
      );
    });

    await widget.preferences.setString(_localApiBaseUrlKey, normalized);
    await widget.preferences.remove(_legacyApiBaseUrlKey);
  }

  Future<void> _updateServerHost(String nextHost) async {
    final normalized = normalizeServerHost(nextHost);
    setState(() {
      _environmentConfig = _environmentConfig.copyWith(
        serverHost: normalized,
      );
    });

    await widget.preferences.setString(_serverHostKey, normalized);
  }

  Future<void> _handleLogin(LoginCredentials credentials) async {
    if (_isSubmitting) {
      return;
    }

    final apiBaseUrl = _environmentConfig.tryResolveApiBaseUrl();
    if (apiBaseUrl == null) {
      throw const ApiException('当前环境缺少可用的接口地址，请先完成环境配置。');
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = ApiClient(baseUrl: apiBaseUrl);
      final session = await client.login(credentials);

      AppUser resolvedUser = session.user;

      try {
        resolvedUser = await client.fetchCurrentUser(
          accessToken: session.tokens.accessToken,
        );
      } catch (_) {
        resolvedUser = session.user;
      }

      final resolvedSession = session.copyWith(user: resolvedUser);
      await _persistSession(resolvedSession);

      if (!mounted) {
        return;
      }

      setState(() {
        _session = resolvedSession;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleLogout({
    bool notifyServer = true,
    String? notice,
  }) async {
    if (_isLoggingOut) {
      return;
    }

    final currentSession = _session;

    setState(() {
      _isLoggingOut = true;
    });

    if (notifyServer && currentSession != null) {
      try {
        final apiBaseUrl = _environmentConfig.tryResolveApiBaseUrl();
        if (apiBaseUrl != null) {
          final client = ApiClient(baseUrl: apiBaseUrl);
          await client.logout(refreshToken: currentSession.tokens.refreshToken);
        }
      } catch (_) {
        // Local logout should still complete even if the remote call fails.
      }
    }

    await widget.preferences.remove(_sessionKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = null;
      _noticeMessage = notice;
      _isLoggingOut = false;
    });
  }

  Future<void> _handleSessionExpired() {
    return _handleLogout(
      notifyServer: false,
      notice: '登录状态已失效，请重新登录。',
    );
  }

  Future<void> _handleUserSynced(AppUser user) async {
    final current = _session;
    if (current == null) {
      return;
    }

    final next = current.copyWith(user: user);
    await _persistSession(next);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = next;
    });
  }

  void _clearNotice() {
    if (_noticeMessage == null) {
      return;
    }

    setState(() {
      _noticeMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF132136);
    const accent = Color(0xFFEC6F4A);
    const secondary = Color(0xFF56D5C5);

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: secondary,
        surface: Colors.white,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TechFlow',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: baseTheme.textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          hintStyle: TextStyle(
            color: ink.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
          labelStyle: TextStyle(
            color: ink.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
          prefixIconColor: ink.withValues(alpha: 0.72),
          suffixIconColor: ink.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(58),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            minimumSize: const Size.fromHeight(56),
            side: BorderSide(color: ink.withValues(alpha: 0.12)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: !_isReady
            ? const _SplashScreen()
            : _session == null
                ? LoginEntryScreen(
                    key: const ValueKey('login'),
                    environmentConfig: _environmentConfig,
                    isSubmitting: _isSubmitting,
                    noticeMessage: _noticeMessage,
                    onNoticeShown: _clearNotice,
                    onSelectEnvironment: _selectEnvironment,
                    onSaveLocalApiBaseUrl: _updateLocalApiBaseUrl,
                    onSaveServerHost: _updateServerHost,
                    onLogin: _handleLogin,
                  )
                : HomePage(
                    key: const ValueKey('home'),
                    session: _session!,
                    environmentConfig: _environmentConfig,
                    isLoggingOut: _isLoggingOut,
                    onLogout: _handleLogout,
                    onSessionExpired: _handleSessionExpired,
                    onUserSynced: _handleUserSynced,
                  ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07111F),
            Color(0xFF14324C),
            Color(0xFFF2E7D6),
          ],
          stops: [0.0, 0.48, 1.0],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
