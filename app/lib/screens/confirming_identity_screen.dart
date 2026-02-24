import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfirmingIdentityScreen extends StatefulWidget {
  final User user;
  final VoidCallback onIdentityConfirmed;
  final VoidCallback onFailed;

  const ConfirmingIdentityScreen({
    super.key,
    required this.user,
    required this.onIdentityConfirmed,
    required this.onFailed,
  });

  @override
  State<ConfirmingIdentityScreen> createState() =>
      _ConfirmingIdentityScreenState();
}

class _ConfirmingIdentityScreenState extends State<ConfirmingIdentityScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _resultAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Mengonfirmasi identitas Anda...';
  bool _isConfirming = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _confirmIdentity();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _confirmIdentity() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Verify user session
      setState(() {
        _statusMessage = 'Memverifikasi sesi Anda...';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Reload user to ensure session is valid
      await widget.user.reload();

      setState(() {
        _statusMessage = 'Memuat data profil...';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // All checks passed
      setState(() {
        _statusMessage = 'Identitas dikonfirmasi!';
        _isConfirming = false;
      });

      _animationController.stop();
      _resultAnimationController.forward();

      // Navigate after brief success message
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        widget.onIdentityConfirmed();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Gagal mengonfirmasi identitas: $e';
          _isConfirming = false;
        });
      }

      _animationController.stop();
      _resultAnimationController.forward();

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        widget.onFailed();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade300],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon
                    if (_isConfirming)
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: const Icon(
                                    Icons.verified_user,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else if (_statusMessage.contains('Gagal'))
                      ScaleTransition(
                        scale: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _resultAnimationController,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      )
                    else
                      ScaleTransition(
                        scale: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _resultAnimationController,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),

                    // Status Message
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // User Info
                    Text(
                      'Pengguna: ${widget.user.email}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Steps Indicator
                    if (_isConfirming)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildStepItem(
                              '1',
                              'Mengonfirmasi identitas',
                              true,
                            ),
                            const SizedBox(height: 12),
                            _buildStepItem('2', 'Memverifikasi sesi', false),
                            const SizedBox(height: 12),
                            _buildStepItem('3', 'Memuat data profil', false),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String title, bool isActive) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isActive
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
