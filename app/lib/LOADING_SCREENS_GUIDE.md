/// Loading Screens Implementation Guide
///
/// This project implements a comprehensive loading state management system
/// using BLoC pattern. Loading states are displayed as overlays on top of
/// existing screens without interrupting navigation flow.
///
/// ## Components
///
/// 1. **LoadingBloc** (loading_bloc.dart)
///    - Manages loading state across the app
///    - Events: Start, Update (with progress), Complete, Error
///    - States: Initial, Loading (with progress), Error
///
/// 2. **Loading Widgets** (widgets/loading_widgets.dart)
///    - LoadingScreen: Full-screen loading with optional progress
///    - LoadingOverlay: Modal overlay with semi-transparent backdrop
///    - MiniLoadingIndicator: Compact inline loading indicator
///    - SkeletonLoader: Shimmer effect for content loading
///
/// 3. **AppLoadingListener** (widgets/app_loading_listener.dart)
///    - Global loading overlay management
///    - Wraps the entire auth wrapper
///    - Automatically shows/hides based on LoadingBloc state
///
/// 4. **Loading Extension** (extensions/loading_extension.dart)
///    - Convenient context methods for loading management
///    - withLoading(): Execute async operation with loading overlay
///    - showLoading()/hideLoading(): Manual control
///    - showLoadingError(): Show error message
///
/// ## Usage Examples
///
/// ### Example 1: Simple Loading (AutoHandler)
/// ```dart
/// // Show loading overlay (automatically managed by AppLoadingListener)
/// context.read<LoadingBloc>().add(
///   const LoadingEventStart(
///     message: 'Sedang login...',
///     operationType: LoadingOperationType.login,
///   ),
/// );
///
/// // Perform async operation
/// await _authService.login(email, password);
///
/// // Hide loading
/// context.read<LoadingBloc>().add(const LoadingEventComplete());
/// ```
///
/// ### Example 2: Using Extension Helper (Recommended)
/// ```dart
/// // Using helper extension
/// final result = await context.withLoading(
///   operation: () => _authService.login(email, password),
///   loadingMessage: 'Sedang login...',
///   operationType: LoadingOperationType.login,
/// );
/// ```
///
/// ### Example 3: With Progress Updates
/// ```dart
/// context.showLoading(
///   message: 'Mengunduh data...',
///   operationType: LoadingOperationType.dataFetch,
/// );
///
/// // Update progress during operation
/// for (int i = 0; i <= 100; i += 10) {
///   await Future.delayed(Duration(milliseconds: 200));
///   context.updateLoading(
///     message: 'Mengunduh data...',
///     progress: i / 100,
///     operationType: LoadingOperationType.dataFetch,
///   );
/// }
///
/// context.hideLoading();
/// ```
///
/// ### Example 4: Error Handling
/// ```dart
/// try {
///   context.showLoading(message: 'Memproses...');
///   await riskyOperation();
/// } catch (e) {
///   context.showLoadingError(
///     message: 'Terjadi kesalahan: ${e.toString()}',
///   );
/// }
/// ```
///
/// ### Example 5: Different Loading Types
/// ```dart
/// // Login operation
/// context.showLoading(
///   message: 'Verifikasi login Anda...',
///   operationType: LoadingOperationType.login,
/// );
///
/// // Registration operation
/// context.showLoading(
///   message: 'Membuat akun...',
///   operationType: LoadingOperationType.registration,
/// );
///
/// // Email verification
/// context.showLoading(
///   message: 'Memeriksa verifikasi email...',
///   operationType: LoadingOperationType.emailVerification,
/// );
///
/// // Data fetch
/// context.showLoading(
///   message: 'Mengambil data...',
///   operationType: LoadingOperationType.dataFetch,
/// );
///
/// // Data save
/// context.showLoading(
///   message: 'Menyimpan data...',
///   operationType: LoadingOperationType.dataSave,
/// );
///
/// // General loading
/// context.showLoading(
///   message: 'Sedang memproses...',
///   operationType: LoadingOperationType.general,
/// );
/// ```
///
/// ## Architecture Benefits
///
/// ✅ **Centralized State**: All loading states managed by single BLoC
/// ✅ **Global Overlays**: Loading shown on top of any screen
/// ✅ **Progress Tracking**: Optional progress bar with percentage
/// ✅ **Testable**: Easy to unit test loading scenarios
/// ✅ **No Route Changes**: Overlays don't affect navigation
/// ✅ **Type-Safe**: Enum for operation types prevents errors
/// ✅ **Extensible**: Easy to add new loading operation types
///
/// ## Integration Points
///
/// 1. **AuthBloc**: Auto-hide loading after login/register success
/// 2. **DialogBloc**: Combine with error snackbars for better UX
/// 3. **RoutingBloc**: Works alongside navigation events
/// 4. **Any BLoC**: Can emit loading events for their operations
///
/// ## Best Practices
///
/// 1. Use operation types consistently for tracking
/// 2. Always hide loading after operations complete (or fail)
/// 3. Keep loading messages short and clear
/// 4. Use progress bar only for long-running operations (>2 seconds)
/// 5. Combine with DialogBloc for error messages after loading fails
/// 6. Prevent back button during loading (WillPopScope handled)
///
/// ## Future Enhancements
///
/// - [ ] Loading analytics/metrics collection
/// - [ ] Timeout handling for stuck operations
/// - [ ] Customizable loading animation styles
/// - [ ] Loading state persistence
/// - [ ] Loading operation queue management
///
