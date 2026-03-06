import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart'
    show MissingPlatformDirectoryException, getApplicationDocumentsDirectory;
import 'package:path/path.dart' show join;
import 'crud_exceptions.dart';
import '../firebase_service.dart';

class NoteService {
  Database? _db;
  String? _currentUserEmail;
  final FirebaseService _firebaseService = FirebaseService();
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  final Duration _syncInterval = const Duration(seconds: 30);

  List<DatabaseNote> _notes = [];

  final _notesStreamController =
      StreamController<List<DatabaseNote>>.broadcast();
  
  final _syncStatusStreamController =
      StreamController<SyncStatus>.broadcast();

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
  bool get isUserAuthenticated =>
      _currentUserEmail != null && _currentUserEmail!.isNotEmpty;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Get sync status stream
  Stream<SyncStatus> get syncStatusStream => _syncStatusStreamController.stream;

  /// Start automatic background sync
  void startAutoSync() {
    if (_syncTimer != null) return; // Already running

    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      await syncNotesToCloud();
    });
  }

  /// Stop automatic background sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Sync all unsynced notes to Cloud Firestore
  Future<void> syncNotesToCloud() async {
    if (_isSyncing || !isUserAuthenticated) return;

    _isSyncing = true;
    _syncStatusStreamController.add(
      SyncStatus(issyncing: true, isSyncedCount: 0, unsyncedCount: 0),
    );

    try {
      final db = _getDatabaseOrThrow();

      // Get all unsynced notes
      final unsyncedNotes = await db.query(
        noteTable,
        where: 'isSyncedWithCloud = ?',
        whereArgs: [0],
      );

      int syncedCount = 0;
      int failedCount = 0;

      for (final noteData in unsyncedNotes) {
        try {
          await _syncSingleNote(DatabaseNote.fromRow(noteData));
          syncedCount++;
        } catch (e) {
          failedCount++;
        }
      }

      _isSyncing = false;
      _syncStatusStreamController.add(
        SyncStatus(
          issyncing: false,
          isSyncedCount: syncedCount,
          unsyncedCount: failedCount,
        ),
      );
    } catch (e) {
      _isSyncing = false;
      _syncStatusStreamController.add(
        SyncStatus(issyncing: false, isSyncedCount: 0, unsyncedCount: 0),
      );
    }
  }

  /// Sync a single note to Cloud Firestore
  Future<void> _syncSingleNote(DatabaseNote note) async {
    _validateUserAuthentication();

    try {
      final db = _getDatabaseOrThrow();

      // Get note details from database
      final noteDetails = await db.query(
        noteTable,
        limit: 1,
        where: 'id = ?',
        whereArgs: [note.id],
      );

      if (noteDetails.isEmpty) {
        throw CouldNotFindNote();
      }

      final noteData = noteDetails.first;
      final text = noteData['text'] as String? ?? '';

      // Extract title from first line or use default
      final lines = text.split('\n');
      final title = lines.isNotEmpty && lines.first.isNotEmpty
          ? lines.first.substring(0, (lines.first.length > 100 ? 100 : lines.first.length))
          : 'Untitled Note';

      // Push to Firebase (create new note)
      await _firebaseService.createNote(
        title: title,
        content: text,
      );

      // Mark as synced in local database
      await _markAsSynced(note.id);
    } catch (e) {
      throw 'Failed to sync note ${note.id}: $e';
    }
  }

  /// Mark a note as synced with cloud
  Future<void> _markAsSynced(int noteId) async {
    _validateUserAuthentication();

    final db = _getDatabaseOrThrow();
    final updatedCount = await db.update(
      noteTable,
      {'isSyncedWithCloud': 1},
      where: 'id = ?',
      whereArgs: [noteId],
    );

    if (updatedCount != 1) {
      throw CouldNotUpdateNote();
    }

    // Update in-memory notes
    final updatedNotes = _notes.map((note) {
      if (note.id == noteId) {
        return DatabaseNote(
          id: note.id,
          userId: note.userId,
          text: note.text,
          isSyncedWithCloud: true,
        );
      }
      return note;
    }).toList();

    _notes = updatedNotes;
    _notesStreamController.add(_notes);
  }

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
      'isSyncedWithCloud': 0, // Mark as unsynced for cloud
    });

    final note = DatabaseNote(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: false,
    );

    _notes.add(note);
    _notesStreamController.add(_notes);

    // Attempt to sync to cloud immediately (fire and forget)
    _syncSingleNote(note).catchError((e) {
      // Sync failed but note is saved locally, will retry in background
    });

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
    // Stop auto sync
    stopAutoSync();

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
        await _syncStatusStreamController.close();
      } catch (e) {
        // Already closed or error closing stream, ignore
      }
    }
  }

  Future<void> _ensureDbIsOpen() async {
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

      // Start auto sync in background
      startAutoSync();

      // Perform initial sync immediately (fire and forget)
      syncNotesToCloud().catchError((e) {
        // Log sync error but don't block
      });
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

/// Cloud sync status information
@immutable
class SyncStatus {
  final bool issyncing;
  final int isSyncedCount;
  final int unsyncedCount;

  const SyncStatus({
    required this.issyncing,
    required this.isSyncedCount,
    required this.unsyncedCount,
  });

  String get summary {
    if (issyncing) {
      return 'Menyinkronkan catatan ke cloud...';
    }
    if (isSyncedCount > 0) {
      return '$isSyncedCount catatan berhasil disinkronkan';
    }
    if (unsyncedCount > 0) {
      return '$unsyncedCount catatan gagal disinkronkan';
    }
    return 'Semua catatan tersinkronkan';
  }
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
