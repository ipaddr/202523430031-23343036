/// Example: Using Loading Screens with Login Flow
///
/// This file demonstrates how to integrate LoadingBloc with existing screens
/// to provide comprehensive loading state management.
///
/// ## Integration in login_screen.dart
///
/// Step 1: Add LoadingBloc import
/// ```dart
/// import '../bloc/loading_bloc.dart';
/// import '../extensions/loading_extension.dart';
/// ```
///
/// Step 2: Monitor AuthBloc state changes and trigger loading
/// ```dart
/// BlocListener<AuthBloc, AuthState>(
///   listener: (context, state) {
///     if (state is AuthStateLoading) {
///       // AuthBloc is now handling the actual loading
///       // You can optionally trigger LoadingBloc here if needed
///       context.showLoading(
///         message: 'Sedang memverifikasi kredensial...',
///         operationType: LoadingOperationType.login,
///       );
///     } else if (state is AuthStateError) {
///       // Hide loading and show error
///       context.hideLoading();
///       // Error will be shown via DialogBloc
///     } else if (state is AuthStateAuthenticated ||
///                state is AuthStateEmailVerificationNeeded) {
///       // Hide loading and navigate
///       context.hideLoading();
///       // Navigation will be handled by RoutingBloc
///     }
///   },
///   child: ...,
/// )
/// ```
///
/// Step 3: Update auth_bloc.dart to emit loading events
/// ```dart
/// Future<void> _onLogin(AuthEventLogin event, Emitter<AuthState> emit) async {
///   try {
///     emit(const AuthStateLoading());
///     // AuthStateLoading will trigger loading overlay via BlocListener above
///
///     final userCredential = await _authService.loginWithEmail(
///       event.email,
///       event.password,
///     );
///     // ... rest of login logic
///   } on FirebaseAuthException catch (e) {
///     emit(AuthStateError(message: _getAuthErrorMessage(e.code), code: e.code));
///   }
/// }
/// ```
///
/// ## Pattern: Coordinated Loading
///
/// The system uses a coordination pattern:
/// 1. UI calls AuthBloc.add(AuthEventLogin(...))
/// 2. AuthBloc.add(AuthStateLoading()) in handler
/// 3. LoadingBloc listener displays overlay
/// 4. Async operation completes
/// 5. AuthBloc emits success/error state
/// 6. LoadingBloc completes, overlay hidden
/// 7. Other BLoCs (Dialog, Routing) handle next step
///
/// ## Example: Custom Screen with Loading
///
/// ```dart
/// class CustomDataScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return BlocListener<DataBloc, DataState>(
///       listener: (context, state) {
///         if (state is DataStateLoading) {
///           context.showLoading(
///             message: 'Mengambil data...',
///             operationType: LoadingOperationType.dataFetch,
///           );
///         } else if (state is DataStateSuccess) {
///           context.hideLoading();
///           // Show data
///         } else if (state is DataStateError) {
///           context.hideLoading();
///           context.read<DialogBloc>().add(
///             DialogEventShowSnackBar(
///               message: state.message,
///               type: SnackBarType.error,
///             ),
///           );
///         }
///       },
///       child: BlocBuilder<DataBloc, DataState>(
///         builder: (context, state) {
///           if (state is DataStateLoading) {
///             return const SizedBox.shrink(); // Loading handled by overlay
///           }
///           // Show actual content
///           return YourContentWidget();
///         },
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Real-world Flow Diagram
///
/// ```
/// User taps Login
///         ↓
/// _handleLogin() calls AuthBloc.add(AuthEventLogin)
///         ↓
/// AuthBloc._onLogin emits AuthStateLoading
///         ↓
/// BlocListener detects loading state
///         ↓
/// context.showLoading() → LoadingBloc.add(LoadingEventStart)
///         ↓
/// AppLoadingListener detects LoadingStateLoading
///         ↓
/// LoadingOverlay appears on top of screen
///         ↓
/// Firebase auth operation continues in background
///         ↓
/// Auth completes → AuthBloc emits success/error
///         ↓
/// BlocListener detects completion
///         ↓
/// context.hideLoading() → LoadingBloc.add(LoadingEventComplete)
///         ↓
/// LoadingOverlay disappears
///         ↓
/// DialogBloc/RoutingBloc handle next action
///         ↓
/// UI updates or navigation occurs
/// ```
///
/// ## Code Organization
///
/// - **loading_bloc.dart**: Core loading state management
/// - **loading_widgets.dart**: Reusable loading UI components
/// - **app_loading_listener.dart**: Global overlay wrapper
/// - **loading_extension.dart**: Helper methods for easy usage
/// - **screens/**: Each screen uses context methods from extension
///
/// ## Troubleshooting
///
/// **Problem**: Loading never disappears
/// **Solution**: Ensure all code paths call context.hideLoading() or
///              emit LoadingEventComplete()
///
/// **Problem**: Loading appears but content is clickable
/// **Solution**: LoadingOverlay has ModalBarrier that prevents interaction.
///              If still clickable, check if overlay is properly mounted
///              in Stack hierarchy.
///
/// **Problem**: Multiple loading overlays at once
/// **Solution**: LoadingBloc is a singleton (created once in main.dart).
///              Each new loading event replaces the previous one.
///
/// **Problem**: Back button dismisses loading
/// **Solution**: WillPopScope in LoadingScreen/LoadingOverlay prevents back.
///              If back works, overlay may not be active in widget tree.
///
