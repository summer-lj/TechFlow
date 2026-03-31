import 'package:flutter/material.dart';

import '../core/api_config.dart';
import '../core/api_client.dart';
import '../core/models.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.session,
    required this.environmentConfig,
    required this.isLoggingOut,
    required this.onLogout,
    required this.onSessionExpired,
    required this.onUserSynced,
  });

  final AuthSession session;
  final ApiEnvironmentConfig environmentConfig;
  final bool isLoggingOut;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSessionExpired;
  final Future<void> Function(AppUser user) onUserSynced;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppUser? _currentUser;
  AppHomePayload? _homePayload;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.session.user;
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final apiBaseUrl = widget.environmentConfig.tryResolveApiBaseUrl();
    if (apiBaseUrl == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '当前环境缺少可用接口地址，请先回到登录页完成配置。';
        _isLoading = false;
      });
      return;
    }

    final client = ApiClient(baseUrl: apiBaseUrl);

    try {
      final homePayload = await client.fetchAppHome();
      AppUser currentUser = _currentUser ?? widget.session.user;
      String? warningMessage;

      try {
        currentUser = await client.fetchCurrentUser(
          accessToken: widget.session.tokens.accessToken,
        );
        await widget.onUserSynced(currentUser);
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          await widget.onSessionExpired();
          return;
        }
        warningMessage = '当前用户信息刷新失败，已显示登录时缓存的账号信息。';
      } catch (_) {
        warningMessage = '当前用户信息刷新失败，已显示登录时缓存的账号信息。';
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _homePayload = homePayload;
        _currentUser = currentUser;
        _errorMessage = warningMessage;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await widget.onSessionExpired();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '首页加载失败，请稍后重试。';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser ?? widget.session.user;
    final homePayload = _homePayload;
    final quickActions = homePayload?.quickActions ?? const <HomeQuickAction>[];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08121E), Color(0xFF10263B), Color(0xFFEFE5D6)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFFEC6F4A),
            onRefresh: _loadHomeData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(
                          user: user,
                          environmentConfig: widget.environmentConfig,
                          isLoggingOut: widget.isLoggingOut,
                          onLogout: widget.onLogout,
                        ),
                        const SizedBox(height: 18),
                        _HeroSummary(
                          user: user,
                          homePayload: homePayload,
                          environmentConfig: widget.environmentConfig,
                        ),
                        const SizedBox(height: 16),
                        _StatsRow(
                          homePayload: homePayload,
                          tokenSeconds: widget.session.tokens.expiresIn,
                        ),
                        const SizedBox(height: 16),
                        _ActionPanel(
                          isLoggingOut: widget.isLoggingOut,
                          onRefresh: _loadHomeData,
                          onLogout: widget.onLogout,
                        ),
                        const SizedBox(height: 16),
                        _AccountSummaryCard(
                          user: user,
                          environmentConfig: widget.environmentConfig,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(
                            message: _errorMessage!,
                            onRetry: _loadHomeData,
                          ),
                        ],
                        if (_isLoading && homePayload == null) ...[
                          const SizedBox(height: 60),
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ] else if (homePayload != null) ...[
                          const SizedBox(height: 18),
                          ...homePayload.sections.map(_buildSection),
                        ] else ...[
                          const SizedBox(height: 18),
                          _EmptyHomeState(onRefresh: _loadHomeData),
                        ],
                        const SizedBox(height: 18),
                        _QuickActionsCard(
                          actions: quickActions,
                          onRefresh: _loadHomeData,
                          onLogout: widget.onLogout,
                          isLoggingOut: widget.isLoggingOut,
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(HomeSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF132136),
              ),
            ),
            const SizedBox(height: 16),
            ...section.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SectionItemCard(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.user,
    required this.environmentConfig,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final AppUser user;
  final ApiEnvironmentConfig environmentConfig;
  final bool isLoggingOut;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final logoutButton = FilledButton.tonalIcon(
      onPressed: isLoggingOut ? null : onLogout,
      icon: isLoggingOut
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout_rounded),
      label: Text(isLoggingOut ? '退出中...' : '退出登录'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TechFlow 首页',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '欢迎回来，${user.name}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            environmentConfig.selectedEnvironment.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerRight, child: logoutButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            logoutButton,
          ],
        );
      },
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.isLoggingOut,
    required this.onRefresh,
    required this.onLogout,
  });

  final bool isLoggingOut;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('刷新首页'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: isLoggingOut ? null : onLogout,
              icon: isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(isLoggingOut ? '退出中...' : '退出登录'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({
    required this.user,
    required this.environmentConfig,
  });

  final AppUser user;
  final ApiEnvironmentConfig environmentConfig;

  @override
  Widget build(BuildContext context) {
    final apiBaseUrl = environmentConfig.tryResolveApiBaseUrl();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前登录账号',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132136),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetaChip(icon: Icons.person_outline_rounded, label: user.name),
              _MetaChip(icon: Icons.badge_rounded, label: user.roleLabel),
              _MetaChip(icon: Icons.phone_iphone_rounded, label: user.phone),
              _MetaChip(
                icon: Icons.mail_outline_rounded,
                label: user.email.isEmpty ? '未绑定邮箱' : user.email,
              ),
              _MetaChip(
                icon: Icons.cloud_done_rounded,
                label: environmentConfig.selectedEnvironment.label,
              ),
              _MetaChip(
                icon: Icons.link_rounded,
                label: apiBaseUrl == null
                    ? '未配置接口地址'
                    : describeApiEndpoint(apiBaseUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF132136)),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF132136),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.user,
    required this.homePayload,
    required this.environmentConfig,
  });

  final AppUser user;
  final AppHomePayload? homePayload;
  final ApiEnvironmentConfig environmentConfig;

  @override
  Widget build(BuildContext context) {
    final hero = homePayload?.hero;
    final currentApiBaseUrl = environmentConfig.tryResolveApiBaseUrl();
    final currentEndpointLabel = currentApiBaseUrl == null
        ? '未配置服务器主机'
        : describeApiEndpoint(currentApiBaseUrl);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6EFE4), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF132136),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF132136),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.roleLabel} · ${user.phone}',
                      style: TextStyle(
                        color: const Color(0xFF132136).withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            hero?.title ?? '正在从后端读取首页内容',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF132136),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hero?.subtitle ?? '登录完成后，这里会展示由 /api/v1/app/home 返回的服务端文案与模块。',
            style: TextStyle(
              color: const Color(0xFF132136).withValues(alpha: 0.7),
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF132136).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.lan_rounded, color: Color(0xFF132136)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentEndpointLabel,
                    style: const TextStyle(
                      color: Color(0xFF132136),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '部署规则来自仓库配置：测试环境走服务器 `:8080`，生产环境走默认 `:80`，App 会自动拼接 `/api/v1`。',
            style: TextStyle(
              color: const Color(0xFF132136).withValues(alpha: 0.64),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.homePayload, required this.tokenSeconds});

  final AppHomePayload? homePayload;
  final int tokenSeconds;

  @override
  Widget build(BuildContext context) {
    final sectionsCount = homePayload?.sections.length ?? 0;
    final actionsCount = homePayload?.quickActions.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: '首页区块',
            value: '$sectionsCount',
            tone: const Color(0xFF56D5C5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: '快捷动作',
            value: '$actionsCount',
            tone: const Color(0xFFEC6F4A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Access Token',
            value: '${tokenSeconds}s',
            tone: const Color(0xFFF6B36A),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132136),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF132136).withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionItemCard extends StatelessWidget {
  const _SectionItemCard({required this.item});

  final HomeSectionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
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
              Icons.arrow_upward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.tag != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132136).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.tag!,
                      style: const TextStyle(
                        color: Color(0xFF132136),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF132136),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description!,
                    style: TextStyle(
                      color: const Color(0xFF132136).withValues(alpha: 0.7),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.actions,
    required this.onRefresh,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final List<HomeQuickAction> actions;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions.isEmpty
        ? const <HomeQuickAction>[
            HomeQuickAction(
              label: '首页元信息待返回',
              method: 'GET',
              path: '/api/v1/app/home',
              requiresAuth: false,
            ),
          ]
        : actions;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷入口',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132136),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下面的接口元信息来自 /api/v1/app/home，页面本身的退出登录入口直接调用 /api/v1/auth/logout。',
            style: TextStyle(
              color: const Color(0xFF132136).withValues(alpha: 0.68),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibleActions
                .map(
                  (action) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${action.method} ${action.label}',
                      style: const TextStyle(
                        color: Color(0xFF132136),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('刷新首页'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoggingOut ? null : onLogout,
                  icon: isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.logout_rounded),
                  label: Text(isLoggingOut ? '退出中...' : '退出登录'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '首页内容暂未加载出来',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF132136),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '登录已经成功，说明统一认证链路是通的。当前页面会保留账号信息和退出入口，你可以先刷新一次首页，稍后我也会继续把这里的服务端内容对齐得更完整。',
            style: TextStyle(
              color: const Color(0xFF132136).withValues(alpha: 0.7),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新拉取首页内容'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEC6F4A).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEC6F4A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF132136),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
