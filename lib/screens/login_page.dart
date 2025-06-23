import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talker/talker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class AuthConfig {
  static const String clientId = '3c82ea21-fb37-4e3d-bbe2-bd4dc7237185';
  static const String tenantId = '873ebc3c-13b9-43e6-865c-1e26b0185b40';
  static const String redirectUri = 'msauth://com.aaronwalker.inventoryscannernew/auth';
  static const String scope = 'https://graph.microsoft.com/.default';
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _storage = FlutterSecureStorage();
  final _talker = Talker();
  String _status = 'Not logged in';
  bool _isLoading = false;
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        setState(() => _status = 'Logged in');
        _talker.info('Auto-login successful');
      }
    } catch (e) {
      _talker.error('Error checking auth state: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      _talker.info('Starting Microsoft OAuth login');
      final params = {
        'client_id': AuthConfig.clientId,
        'response_type': 'code',
        'redirect_uri': AuthConfig.redirectUri,
        'scope': AuthConfig.scope,
        'response_mode': 'query',
      };
      final url = Uri.https(
        'login.microsoftonline.com',
        '/${AuthConfig.tenantId}/oauth2/v2.0/authorize',
        params,
      ).toString();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logging in'),
          content: SizedBox(
            height: 200,
            width: 300,
            child: WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController controller) {
                _controller = controller;
                _talker.info('WebView created');
              },
              onPageFinished: (String url) {
                _talker.info('WebView finished: $url');
                if (url.startsWith(AuthConfig.redirectUri)) {
                  _talker.info('Redirect detected');
                  Navigator.pop(context);
                }
              },
              navigationDelegate: (NavigationRequest request) {
                _talker.info('Navigating to: ${request.url}');
                return NavigationDecision.navigate;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _talker.error('Login error: ${e.toString()}');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: Check network or Azure config')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SharePoint Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: Text('Login with Microsoft'),
            ),
          ],
        ),
      ),
    );
  }
}
