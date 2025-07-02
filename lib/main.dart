import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sharepoint_scanner_new/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SharePoint Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const SharePointLoginScreen(),
        '/scanner': (context) => const BarcodeScannerScreen(),
        '/result': (context) => const ScanResultScreen(),
      },
      initialRoute: '/',
    );
  }
}

class SharePointLoginScreen extends StatefulWidget {
  const SharePointLoginScreen({super.key});

  @override
  State<SharePointLoginScreen> createState() => _SharePointLoginScreenState();
}

class _SharePointLoginScreenState extends State<SharePointLoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() => _isLoading = true);
    
    final isAuthenticated = await _authService.initialize();
    
    if (isAuthenticated) {
      _navigateToMainApp();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final success = await _authService.login(context);
    
    if (success && _authService.isAuthenticated) {
      _authService.showSuccessDialog(context, _navigateToMainApp);
    }
    
    setState(() => _isLoading = false);
  }

  void _navigateToMainApp() {
    // Navigate to the barcode scanner screen
    Navigator.pushReplacementNamed(context, '/scanner');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SharePoint Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to SharePoint Scanner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan barcodes and update SharePoint lists easily',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login),
                label: const Text('Login with Microsoft'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Real barcode scanner implementation using mobile_scanner
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                return Icon(
                  state == CameraFacing.front
                      ? Icons.camera_front
                      : Icons.camera_rear,
                );
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().logout().then((_) {
                Navigator.pushReplacementNamed(context, '/');
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (_isProcessing) return;
                _isProcessing = true;

                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  final code = barcode.rawValue;
                  if (code != null) {
                    _handleBarcode(code);
                  }
                }
              },
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.1),
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Position the barcode within the scanner frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, 
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBarcode(String code) {
    // Navigate to result screen with the scanned code
    Navigator.pushNamed(
      context,
      '/result',
      arguments: code,
    ).then((_) {
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Screen to display scan results and handle SharePoint updates
class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final scannedCode = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanned Barcode:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              width: double.infinity,
              child: Text(
                scannedCode,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Item Information:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // This is where you would display item information from SharePoint
            // For now, we'll just show some example fields
            _buildInfoField('Item Type', 'Office Equipment'),
            _buildInfoField('Location', 'Main Office'),
            _buildInfoField('Status', 'In Stock'),
            _buildInfoField('Last Updated', '2025-07-01'),
            const SizedBox(height: 24),
            Center(
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _updateSharePointList(scannedCode);
                          },
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Update SharePoint'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Another'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSharePointList(String scannedCode) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Simulate an API call to update SharePoint
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SharePoint list updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Return to scanner screen after successful update
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating SharePoint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
