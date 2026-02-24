import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'login_success_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onSwitchToRegister,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isHoveringRegisterLink = false;
  String? _errorMessage;
  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;

  @override
  void initState() {
    super.initState();
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _errorAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _errorAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _errorAnimationController.dispose();
    super.dispose();
  }

  String _parseFirebaseError(dynamic error) {
    String errorMessage = error.toString();

    // Parse Firebase error codes
    if (errorMessage.contains('user-not-found')) {
      return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Password yang Anda masukkan salah. Coba lagi.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Format email tidak valid.';
    } else if (errorMessage.contains('user-disabled')) {
      return 'Akun Anda telah dinonaktifkan. Hubungi admin.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan gagal. Coba lagi nanti.';
    } else if (errorMessage.contains('network')) {
      return 'Koneksi internet Anda tidak stabil. Cek koneksi dan coba lagi.';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return 'Login dengan email dan password sedang dinonaktifkan.';
    } else {
      return 'Login gagal: $errorMessage';
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _errorAnimationController.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismissError();
      }
    });
  }

  void _dismissError() {
    _errorAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseService().loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted && userCredential != null) {
        _showLoginSuccessScreen(userCredential);
      }
    } catch (e) {
      if (mounted) {
        final friendlyErrorMessage = _parseFirebaseError(e);
        _showError(friendlyErrorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLoginSuccessScreen(UserCredential userCredential) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginSuccessScreen(
          user: userCredential.user!,
          onContinue: widget.onLoginSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or App Title
                Text(
                  'Aplikasi Saya',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan email Anda',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password Anda',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Error Message with Animation
                if (_errorMessage != null)
                  FadeTransition(
                    opacity: _errorAnimation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, -0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _errorAnimationController,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Login Gagal',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              onPressed: _dismissError,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Switch to Register Link
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Belum punya akun?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            _isHoveringRegisterLink = true;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            _isHoveringRegisterLink = false;
                          });
                        },
                        child: GestureDetector(
                          onTap: widget.onSwitchToRegister,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _isHoveringRegisterLink
                                  ? Colors.deepPurple.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: _isHoveringRegisterLink
                                    ? Colors.deepPurple
                                    : Colors.deepPurple.withValues(alpha: 0.5),
                                width: _isHoveringRegisterLink ? 2 : 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_add_outlined,
                                  color: Colors.deepPurple,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _isHoveringRegisterLink
                                        ? Colors.deepPurple
                                        : Colors.deepPurple,
                                    letterSpacing: _isHoveringRegisterLink
                                        ? 0.3
                                        : 0,
                                  ),
                                  child: const Text('Daftar Sekarang'),
                                ),
                                if (_isHoveringRegisterLink) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.deepPurple,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
