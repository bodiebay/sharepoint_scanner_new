import 'package:flutter/material.dart';
import 'package:sharepoint_scanner_new/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  String _status = 'Not logged in';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    
    final isAuthenticated = await _authService.initialize();
    
    setState(() {
      _status = isAuthenticated ? 'Logged in' : 'Not logged in';
      _isLoading = false;
    });
    
    // If already authenticated, navigate to barcode scanner
    if (isAuthenticated) {
      _navigateToScanner();
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final success = await _authService.login(context);
    
    if (success && _authService.isAuthenticated) {
      setState(() => _status = 'Logged in');
      
      // Show success dialog and then navigate to scanner
      _authService.showSuccessDialog(context, _navigateToScanner);
    } else {
      setState(() => _isLoading = false);
    }
  }
  
  void _navigateToScanner() {
    // Navigate to your barcode scanner screen
    Navigator.pushReplacementNamed(context, '/scanner');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SharePoint Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: const Text('Login with Microsoft'),
            ),
          ],
        ),
      ),
    );
  }
}
