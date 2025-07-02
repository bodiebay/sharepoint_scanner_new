import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:talker/talker.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Configuration for Microsoft OAuth authentication.
class MicrosoftAuthConfig {
  static const String clientId = '3c82ea21-fb37-4e3d-bbe2-bd4dc7237185';
  static const String tenantId = '873ebc3c-13b9-43e6-865c-1e26b0185b40';
  static const String redirectUri = 'msauth://com.aaronwalker.inventoryscannernew/auth';
  static const String scope = 'https://graph.microsoft.com/Sites.ReadWrite.All offline_access';
  
  // OAuth endpoints
  static String get authorizeUrl => 
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize';
  static String get tokenUrl => 
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token';
}

/// Manages authentication state and operations for the app.
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _talker = Talker();
  
  // Authentication state
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _accessToken;
  String? _refreshToken;
  
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;

  /// Initialize the auth service, checking for existing tokens
  Future<bool> initialize() async {
    _isLoading = true;
    try {
      _accessToken = await _storage.read(key: 'access_token');
      _refreshToken = await _storage.read(key: 'refresh_token');
      
      if (_accessToken != null) {
        _isAuthenticated = true;
        _talker.info('Auth service initialized with existing token');
        return true;
      }
    } catch (e) {
      _talker.error('Error initializing auth service: $e');
    } finally {
      _isLoading = false;
    }
    return false;
  }

  /// Start the login process by showing a WebView for Microsoft OAuth
  Future<bool> login(BuildContext context) async {
    _isLoading = true;
    bool success = false;
    
    try {
      _talker.info('Starting Microsoft OAuth login');
      final params = {
        'client_id': MicrosoftAuthConfig.clientId,
        'response_type': 'code',
        'redirect_uri': MicrosoftAuthConfig.redirectUri,
        'scope': MicrosoftAuthConfig.scope,
        'response_mode': 'query',
      };
      
      final url = Uri.parse('${MicrosoftAuthConfig.authorizeUrl}').replace(
        queryParameters: params,
      ).toString();
      
      // Create a controller for the WebView
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(url))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _talker.info('WebView finished: $url');
            },
            onNavigationRequest: (NavigationRequest request) {
              _talker.info('Navigating to: ${request.url}');
              
              // Handle redirect back to app
              if (request.url.startsWith(MicrosoftAuthConfig.redirectUri)) {
                _handleAuthRedirect(request.url);
                Navigator.pop(context, true); // Close the WebView dialog
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );
      
      // Show the WebView in a dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Login with Microsoft'),
          content: SizedBox(
            height: 400,
            width: 350,
            child: WebViewWidget(controller: controller),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      success = result ?? false;
    } catch (e) {
      _talker.error('Login error: $e');
      _showErrorDialog(context, 'Login failed', 'Please check your network connection and try again.');
    } finally {
      _isLoading = false;
    }
    
    return success;
  }

  /// Handle the OAuth redirect with auth code
  Future<void> _handleAuthRedirect(String url) async {
    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        _talker.error('OAuth error: $error');
        return;
      }
      
      if (code != null) {
        _talker.info('Auth code received, exchanging for token...');
        await _exchangeCodeForToken(code);
      }
    } catch (e) {
      _talker.error('Error handling auth redirect: $e');
    }
  }

  /// Exchange authorization code for access and refresh tokens
  Future<void> _exchangeCodeForToken(String code) async {
    try {
      // In a real implementation, you would make an HTTP request to the token endpoint
      // For this example, we'll simulate a successful token exchange
      
      // Simulate successful token response
      const mockAccessToken = 'mock_access_token_for_demo';
      const mockRefreshToken = 'mock_refresh_token_for_demo';
      
      // Store tokens securely
      await _storage.write(key: 'access_token', value: mockAccessToken);
      await _storage.write(key: 'refresh_token', value: mockRefreshToken);
      
      // Update state
      _accessToken = mockAccessToken;
      _refreshToken = mockRefreshToken;
      _isAuthenticated = true;
      
      _talker.info('Token exchange successful');
    } catch (e) {
      _talker.error('Token exchange failed: $e');
    }
  }

  /// Show error dialog for authentication failures
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Log out the current user
  Future<void> logout() async {
    try {
      // Clear stored tokens
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      
      // Update state
      _accessToken = null;
      _refreshToken = null;
      _isAuthenticated = false;
      
      _talker.info('User logged out');
    } catch (e) {
      _talker.error('Logout error: $e');
    }
  }

  /// Show success dialog after successful authentication
  void showSuccessDialog(BuildContext context, Function() onContinue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('✅ Authentication completed!'),
            SizedBox(height: 12),
            Text('Ready to build your SharePoint scanner app!'),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onContinue();
            },
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Start Building!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }
}
