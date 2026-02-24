import 'package:firebase_auth/firebase_auth.dart';

/// Arguments untuk navigate ke AddNote screen
class AddNoteArgs {
  final User user;
  final String? noteId;
  final String initialTitle;
  final String initialContent;

  AddNoteArgs({
    required this.user,
    this.noteId,
    this.initialTitle = '',
    this.initialContent = '',
  });

  /// Convert arguments ke Map untuk dipass ke route
  Map<String, dynamic> toMap() {
    return {
      'user': user,
      'noteId': noteId,
      'title': initialTitle,
      'content': initialContent,
    };
  }

  /// Create from Map
  factory AddNoteArgs.fromMap(Map<String, dynamic> map) {
    return AddNoteArgs(
      user: map['user'] as User,
      noteId: map['noteId'] as String?,
      initialTitle: map['title'] as String? ?? '',
      initialContent: map['content'] as String? ?? '',
    );
  }
}

/// Arguments untuk navigate ke MainScreen
class MainScreenArgs {
  final User user;

  MainScreenArgs({required this.user});
}

/// Arguments untuk navigate ke EmailVerification screen
class EmailVerificationArgs {
  final User user;

  EmailVerificationArgs({required this.user});
}
