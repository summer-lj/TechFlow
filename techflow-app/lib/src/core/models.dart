import 'dart:convert';

class LoginCredentials {
  const LoginCredentials({
    required this.phone,
    required this.password,
  });

  final String phone;
  final String password;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'TechFlow 用户',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      isActive: json['isActive'] == true,
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;

  String get roleLabel {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return '管理员';
      case 'OPERATOR':
        return '运营';
      default:
        return '成员';
    }
  }

  String get initials {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return 'TF';
    }
    return String.fromCharCode(normalized.runes.first).toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
    };
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      expiresIn: json['expiresIn'] is int
          ? json['expiresIn'] as int
          : int.tryParse(json['expiresIn']?.toString() ?? '') ?? 0,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.tokens,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>? ?? const {}),
    );
  }

  factory AuthSession.decode(String source) {
    return AuthSession.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  final AppUser user;
  final AuthTokens tokens;

  AuthSession copyWith({
    AppUser? user,
    AuthTokens? tokens,
  }) {
    return AuthSession(
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': tokens.toJson(),
    };
  }

  String encode() => jsonEncode(toJson());
}

class AppHeroData {
  const AppHeroData({
    required this.title,
    required this.subtitle,
    required this.recommendedFlow,
  });

  factory AppHeroData.fromJson(Map<String, dynamic> json) {
    return AppHeroData(
      title: json['title']?.toString() ?? 'TechFlow',
      subtitle: json['subtitle']?.toString() ?? '',
      recommendedFlow: (json['recommendedFlow'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final String title;
  final String subtitle;
  final List<String> recommendedFlow;
}

class HomeSectionItem {
  const HomeSectionItem({
    required this.title,
    this.description,
    this.tag,
  });

  factory HomeSectionItem.fromDynamic(dynamic value) {
    if (value is String) {
      return HomeSectionItem(title: value);
    }

    if (value is Map<String, dynamic>) {
      return HomeSectionItem(
        title: value['title']?.toString() ??
            value['label']?.toString() ??
            value['name']?.toString() ??
            '未命名条目',
        description: value['description']?.toString() ??
            value['subtitle']?.toString() ??
            value['path']?.toString(),
        tag: value['tag']?.toString() ?? value['method']?.toString(),
      );
    }

    return HomeSectionItem(title: value.toString());
  }

  final String title;
  final String? description;
  final String? tag;
}

class HomeSection {
  const HomeSection({
    required this.code,
    required this.title,
    required this.items,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '内容区块',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(HomeSectionItem.fromDynamic)
          .toList(),
    );
  }

  final String code;
  final String title;
  final List<HomeSectionItem> items;
}

class HomeQuickAction {
  const HomeQuickAction({
    required this.label,
    required this.method,
    required this.path,
    required this.requiresAuth,
  });

  factory HomeQuickAction.fromJson(Map<String, dynamic> json) {
    return HomeQuickAction(
      label: json['label']?.toString() ?? '操作',
      method: json['method']?.toString() ?? 'GET',
      path: json['path']?.toString() ?? '/',
      requiresAuth: json['requiresAuth'] == true,
    );
  }

  final String label;
  final String method;
  final String path;
  final bool requiresAuth;
}

class AppHomePayload {
  const AppHomePayload({
    required this.client,
    required this.hero,
    required this.sections,
    required this.quickActions,
  });

  factory AppHomePayload.fromJson(Map<String, dynamic> json) {
    return AppHomePayload(
      client: json['client']?.toString() ?? 'app',
      hero: AppHeroData.fromJson(json['hero'] as Map<String, dynamic>? ?? const {}),
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HomeSection.fromJson)
          .toList(),
      quickActions: (json['quickActions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HomeQuickAction.fromJson)
          .toList(),
    );
  }

  final String client;
  final AppHeroData hero;
  final List<HomeSection> sections;
  final List<HomeQuickAction> quickActions;
}
