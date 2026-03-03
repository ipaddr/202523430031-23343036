import 'package:flutter/foundation.dart' show immutable;

// Database exceptions
@immutable
class DatabaseAlreadyOpenException implements Exception {
  const DatabaseAlreadyOpenException();
}

@immutable
class UnableToGetDocumentsDirectoryException implements Exception {
  const UnableToGetDocumentsDirectoryException();
}

@immutable
class DatabaseIsNotOpen implements Exception {
  const DatabaseIsNotOpen();
}

// User exceptions
@immutable
class CouldNotDeleteUser implements Exception {
  const CouldNotDeleteUser();
}

@immutable
class UserAlreadyExists implements Exception {
  const UserAlreadyExists();
}

@immutable
class CouldNotFindUser implements Exception {
  const CouldNotFindUser();
}

// Note exceptions
@immutable
class CouldNotDeleteNote implements Exception {
  const CouldNotDeleteNote();
}

@immutable
class CouldNotFindNote implements Exception {
  const CouldNotFindNote();
}

@immutable
class CouldNotUpdateNote implements Exception {
  const CouldNotUpdateNote();
}
