import 'package:flutter/material.dart';

import '../core/api_config.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import 'register_webview_page.dart';

class LoginEntryScreen extends StatefulWidget {
  const LoginEntryScreen({
    super.key,
    required this.environmentConfig,
    required this.isSubmitting,
    required this.onLogin,
    required this.onRegisterSession,
    required this.onSelectEnvironment,
    required this.onSaveLocalApiBaseUrl,
    required this.onSaveServerHost,
    this.noticeMessage,
    this.onNoticeShown,
  });

  final ApiEnvironmentConfig environmentConfig;
  final bool isSubmitting;
  final String? noticeMessage;
  final VoidCallback? onNoticeShown;
  final Future<void> Function(LoginCredentials credentials) onLogin;
  final Future<void> Function(AuthSession session) onRegisterSession;
  final Future<void> Function(ApiEnvironment environment) onSelectEnvironment;
  final Future<void> Function(String baseUrl) onSaveLocalApiBaseUrl;
  final Future<void> Function(String serverHost) onSaveServerHost;

  @override
  State<LoginEntryScreen> createState() => _LoginEntryScreenState();
}

class _LoginEntryScreenState extends State<LoginEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    _showNoticeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LoginEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noticeMessage != widget.noticeMessage) {
      _showNoticeIfNeeded();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showNoticeIfNeeded() {
    final notice = widget.noticeMessage;
    if (notice == null || notice.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notice)));
      widget.onNoticeShown?.call();
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || widget.isSubmitting) {
      return;
    }

    if (!widget.environmentConfig.isSelectedEnvironmentConfigured) {
      _showSnack('当前环境还没有配置服务器主机，请先完成环境配置。');
      return;
    }

    final environment = widget.environmentConfig.selectedEnvironment;
    final endpoint = widget.environmentConfig.endpointLabel() ?? '未配置';

    try {
      await widget.onLogin(
        LoginCredentials(
          phone: _phoneController.text,
          password: _passwordController.text,
        ),
      );
    } on ApiException catch (error) {
      _showSnack('[${environment.label}] $endpoint\n${error.message}');
    } catch (_) {
      _showSnack('[${environment.label}] $endpoint\n登录失败，请稍后再试。');
    }
  }

  Future<void> _openRegisterPage() async {
    if (widget.isSubmitting) {
      return;
    }

    final apiBaseUrl = widget.environmentConfig.tryResolveApiBaseUrl();

    if (apiBaseUrl == null) {
      _showSnack('当前环境还没有配置服务器主机，请先完成环境配置。');
      return;
    }

    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute(
        builder: (context) => RegistrationWebViewPage(
          environmentLabel:
              widget.environmentConfig.selectedEnvironment.shortLabel,
          registrationUrl: buildH5RegistrationUrl(apiBaseUrl),
        ),
      ),
    );

    if (session == null) {
      return;
    }

    await widget.onRegisterSession(session);
  }

  Future<void> _openEndpointSettings() async {
    final environment = widget.environmentConfig.selectedEnvironment;
    final isLocal = environment == ApiEnvironment.local;
    final controller = TextEditingController(
      text: isLocal
          ? widget.environmentConfig.localApiBaseUrl
          : widget.environmentConfig.serverHost,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            top: 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLocal ? '修改本地接口地址' : '配置服务器主机',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLocal
                      ? '本地环境直接连接开发机接口，适合真机联调。'
                      : '根据仓库部署规则，测试环境走 `:8080`，生产环境走默认 `:80`。这里只需要填写服务器的公网 IP 或域名。',
                  style: TextStyle(
                    color: const Color(0xFF132136).withValues(alpha: 0.68),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isLocal ? '接口地址' : '服务器主机',
                    hintText: isLocal
                        ? 'http://172.16.81.118:3000/api/v1'
                        : '123.123.123.123 或 api.example.com',
                    prefixIcon: Icon(
                      isLocal ? Icons.lan_rounded : Icons.dns_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isLocal
                      ? '支持输入完整地址，也支持只填主机和端口，例如 172.16.81.118:3000。'
                      : '如果输入了完整 URL，App 会自动提取主机，并生成测试环境与生产环境的登录地址。',
                  style: TextStyle(
                    color: const Color(0xFF132136).withValues(alpha: 0.52),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    try {
                      if (isLocal) {
                        await widget.onSaveLocalApiBaseUrl(controller.text);
                        if (!mounted) {
                          return;
                        }
                        navigator.pop();
                        _showSnack(
                          '本地接口已更新为 ${describeApiEndpoint(controller.text)}',
                        );
                      } else {
                        await widget.onSaveServerHost(controller.text);
                        if (!mounted) {
                          return;
                        }
                        navigator.pop();
                        final stagingUrl = buildEnvironmentApiBaseUrl(
                          environment: ApiEnvironment.staging,
                          localApiBaseUrl:
                              widget.environmentConfig.localApiBaseUrl,
                          serverHost: controller.text,
                        );
                        _showSnack(
                          '服务器主机已保存，测试环境将连接 ${describeApiEndpoint(stagingUrl)}',
                        );
                      }
                    } on FormatException catch (error) {
                      _showSnack(error.message);
                    } catch (_) {
                      _showSnack('保存失败，请检查输入格式。');
                    }
                  },
                  child: Text(isLocal ? '保存本地地址' : '保存服务器主机'),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  void _fillDemoAccount() {
    _phoneController.text = '13965026764';
    _passwordController.text = '123456';
    _showSnack('已填充默认管理员账号。');
  }

  Future<void> _checkConnection() async {
    final apiBaseUrl = widget.environmentConfig.tryResolveApiBaseUrl();
    final environment = widget.environmentConfig.selectedEnvironment;
    final endpoint = widget.environmentConfig.endpointLabel() ?? '未配置';

    if (apiBaseUrl == null) {
      _showSnack('[${environment.label}] 未找到可用接口地址，请先配置环境。');
      return;
    }

    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final client = ApiClient(baseUrl: apiBaseUrl);
      final payload = await client.fetchHealth();
      final data = payload['data'] as Map<String, dynamic>? ?? const {};
      final environmentName = data['environment']?.toString() ?? 'unknown';
      _showSnack(
        '[${environment.label}] $endpoint\n连接成功，服务环境：$environmentName',
      );
    } on ApiException catch (error) {
      _showSnack('[${environment.label}] $endpoint\n${error.message}');
    } catch (_) {
      _showSnack('[${environment.label}] $endpoint\n连接检查失败。');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 920;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07111F), Color(0xFF14324C), Color(0xFFF2E7D6)],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -100,
              left: -40,
              child: _GlowOrb(
                size: 250,
                color: Color(0xFF56D5C5),
                opacity: 0.22,
              ),
            ),
            const Positioned(
              top: 180,
              right: -30,
              child: _GlowOrb(
                size: 280,
                color: Color(0xFFF6B36A),
                opacity: 0.22,
              ),
            ),
            const Positioned(
              bottom: -60,
              left: 100,
              child: _GlowOrb(
                size: 220,
                color: Color(0xFFEC6F4A),
                opacity: 0.18,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 20 : 32,
                    vertical: isCompact ? 20 : 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: isCompact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BrandPanel(
                                  environmentConfig: widget.environmentConfig,
                                ),
                                const SizedBox(height: 20),
                                _LoginPanel(
                                  formKey: _formKey,
                                  phoneController: _phoneController,
                                  passwordController: _passwordController,
                                  rememberMe: _rememberMe,
                                  obscurePassword: _obscurePassword,
                                  isSubmitting: widget.isSubmitting,
                                  isCheckingConnection: _isCheckingConnection,
                                  environmentConfig: widget.environmentConfig,
                                  onRememberChanged: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  onPasswordVisibilityPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  onPrimaryAction: _submit,
                                  onOpenRegister: _openRegisterPage,
                                  onFillDemoAccount: _fillDemoAccount,
                                  onConfigureEnvironment: _openEndpointSettings,
                                  onCheckConnection: _checkConnection,
                                  onSelectEnvironment:
                                      widget.onSelectEnvironment,
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: _BrandPanel(
                                    environmentConfig: widget.environmentConfig,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 9,
                                  child: _LoginPanel(
                                    formKey: _formKey,
                                    phoneController: _phoneController,
                                    passwordController: _passwordController,
                                    rememberMe: _rememberMe,
                                    obscurePassword: _obscurePassword,
                                    isSubmitting: widget.isSubmitting,
                                    isCheckingConnection: _isCheckingConnection,
                                    environmentConfig: widget.environmentConfig,
                                    onRememberChanged: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    onPasswordVisibilityPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    onPrimaryAction: _submit,
                                    onOpenRegister: _openRegisterPage,
                                    onFillDemoAccount: _fillDemoAccount,
                                    onConfigureEnvironment:
                                        _openEndpointSettings,
                                    onCheckConnection: _checkConnection,
                                    onSelectEnvironment:
                                        widget.onSelectEnvironment,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.environmentConfig});

  final ApiEnvironmentConfig environmentConfig;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF6F2EA);

    final titleStyle =
        Theme.of(context).textTheme.displaySmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
          height: 1.02,
          letterSpacing: -1.6,
          fontFamilyFallback: const [
            'SF Pro Display',
            'PingFang SC',
            'Avenir Next',
            'Roboto',
          ],
        ) ??
        const TextStyle(color: ink, fontSize: 38, fontWeight: FontWeight.w800);

    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFF4E7D1)),
                SizedBox(width: 10),
                Text(
                  'TechFlow Mobile Workspace',
                  style: TextStyle(
                    color: Color(0xFFF7F3EC),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          Text('测试环境、生产环境、\n本地联调同页切换。', style: titleStyle),
          const SizedBox(height: 16),
          Text(
            '我已经按部署文档把环境拓扑接进 App：本地走开发机，测试环境走服务器 `:8080`，生产环境走默认 `:80`。登录页切换环境后，登录会直接命中对应接口。',
            style: TextStyle(
              color: ink.withValues(alpha: 0.78),
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          _EndpointSummary(
            title: '本地环境',
            subtitle:
                environmentConfig.endpointLabel(ApiEnvironment.local) ?? '未配置',
            active:
                environmentConfig.selectedEnvironment == ApiEnvironment.local,
          ),
          const SizedBox(height: 12),
          _EndpointSummary(
            title: '测试环境',
            subtitle:
                environmentConfig.endpointLabel(ApiEnvironment.staging) ??
                '待配置服务器主机 -> http://<服务器主机>:8080',
            active:
                environmentConfig.selectedEnvironment == ApiEnvironment.staging,
          ),
          const SizedBox(height: 12),
          _EndpointSummary(
            title: '生产环境',
            subtitle:
                environmentConfig.endpointLabel(ApiEnvironment.production) ??
                '待配置服务器主机 -> http://<服务器主机>',
            active:
                environmentConfig.selectedEnvironment ==
                ApiEnvironment.production,
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.phoneController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.isCheckingConnection,
    required this.environmentConfig,
    required this.onRememberChanged,
    required this.onPasswordVisibilityPressed,
    required this.onPrimaryAction,
    required this.onOpenRegister,
    required this.onFillDemoAccount,
    required this.onConfigureEnvironment,
    required this.onCheckConnection,
    required this.onSelectEnvironment,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool isCheckingConnection;
  final ApiEnvironmentConfig environmentConfig;
  final VoidCallback onRememberChanged;
  final VoidCallback onPasswordVisibilityPressed;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onOpenRegister;
  final VoidCallback onFillDemoAccount;
  final VoidCallback onConfigureEnvironment;
  final Future<void> Function() onCheckConnection;
  final Future<void> Function(ApiEnvironment environment) onSelectEnvironment;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF132136);
    final selectedEnvironment = environmentConfig.selectedEnvironment;
    final selectedEndpointLabel =
        environmentConfig.endpointLabel() ?? '请先配置服务器主机';
    final canLogin = environmentConfig.isSelectedEnvironmentConfigured;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '欢迎回来',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '当前登录和注册都已接入真实后端接口。你可以在这里切到本地、测试环境或生产环境，再直接执行登录或打开 H5 注册。',
              style: TextStyle(
                color: ink.withValues(alpha: 0.66),
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '选择环境',
              style: TextStyle(
                color: Color(0xFF132136),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ApiEnvironment>(
              segments: ApiEnvironment.values
                  .map(
                    (environment) => ButtonSegment<ApiEnvironment>(
                      value: environment,
                      label: Text(environment.shortLabel),
                    ),
                  )
                  .toList(),
              selected: {selectedEnvironment},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                onSelectEnvironment(selection.first);
              },
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selectedEnvironment == ApiEnvironment.local
                        ? Icons.memory_rounded
                        : Icons.cloud_done_rounded,
                    color: const Color(0xFF132136),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedEnvironment.label}接口',
                          style: const TextStyle(
                            color: Color(0xFF132136),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedEndpointLabel,
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.72),
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!canLogin) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF6B36A).withValues(alpha: 0.28),
                  ),
                ),
                child: const Text(
                  '仓库里只定义了部署拓扑，没有提交真实公网 IP。要连接测试环境或生产环境，请先点击“配置服务器地址”，填写服务器公网 IP 或域名。',
                  style: TextStyle(
                    color: Color(0xFF132136),
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('填充演示账号'),
                  onPressed: isSubmitting ? null : onFillDemoAccount,
                ),
                ActionChip(
                  avatar: Icon(
                    selectedEnvironment == ApiEnvironment.local
                        ? Icons.settings_ethernet_rounded
                        : Icons.dns_rounded,
                    size: 18,
                  ),
                  label: Text(
                    selectedEnvironment == ApiEnvironment.local
                        ? '修改本地地址'
                        : '配置服务器地址',
                  ),
                  onPressed: isSubmitting ? null : onConfigureEnvironment,
                ),
                ActionChip(
                  avatar: isCheckingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: Text(isCheckingConnection ? '检查中...' : '检查环境连接'),
                  onPressed: isSubmitting || isCheckingConnection
                      ? null
                      : onCheckConnection,
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: '手机号',
                hintText: '13965026764',
                prefixIcon: Icon(Icons.phone_iphone_rounded),
              ),
              validator: (value) {
                final normalized = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (normalized.isEmpty) {
                  return '请输入手机号';
                }
                if (!RegExp(r'^1\d{10}$').hasMatch(normalized)) {
                  return '请输入有效的 11 位手机号';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: '登录密码',
                hintText: '请输入至少 6 位密码',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: onPasswordVisibilityPressed,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return '请输入登录密码';
                }
                if ((value ?? '').trim().length < 6) {
                  return '密码至少 6 位';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: isSubmitting ? null : onRememberChanged,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: rememberMe
                                ? const Color(0xFF132136)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: rememberMe
                                  ? const Color(0xFF132136)
                                  : ink.withValues(alpha: 0.2),
                            ),
                          ),
                          child: rememberMe
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '记住登录状态',
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  selectedEnvironment.shortLabel,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isSubmitting
                  ? null
                  : canLogin
                  ? onPrimaryAction
                  : onConfigureEnvironment,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      canLogin
                          ? Icons.arrow_forward_rounded
                          : Icons.settings_input_component_rounded,
                    ),
              label: Text(
                isSubmitting
                    ? '登录中...'
                    : canLogin
                    ? '登录并进入${selectedEnvironment.label}'
                    : '先配置${selectedEnvironment.label}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : canLogin
                  ? () {
                      onOpenRegister();
                    }
                  : onConfigureEnvironment,
              icon: Icon(
                canLogin
                    ? Icons.app_registration_rounded
                    : Icons.settings_input_component_rounded,
              ),
              label: Text(
                canLogin ? '打开 H5 注册页' : '先配置${selectedEnvironment.label}再注册',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEE6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF132136),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.developer_mode_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '仓库部署规则：staging 对外端口 8080，production 对外端口 80。默认演示账号仍是 13965026764 / 123456；新用户也可以通过上面的 H5 注册页直接入库，再自动回到 App。',
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.74),
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndpointSummary extends StatelessWidget {
  const _EndpointSummary({
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: active ? 0.18 : 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
