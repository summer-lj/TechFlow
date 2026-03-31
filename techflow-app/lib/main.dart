import 'package:flutter/material.dart';

void main() {
  runApp(const TechFlowApp());
}

class TechFlowApp extends StatelessWidget {
  const TechFlowApp({super.key});

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
      home: const LoginEntryPage(),
    );
  }
}

class LoginEntryPage extends StatefulWidget {
  const LoginEntryPage({super.key});

  @override
  State<LoginEntryPage> createState() => _LoginEntryPageState();
}

class _LoginEntryPageState extends State<LoginEntryPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showNotice(String message) {
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
            colors: [
              Color(0xFF07111F),
              Color(0xFF14324C),
              Color(0xFFF2E7D6),
            ],
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
                                _BrandPanel(isCompact: isCompact),
                                const SizedBox(height: 20),
                                _LoginPanel(
                                  accountController: _accountController,
                                  passwordController: _passwordController,
                                  rememberMe: _rememberMe,
                                  obscurePassword: _obscurePassword,
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
                                  onPrimaryAction: () =>
                                      _showNotice('登录流程已预留，下一步可接入真实接口。'),
                                  onSmsAction: () =>
                                      _showNotice('短信验证码登录入口暂未接入。'),
                                  onAppleAction: () =>
                                      _showNotice('Apple 登录入口暂未接入。'),
                                  onWorkspaceAction: () =>
                                      _showNotice('企业身份登录入口暂未接入。'),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Expanded(
                                  flex: 11,
                                  child: _BrandPanel(isCompact: false),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 9,
                                  child: _LoginPanel(
                                    accountController: _accountController,
                                    passwordController: _passwordController,
                                    rememberMe: _rememberMe,
                                    obscurePassword: _obscurePassword,
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
                                    onPrimaryAction: () => _showNotice(
                                      '登录流程已预留，下一步可接入真实接口。',
                                    ),
                                    onSmsAction: () =>
                                        _showNotice('短信验证码登录入口暂未接入。'),
                                    onAppleAction: () =>
                                        _showNotice('Apple 登录入口暂未接入。'),
                                    onWorkspaceAction: () =>
                                        _showNotice('企业身份登录入口暂未接入。'),
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
  const _BrandPanel({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF6F2EA);
    final titleStyle = (isCompact
            ? Theme.of(context).textTheme.headlineLarge
            : Theme.of(context).textTheme.displaySmall)
        ?.copyWith(
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
        );

    return Container(
      padding: EdgeInsets.all(isCompact ? 24 : 34),
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
          SizedBox(height: isCompact ? 22 : 34),
          Text(
            '把线索、协作与交付\n放进同一个入口。',
            style: titleStyle,
          ),
          const SizedBox(height: 16),
          Text(
            '一个更轻、更快、更有节奏感的业务工作台。先从顺滑登录开始，把团队带回统一的工作现场。',
            style: TextStyle(
              color: ink.withValues(alpha: 0.78),
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureTag(
                icon: Icons.flash_on_rounded,
                label: '线索秒级流转',
              ),
              _FeatureTag(
                icon: Icons.hub_rounded,
                label: '团队协作同步',
              ),
              _FeatureTag(
                icon: Icons.insights_rounded,
                label: '数据看板可追踪',
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const [
              _MetricCard(
                value: '12s',
                label: '从登录到进入工作区',
              ),
              _MetricCard(
                value: '24/7',
                label: '移动端随时处理任务',
              ),
              _MetricCard(
                value: '1 个',
                label: '统一入口连接全部流程',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.accountController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberChanged,
    required this.onPasswordVisibilityPressed,
    required this.onPrimaryAction,
    required this.onSmsAction,
    required this.onAppleAction,
    required this.onWorkspaceAction,
  });

  final TextEditingController accountController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final VoidCallback? onRememberChanged;
  final VoidCallback? onPasswordVisibilityPressed;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSmsAction;
  final VoidCallback? onAppleAction;
  final VoidCallback? onWorkspaceAction;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF132136);

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
            '登录 TechFlow，继续跟进你的客户线索、待办事项和团队进度。',
            style: TextStyle(
              color: ink.withValues(alpha: 0.66),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: accountController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '手机号或邮箱',
              hintText: 'name@company.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: '登录密码',
              hintText: '请输入至少 8 位密码',
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
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onRememberChanged,
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
                        '记住我',
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
              TextButton(
                onPressed: () {},
                child: const Text('忘记密码'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPrimaryAction,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('立即登录'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSmsAction,
            icon: const Icon(Icons.sms_outlined),
            label: const Text('短信验证码登录'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Divider(color: ink.withValues(alpha: 0.12)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '其他方式',
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.48),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: ink.withValues(alpha: 0.12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.apple_rounded,
                  label: 'Apple',
                  onPressed: onAppleAction,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.approval_outlined,
                  label: '企业身份',
                  onPressed: onWorkspaceAction,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
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
                    Icons.north_east_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '首次使用？联系管理员开通组织空间，或者先申请体验账号。',
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
    );
  }
}

class _FeatureTag extends StatelessWidget {
  const _FeatureTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF4E7D1)),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF7F3EC),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
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
