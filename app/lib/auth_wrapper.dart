import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bloc/auth_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/register_success_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/confirming_identity_screen.dart';
import 'screens/main_screen.dart';
import 'widgets/app_loading_listener.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isShowingLogin = true;
  bool _isShowingRegisterSuccess = false;
  bool _isConfirmingIdentity = false;
  User? _newlyRegisteredUser;
  User? _userToConfirm;

  @override
  Widget build(BuildContext context) {
    // Show register success screen if user just registered
    if (_isShowingRegisterSuccess && _newlyRegisteredUser != null) {
      return RegisterSuccessScreen(user: _newlyRegisteredUser!);
    }

    // Show confirming identity screen if needed
    if (_isConfirmingIdentity && _userToConfirm != null) {
      return ConfirmingIdentityScreen(
        user: _userToConfirm!,
        onIdentityConfirmed: () {
          setState(() {
            _isConfirmingIdentity = false;
          });
        },
        onFailed: () {
          setState(() {
            _isConfirmingIdentity = false;
            _isShowingLogin = true;
          });
        },
      );
    }

    return AppLoadingListener(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Loading state
          if (state is AuthStateInitial || state is AuthStateLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Error state
          if (state is AuthStateError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isShowingLogin = true;
                        });
                      },
                      child: const Text('Kembali ke Login'),
                    ),
                  ],
                ),
              ),
            );
          }

          // User just registered and needs to verify email
          if (state is AuthStateRegisterSuccess) {
            if (_newlyRegisteredUser?.uid != state.user.uid) {
              _newlyRegisteredUser = state.user;
              _isShowingRegisterSuccess = true;
            }
            return RegisterSuccessScreen(user: state.user);
          }

          // User is authenticated
          if (state is AuthStateAuthenticated) {
            final user = state.user;

            // Confirm identity before accessing main screen
            if (!_isConfirmingIdentity && _userToConfirm == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _isConfirmingIdentity = true;
                  _userToConfirm = user;
                });
              });
            }

            // Show main screen only if identity is confirmed
            if (!_isConfirmingIdentity && _userToConfirm != null) {
              return MainScreen(
                user: user,
                onLogout: () {
                  context.read<AuthBloc>().add(const AuthEventLogout());
                  setState(() {
                    _isShowingLogin = true;
                    _isShowingRegisterSuccess = false;
                    _isConfirmingIdentity = false;
                    _userToConfirm = null;
                  });
                },
              );
            }

            // During confirmation process
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Email verification needed
          if (state is AuthStateEmailVerificationNeeded) {
            return EmailVerificationScreen(
              user: state.user,
              onVerificationSuccess: () {
                // Check email verification status
                context.read<AuthBloc>().add(
                  const AuthEventCheckEmailVerified(),
                );
              },
              onLogout: () {
                context.read<AuthBloc>().add(const AuthEventLogout());
                setState(() {
                  _isShowingLogin = true;
                  _isShowingRegisterSuccess = false;
                });
              },
            );
          }

          // User is not authenticated
          if (state is AuthStateUnauthenticated) {
            // Reset local state when user logs out
            if (_userToConfirm != null) {
              _userToConfirm = null;
              _isConfirmingIdentity = false;
              _newlyRegisteredUser = null;
              _isShowingRegisterSuccess = false;
            }

            // Show login/register screens
            if (_isShowingLogin) {
              return LoginScreen(
                onSwitchToRegister: () {
                  setState(() {
                    _isShowingLogin = false;
                  });
                },
                onLoginSuccess: () {
                  setState(() {
                    _isShowingRegisterSuccess = false;
                  });
                },
              );
            } else {
              return RegisterScreen(
                onSwitchToLogin: () {
                  setState(() {
                    _isShowingLogin = true;
                  });
                },
                onRegisterSuccess: () {
                  // The user will be registered and EmailVerificationNeeded state will follow
                  // Stay on current screen until that happens
                },
              );
            }
          }

          // Fallback to unauthenticated screen
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
