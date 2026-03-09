import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/routing_bloc.dart';
import '../bloc/dialog_bloc.dart';

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

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isHoveringRegisterLink = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Get snackbar color based on type
  Color _getSnackBarColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Colors.green;
      case SnackBarType.error:
        return Colors.red;
      case SnackBarType.warning:
        return Colors.orange;
      case SnackBarType.info:
        return Colors.blue;
    }
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Trigger login event from BLoC
    context.read<AuthBloc>().add(
      AuthEventLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      context.read<DialogBloc>().add(
        const DialogEventShowSnackBar(
          message: 'Masukkan email Anda untuk reset password',
          type: SnackBarType.warning,
        ),
      );
      return;
    }

    // Show confirmation dialog via DialogBloc
    context.read<DialogBloc>().add(
      DialogEventShowConfirmation(
        title: 'Reset Password',
        message: 'Email reset password akan dikirim ke:\n$email',
        confirmLabel: 'Kirim',
        cancelLabel: 'Batal',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          // Handle auth state changes
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthStateError) {
                // Show error as snackbar
                context.read<DialogBloc>().add(
                  DialogEventShowSnackBar(
                    message: state.message,
                    type: SnackBarType.error,
                    duration: const Duration(seconds: 6),
                  ),
                );
              } else if (state is AuthStateEmailVerificationNeeded ||
                  state is AuthStateAuthenticated) {
                // Navigate to success screen
                final user = state is AuthStateEmailVerificationNeeded
                    ? state.user
                    : (state as AuthStateAuthenticated).user;

                context.read<RoutingBloc>().add(
                  RoutingEventNavigateToAndReplace(
                    routeName: '/login-success',
                    arguments: user,
                  ),
                );
              }
            },
          ),
          // Handle routing events
          BlocListener<RoutingBloc, RoutingState>(
            listener: (context, state) {
              if (state is RoutingStateNavigateTo) {
                Navigator.pushNamed(
                  context,
                  state.routeName,
                  arguments: state.arguments,
                );
              } else if (state is RoutingStateNavigateToAndReplace) {
                Navigator.pushReplacementNamed(
                  context,
                  state.routeName,
                  arguments: state.arguments,
                );
              } else if (state is RoutingStatePopRoute) {
                Navigator.pop(context);
              }
            },
          ),
          // Handle dialog events
          BlocListener<DialogBloc, DialogState>(
            listener: (context, state) {
              if (state is DialogStateShowConfirmation) {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(state.title),
                    content: Text(state.message),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(state.cancelLabel),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle confirmation - trigger reset password event
                          final email = _emailController.text.trim();
                          context.read<AuthBloc>().add(
                            AuthEventResetPassword(email: email),
                          );
                          Navigator.pop(dialogContext);
                        },
                        child: Text(state.confirmLabel),
                      ),
                    ],
                  ),
                );
              } else if (state is DialogStateShowSnackBar) {
                // Show snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: _getSnackBarColor(state.type),
                    duration: state.duration,
                  ),
                );
              }
            },
          ),
        ],
        child: Center(
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

                  // Login Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      bool isLoading = state is AuthStateLoading;

                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            disabledBackgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _handleForgotPassword,
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? '),
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
                          child: Text(
                            'Daftar',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              decoration: _isHoveringRegisterLink
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
