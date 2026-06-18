import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';

class EmailVerificationCodeScreen extends StatefulWidget {
  final String email;
  final String uid;

  const EmailVerificationCodeScreen({
    super.key,
    required this.email,
    required this.uid,
  });

  @override
  State<EmailVerificationCodeScreen> createState() =>
      _EmailVerificationCodeScreenState();
}

class _EmailVerificationCodeScreenState
    extends State<EmailVerificationCodeScreen>
    with TickerProviderStateMixin {
  final FirebaseAuthService _authService = FirebaseAuthService();
  late TextEditingController _codeController;
  bool _isLoading = false;
  int _resendCountdown = 0;

  late AnimationController _animationController;
  late List<Animation<double>> _staggeredAnimations;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _staggeredAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            (0.6 + ((index * 0.1).clamp(0.0, 1.0))).clamp(0.0, 1.0),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );

    _animationController.forward();

    // Send verification email on first load
    _sendVerificationEmail();

    // Start auto-checking email verification
    _startEmailVerificationCheck();
  }

  void _startEmailVerificationCheck() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (mounted) {
        final isVerified = await _authService.checkEmailVerified();
        if (isVerified) {
          await _authService.updateEmailVerifiedStatus();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✓ Email terverifikasi! Selamat datang!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/user_home');
              }
            });
          }
        } else {
          _startEmailVerificationCheck();
        }
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      debugPrint('Verification email sent to ${widget.email}');
    } catch (e) {
      debugPrint('Error sending verification email: $e');
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0) return;
    setState(() => _isLoading = true);

    try {
      await _authService.sendEmailVerification();
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Email verifikasi telah dikirim ulang'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      setState(() => _resendCountdown = 60);
      _startCountdown();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _startCountdown() {
    if (_resendCountdown <= 0) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _resendCountdown--);
        if (_resendCountdown > 0) _startCountdown();
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan masukkan kode verifikasi'),
            backgroundColor: AppColors.red,
          ),
        );
      }
      return;
    }

    if (code.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode verifikasi harus 6 karakter'),
            backgroundColor: AppColors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email is already verified from Firebase
      final isVerified = await _authService.checkEmailVerified();

      if (isVerified) {
        await _authService.updateEmailVerifiedStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Email terverifikasi! Selamat datang!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/user_home');
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Email belum diverifikasi. Cek email Anda dan klik link verifikasi.',
              ),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _staggeredAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_staggeredAnimations[index]),
        child: child,
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.green.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Header Icon
                    _buildAnimatedItem(
                      index: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_rounded,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Title
                    _buildAnimatedItem(
                      index: 1,
                      child: Text(
                        'Verifikasi Email Anda',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBg,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildAnimatedItem(
                      index: 2,
                      child: Text(
                        'Klik link verifikasi yang telah kami kirim ke:\n${widget.email}\n\nAtau klik tombol dibawah setelah memverifikasi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Input Field (showing email)
                    _buildAnimatedItem(
                      index: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.lightGrey,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_rounded,
                              color: AppColors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.email,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.darkBg,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Info Box
                    _buildAnimatedItem(
                      index: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '✓ Klik link verifikasi di email, kami akan otomatis detect dan verify akun Anda',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Verify Button
                    _buildAnimatedItem(
                      index: 5,
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading ? null : _handleVerify,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.6),
                                          AppColors.green.withValues(alpha: 0.6),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.green,
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                boxShadow: [
                                  if (!_isLoading)
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Cek Status Verifikasi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resend Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum menerima email? ',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: _resendCountdown == 0
                                ? _resendVerificationEmail
                                : null,
                            child: Text(
                              _resendCountdown > 0
                                  ? 'Kirim ulang (${_resendCountdown}s)'
                                  : 'Kirim ulang',
                              style: TextStyle(
                                color: _resendCountdown > 0
                                    ? AppColors.grey
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Change Email
                    GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).pushReplacementNamed('/register'),
                      child: Text(
                        'Ubah Email',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
