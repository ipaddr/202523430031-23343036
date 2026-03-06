/// CRUD (Create, Read, Update, Delete) Exceptions
///
/// This file contains custom exception classes for the Note Service.
/// Organized by operation type and resource (User, Note, Database).

// ============================================================================
// DATABASE EXCEPTIONS
// ============================================================================

/// Thrown when attempting to open a database that is already open
class DatabaseAlreadyOpenException implements Exception {
  const DatabaseAlreadyOpenException();

  @override
  String toString() => 'DatabaseAlreadyOpenException: Database is already open';
}

/// Thrown when database operations are attempted but database is not open
class DatabaseIsNotOpen implements Exception {
  const DatabaseIsNotOpen();

  @override
  String toString() =>
      'DatabaseIsNotOpen: Database connection is not established';
}

/// Thrown when unable to access the documents directory
class UnableToGetDocumentsDirectoryException implements Exception {
  const UnableToGetDocumentsDirectoryException();

  @override
  String toString() =>
      'UnableToGetDocumentsDirectoryException: Could not find documents directory';
}

// ============================================================================
// USER CRUD EXCEPTIONS
// ============================================================================

/// Thrown when attempting to create a user that already exists
class UserAlreadyExists implements Exception {
  final String email;

  const UserAlreadyExists({this.email = ''});

  @override
  String toString() =>
      'UserAlreadyExists: User with email "$email" already exists';
}

/// Thrown when a user cannot be found in the database
class CouldNotFindUser implements Exception {
  final String? email;

  const CouldNotFindUser({this.email});

  @override
  String toString() =>
      'CouldNotFindUser: User${email != null ? ' with email "$email"' : ''} not found';
}

/// Thrown when a user creation operation fails
class CouldNotCreateUser implements Exception {
  final String message;

  const CouldNotCreateUser({this.message = 'Failed to create user'});

  @override
  String toString() => 'CouldNotCreateUser: $message';
}

/// Thrown when a user deletion operation fails
class CouldNotDeleteUser implements Exception {
  final String? email;

  const CouldNotDeleteUser({this.email});

  @override
  String toString() =>
      'CouldNotDeleteUser: Failed to delete user${email != null ? ' with email "$email"' : ''}';
}

/// Thrown when a user update operation fails
class CouldNotUpdateUser implements Exception {
  final String message;

  const CouldNotUpdateUser({this.message = 'Failed to update user'});

  @override
  String toString() => 'CouldNotUpdateUser: $message';
}

// ============================================================================
// NOTE CRUD EXCEPTIONS
// ============================================================================

/// Thrown when a note cannot be found in the database
class CouldNotFindNote implements Exception {
  final int? id;

  const CouldNotFindNote({this.id});

  @override
  String toString() =>
      'CouldNotFindNote: Note${id != null ? ' with id "$id"' : ''} not found';
}

/// Thrown when a note creation operation fails
class CouldNotCreateNote implements Exception {
  final String message;

  const CouldNotCreateNote({this.message = 'Failed to create note'});

  @override
  String toString() => 'CouldNotCreateNote: $message';
}

/// Thrown when a note deletion operation fails
class CouldNotDeleteNote implements Exception {
  final int? id;

  const CouldNotDeleteNote({this.id});

  @override
  String toString() =>
      'CouldNotDeleteNote: Failed to delete note${id != null ? ' with id "$id"' : ''}';
}

/// Thrown when a note update operation fails
class CouldNotUpdateNote implements Exception {
  final int? id;
  final String message;

  const CouldNotUpdateNote({this.id, this.message = 'Failed to update note'});

  @override
  String toString() =>
      'CouldNotUpdateNote: $message${id != null ? ' (id: $id)' : ''}';
}

// ============================================================================
// VALIDATION EXCEPTIONS
// ============================================================================

/// Thrown when note content is empty or invalid
class InvalidNoteContent implements Exception {
  final String message;

  const InvalidNoteContent({this.message = 'Note content is empty or invalid'});

  @override
  String toString() => 'InvalidNoteContent: $message';
}

/// Thrown when user email is invalid
class InvalidUserEmail implements Exception {
  final String email;

  const InvalidUserEmail({required this.email});

  @override
  String toString() =>
      'InvalidUserEmail: "$email" is not a valid email address';
}

// ============================================================================
// SYNCHRONIZATION EXCEPTIONS
// ============================================================================

/// Thrown when cloud synchronization fails
class SyncException implements Exception {
  final String message;

  const SyncException({this.message = 'Synchronization failed'});

  @override
  String toString() => 'SyncException: $message';
}

/// Thrown when offline operations are attempted but not supported
class OfflineException implements Exception {
  final String message;

  const OfflineException({this.message = 'Operation not available offline'});

  @override
  String toString() => 'OfflineException: $message';
}
