# Auth Process BLoC Conversion - Complete Guide

## ✅ COMPLETED - Core BLoC Infrastructure

### 1. **New BLoC Files Created** (`lib/bloc/`)
   - `auth_bloc.dart` - Main BLoC with all event handlers
   - `auth_event.dart` - 9 authentication events  
   - `auth_state.dart` - 7 authentication states

### 2. **Updated Core Files**
   - ✅ `pubspec.yaml` - Added `flutter_bloc: ^8.1.0`
   - ✅ `main.dart` - Wrapped app with `BlocProvider<AuthBloc>`
   - ✅ `auth_wrapper.dart` - Replaced StreamBuilder with BlocBuilder
   - ✅ `services/auth_service.dart` - Added `sendPasswordResetEmail()` and `updateDisplayName()` methods

### 3. **Updated Auth Screens** (Using BLoC Pattern)
   - ✅ `login_screen.dart` - Now uses `BlocListener` + `BlocBuilder`
   - ✅ `register_screen.dart` - Now uses `BlocListener` + `BlocBuilder`
   - ✅ `email_verification_screen.dart` - Now uses `BlocListener` + `BlocBuilder`

---

## ⏳ SCREENS STILL NEEDING UPDATE

### Pattern Template for Any Screen

**OLD Pattern (Direct Service Call):**
```dart
import '../services/auth_service.dart';

// In function
await AuthService().logout();
```

**NEW Pattern (Using BLoC):**
```dart
import '../bloc/auth_bloc.dart';

// In function
context.read<AuthBloc>().add(const AuthEventLogout());

// Listen to state in build
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthStateUnauthenticated) {
      // Handle logout
    }
  },
)
```

---

## Screens Requiring Updates

### 1. **login_success_screen.dart**
**Current:** Likely calls `AuthService` for user data
**Update Pattern:**
```dart
// Replace AuthService calls with BLoC state
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthStateAuthenticated) {
      final user = state.user;
      // Use user from state
    }
  },
)
```

### 2. **register_success_screen.dart**
**Current:** Likely uses AuthService
**Update Pattern:** Same as login_success_screen

### 3. **confirming_identity_screen.dart**
**Current:** May call AuthService for verification
**Update Pattern:**
```dart
// For logout in this screen:
context.read<AuthBloc>().add(const AuthEventLogout());
```

### 4. **email_verification_success_screen.dart**
**Current:** Likely performs auth operations
**Update Pattern:** Check if auth calls exist, convert to BLoC events

### 5. **logout_screen.dart**
**Current:** Calls `AuthService().logout()`
**Update Pattern:**
```dart
// Replace:
await AuthService().logout();

// With:
context.read<AuthBloc>().add(const AuthEventLogout());

// Listen for completion:
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthStateUnauthenticated) {
      // Navigate away
    }
  },
)
```

### 6. **main_screen.dart**
**Current:** May use AuthService
**Update Pattern:** 
```dart
// For reading user from BLoC:
final authState = context.watch<AuthBloc>().state;
if (authState is AuthStateAuthenticated) {
  final user = authState.user;
}
```

### 7. **notes_screen.dart & Other Content Screens**
**Current:** Uses `AuthService().currentUser`
**Update Pattern:**
```dart
// Instead of:
String get userEmail => AuthService().currentUser?.email ?? 'Unknown';

// Do:
final authState = context.watch<AuthBloc>().state;
if (authState is AuthStateAuthenticated) {
  String userEmail = authState.user.email ?? 'Unknown';
}
```

---

## Quick Reference - All Events Available

```dart
// Registration
AuthEventRegister(email, password, fullName)

// Login
AuthEventLogin(email, password)

// Logout
AuthEventLogout()

// Email Verification
AuthEventSendEmailVerification()
AuthEventCheckEmailVerified()

// User Management
AuthEventReloadUser()
AuthEventResetPassword(email)
AuthEventUpdateDisplayName(displayName)

// Internal - Listens to Firebase auth changes
AuthEventAuthStateChanged(user)
```

---

## Important Notes

1. **Remove AuthService Direct Calls**: Replace all `AuthService()` calls with BLoC events
2. **Use context.read()**: For one-time additions of events
3. **Use context.watch()**: To rebuild widgets when state changes
4. **BlocListener**: For side effects (navigation, showing dialogs)
5. **BlocBuilder**: For UI that depends on state

---

## Testing the Conversion

After updating each screen:
1. Run `flutter pub get` (already done)
2. Build and test the auth flow
3. Verify all screens work correctly
4. Check that state transitions work properly

---

## Benefits of BLoC Pattern

✅ Centralized auth state management  
✅ Separation of business logic from UI  
✅ Easier to test with BLoC testing utilities  
✅ Better performance through selective rebuilds  
✅ Easier to add new auth features  
✅ Cleaner code and better maintainability
