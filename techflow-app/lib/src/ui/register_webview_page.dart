import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/models.dart';

class RegistrationWebViewPage extends StatefulWidget {
  const RegistrationWebViewPage({
    super.key,
    required this.environmentLabel,
    required this.registrationUrl,
  });

  final String environmentLabel;
  final String registrationUrl;

  @override
  State<RegistrationWebViewPage> createState() =>
      _RegistrationWebViewPageState();
}

class _RegistrationWebViewPageState extends State<RegistrationWebViewPage> {
  late final WebViewController _controller;

  bool _isLoading = true;
  String? _errorMessage;
  bool _hasCompletedRegistration = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'TechFlowRegister',
        onMessageReceived: _handleRegisterMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) {
              return;
            }

            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.registrationUrl));
  }

  void _handleRegisterMessage(JavaScriptMessage message) {
    if (_hasCompletedRegistration) {
      return;
    }

    try {
      final decoded = jsonDecode(message.message);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid register payload');
      }

      if (decoded['type']?.toString() != 'register-success') {
        return;
      }

      final sessionPayload = decoded['session'];

      if (sessionPayload is! Map) {
        throw const FormatException('Missing register session');
      }

      _hasCompletedRegistration = true;
      Navigator.of(
        context,
      ).pop(AuthSession.fromJson(Map<String, dynamic>.from(sessionPayload)));
    } catch (_) {
      _showSnack('注册已成功，但回传登录态失败，请返回后手动登录。');
    }
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _controller.loadRequest(Uri.parse(widget.registrationUrl));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final overlayMessage = _errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.environmentLabel}注册'),
        actions: [
          IconButton(
            tooltip: '刷新页面',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const ColoredBox(
              color: Colors.white,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (overlayMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132136),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '页面加载失败',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        overlayMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
