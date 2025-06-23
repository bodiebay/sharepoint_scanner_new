import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SharePoint Scanner',
      home: SharePointLoginScreen(),
    );
  }
}

class SharePointLoginScreen extends StatefulWidget {
  @override
  _SharePointLoginScreenState createState() => _SharePointLoginScreenState();
}

class _SharePointLoginScreenState extends State<SharePointLoginScreen> {
  late WebViewController _controller;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            
            if (request.url.startsWith('msauth://com.aaronwalker.inventoryscannernew/auth')) {
              print('🎯 OAuth redirect detected!');
              _handleOAuthRedirect(request.url);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  void _handleOAuthRedirect(String url) {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        _showErrorDialog('Authentication failed', 'Error: $error');
      } else if (code != null) {
        setState(() {
          _isAuthenticated = true;
        });
        // IMMEDIATE SUCCESS - No delay!
        _showSuccessDialog(code);
      } else {
        _showErrorDialog('Invalid Response', 'No authorization code received');
      }
    } catch (e) {
      _showErrorDialog('Parse Error', 'Failed to parse OAuth response: $e');
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅ Authentication completed!'),
              SizedBox(height: 12),
              Text('Ready to build your SharePoint scanner app!'),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToMainApp(code);
              },
              icon: Icon(Icons.rocket_launch),
              label: Text('Start Building!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetLogin();
              },
              child: Text('Login Again'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetLogin();
              },
              child: Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToMainApp(String authCode) {
    // Store the auth code for later use
    print('🎯 Auth code ready: ${authCode.substring(0, 30)}...');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🎉 OAuth Setup Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your SharePoint Scanner is ready!'),
              SizedBox(height: 16),
              Text('Next steps:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Build barcode scanning screen'),
              Text('• Add SharePoint list integration'),
              Text('• Implement inventory updates'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  'OAuth working perfectly! ✅',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Awesome!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetLogin() {
    setState(() {
      _isAuthenticated = false;
      _isLoading = false;
    });
  }

  void _login() {
    setState(() {
      _isLoading = true;
    });

    final authUrl = 'https://login.microsoftonline.com/873ebc3c-13b9-43e6-865c-1e26b0185b40/oauth2/v2.0/authorize'
        '?client_id=3c82ea21-fb37-4e3d-bbe2-bd4dc7237185'
        '&response_type=code'
        '&redirect_uri=msauth://com.aaronwalker.inventoryscannernew/auth'
        '&response_mode=query'
        '&scope=https://graph.microsoft.com/Sites.ReadWrite.All offline_access'
        '&state=12345';

    _controller.loadRequest(Uri.parse(authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SharePoint Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text(
                  _isAuthenticated 
                    ? '✅ Authentication successful!'
                    : 'Sign in to access SharePoint',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _isAuthenticated) ? null : _login,
                  icon: Icon(_isAuthenticated ? Icons.check : Icons.login),
                  label: Text(
                    _isAuthenticated 
                      ? 'Authenticated ✅'
                      : _isLoading 
                        ? 'Signing In...' 
                        : 'Sign In with Microsoft'
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAuthenticated ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isLoading) 
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
