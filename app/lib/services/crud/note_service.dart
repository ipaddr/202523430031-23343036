import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;
import 'package:path/path.dart' show join;
import 'crud_exceptions.dart';

class NoteService {
  Database? _db;
  String? _currentUserEmail;

  List<DatabaseNote> _notes = [];

  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();

  /// Initialize NoteService with current user email
  NoteService({String? userEmail}) : _currentUserEmail = userEmail;

  /// Verify that a user is authenticated and matches current user
  void _validateUserAuthentication() {
    if (_currentUserEmail == null || _currentUserEmail!.isEmpty) {
      throw const UserNotAuthenticatedException();
    }
  }

  /// Verify user hasn't changed
  void _verifyUserMatch(String userEmail) {
    _validateUserAuthentication();
    if (_currentUserEmail!.toLowerCase() != userEmail.toLowerCase()) {
      throw const UnauthorizedAccessException();
    }
  }

  /// Set current user email (called after authentication)
  void setCurrentUser(String userEmail) {
    _currentUserEmail = userEmail.toLowerCase();
  }

  /// Clear user session (called on logout)
  Future<void> clearUserSession() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
    _currentUserEmail = null;
    _notes = [];
    await _notesStreamController.close();
  }

  /// Get current user email
  String? get currentUserEmail => _currentUserEmail;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _currentUserEmail != null && _currentUserEmail!.isNotEmpty;

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    _validateUserAuthentication();
    _verifyUserMatch(email);

    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    _validateUserAuthentication();

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    await getNote(id: note.id);

    final updatedCount = await db.update(
      noteTable,
      {'text': text, 'isSyncedWithCloud': 0},
      where: 'id = ?',
      whereArgs: [note.id],
    );

    if (updatedCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((n) => n.id == note.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    _validateUserAuthentication();

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);
    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));
  }

  Future<DatabaseNote> getNote({required int id}) async {
    _validateUserAuthentication();

    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (notes.isEmpty) {
      throw CouldNotFindNote();
    } else {
      final note = DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((n) => n.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<int> deleteAllNotes() async {
    _validateUserAuthentication();

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }

  Future<void> deleteNote({required int id}) async {
    _validateUserAuthentication();

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    _validateUserAuthentication();
    _verifyUserMatch(owner.email);

    final db = _getDatabaseOrThrow();

    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw const UnauthorizedAccessException();
    }

    const text = '';
    final noteId = await db.insert(noteTable, {
      'userId': owner.id,
      'text': text,
      'isSyncedWithCloud': 1,
    });

    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    return note;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    _validateUserAuthentication();
    _verifyUserMatch(email);

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    _validateUserAuthentication();
    _verifyUserMatch(email);

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {'email': email.toLowerCase()});

    return DatabaseUser(id: userId, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    _validateUserAuthentication();
    _verifyUserMatch(email);

    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
      _currentUserEmail = null;
      _notes = [];
      try {
        await _notesStreamController.close();
      } catch (e) {
        // Already closed or error closing stream, ignore
      }
    }
  }

  Future<void>_ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // empty
    }
  }

  Future<void> open({String? userEmail}) async {
    _validateUserAuthentication();
    
    if (userEmail != null) {
      _verifyUserMatch(userEmail);
    }

    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      await db.execute(createUserTable);

      await db.execute(createNoteTable);
      
      // Ensure current user exists in database
      try {
        await getOrCreateUser(email: _currentUserEmail!);
      } catch (e) {
        rethrow;
      }
      
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw Exception('Could not find the documents directory');
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> map)
    : id = map['id'] as int,
      email = map['email'] as String;

  @override
  String toString() => 'DatabaseUser, id = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) =>
      id == other.id && email == other.email;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
    : id = map['id'] as int,
      userId = map['userId'] as int,
      text = map['text'] as String,
      isSyncedWithCloud = (map['isSyncedWithCloud'] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, id = $id, userId = $userId, text = $text, isSyncedWithCloud = $isSyncedWithCloud';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'userId';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'isSyncedWithCloud';
const createUserTable = ''' Create Table If Not Exists "user" (
        "id" INTEGER Not Null,
        "email" TEXT Not Null Unique,
        Primary Key("id" Autoincrement)
      );''';
const createNoteTable = ''' Create Table If Not Exists "note" (
        "id" INTEGER Not Null,
        "userId" INTEGER Not Null,
        "text" TEXT,
        "isSyncedWithCloud" INTEGER Not Null Default 0,
        Primary Key("id" Autoincrement),
        Foreign Key("userId") References "user"("id")
      );''';
