import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/auth_provider.dart';
import 'google_logo.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    if (_isLoading || widget.isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await context.read<AuthProvider>().signInWithGoogle();

      setState(() => _isLoading = false);

      if (result['success']) {
        // Check if email verification is required
        if (result['requiresEmailVerification'] == true) {
          // Navigate to email verification screen
          if (mounted) {
            Navigator.of(context).pushNamed(
              '/email_verification',
              arguments: {
                'email': result['email'] ?? '',
                'uid': result['uid'] ?? '',
              },
            );
          }
        } else {
          // Already verified or no verification needed
          if (!mounted) return;
          final user = context.read<AuthProvider>().user;
          if (user?.role == 'user') {
            Navigator.of(context).pushReplacementNamed('/user_home');
          } else if (user?.role == 'petugas') {
            Navigator.of(context).pushReplacementNamed('/petugas_home');
          } else if (user?.role == 'admin') {
            Navigator.of(context).pushReplacementNamed('/admin_home');
          }
        }

        widget.onSuccess?.call();
      } else {
        if (mounted) {
          final errorMsg = result['message'] ?? 'Google sign-in gagal';
          final errorCode = result['error'] ?? 'UNKNOWN';
          widget.onError?.call(errorMsg);

          _showErrorDialog(context, errorMsg, errorCode);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMsg = 'Error: ${e.toString()}';
        widget.onError?.call(errorMsg);
        _showErrorDialog(context, errorMsg, 'EXCEPTION');
      }
    }
  }

  void _showErrorDialog(
    BuildContext context,
    String message,
    String errorCode,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('❌ Error Google Sign-In'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Error code for debugging
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Code: $errorCode',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),

              // Troubleshooting tips based on error code
              if (errorCode == 'DEVELOPER_ERROR') ...[
                const Text(
                  '🔧 Troubleshooting:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Ambil SHA-1 fingerprint:\n'
                  '   • Run: flutter doctor -v\n'
                  '   • Find "SHA-1" line\n\n'
                  '2. Register di Firebase:\n'
                  '   • Go to Firebase Console\n'
                  '   • Project Settings > Your Apps\n'
                  '   • Add SHA-1 fingerprint\n\n'
                  '3. Restart aplikasi setelah update',
                  style: TextStyle(fontSize: 11),
                ),
              ] else if (errorCode == 'PERMISSION_DENIED') ...[
                const Text(
                  '🔒 Troubleshooting:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Firestore security rules belum dikonfigurasi.\n\n'
                  'Buka file:\nSETUP_FIRESTORE_RULES.md\n\n'
                  'Lalu copy-paste rules ke Firestore Console.',
                  style: TextStyle(fontSize: 11),
                ),
              ] else if (errorCode == 'NETWORK_ERROR') ...[
                const Text(
                  '📡 Troubleshooting:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Check internet connection\n'
                  '2. Try again in a few moments\n'
                  '3. If problem persists, restart app',
                  style: TextStyle(fontSize: 11),
                ),
              ] else if (errorCode == 'CANCELLED') ...[
                const Text(
                  'ℹ️ Info:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda membatalkan proses sign-in.\n'
                  'Silakan coba lagi.',
                  style: TextStyle(fontSize: 11),
                ),
              ] else ...[
                const Text(
                  '❓ Unknown Error',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Check console logs untuk detail\n'
                  '2. Restart aplikasi\n'
                  '3. Pastikan config Firebase benar',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          if (errorCode == 'DEVELOPER_ERROR')
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Check console logs: flutter logs | grep "=== Google Sign-In"',
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
              },
              child: const Text('View Logs'),
            ),
          if (errorCode == 'PERMISSION_DENIED')
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Open: SETUP_FIRESTORE_RULES.md in project folder',
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
              },
              child: const Text('Setup Guide'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading || widget.isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: _isLoading || widget.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4285F4),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GoogleLogo(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Masuk dengan Google',
                        style: TextStyle(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
