import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Exception thrown when user is not authenticated
class UserNotAuthenticatedException implements Exception {
  final String message;
  const UserNotAuthenticatedException(this.message);
  @override
  String toString() => message;
}

/// Exception thrown when unauthorized access is attempted
class UnauthorizedAccessException implements Exception {
  final String message;
  const UnauthorizedAccessException(this.message);
  @override
  String toString() => message;
}

/// Cloud Note model
class CloudNote {
  final String id;
  final String title;
  final String content;
  final int wordCount;
  final int charCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String userEmail;

  CloudNote({
    required this.id,
    required this.title,
    required this.content,
    required this.wordCount,
    required this.charCount,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.userEmail,
  });

  /// Create from Firestore document
  factory CloudNote.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String docId,
  ) {
    final data = doc.data() ?? {};
    return CloudNote(
      id: docId,
      title: data['title'] ?? 'Untitled',
      content: data['content'] ?? '',
      wordCount: _countWords(data['content'] ?? ''),
      charCount: (data['content'] ?? '').length,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'userId': userId,
      'userEmail': userEmail,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Count words in text
  static int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  String toString() =>
      'CloudNote(id: $id, title: $title, wordCount: $wordCount, charCount: $charCount)';
}

/// Firestore-first notes service
/// Uses Cloud Firestore as the primary data source
class CloudNotesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Validate user is authenticated
  void _validateAuthenticated() {
    if (!isAuthenticated) {
      throw UserNotAuthenticatedException('User not authenticated');
    }
  }

  /// Get user notes as stream (ordered by updatedAt descending)
  Stream<List<CloudNote>> getUserNotesStream() {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CloudNote.fromFirestore(doc, doc.id))
              .toList();
        })
        .handleError((e) {
          throw 'Failed to load notes: $e';
        });
  }

  /// Get all notes as a future (one-time fetch)
  Future<List<CloudNote>> getAllNotes() async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CloudNote.fromFirestore(doc, doc.id))
          .toList();
    } catch (e) {
      throw 'Failed to fetch all notes: $e';
    }
  }

  /// Get a single note by ID
  Future<CloudNote?> getNote(String noteId) async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(noteId)
          .get();

      if (!doc.exists) return null;
      return CloudNote.fromFirestore(doc, doc.id);
    } catch (e) {
      throw 'Failed to get note: $e';
    }
  }

  /// Create a new note
  Future<CloudNote> createNote({
    required String title,
    required String content,
  }) async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;
    final userEmail = _auth.currentUser!.email;

    if (userEmail == null) {
      throw UserNotAuthenticatedException('User email not available');
    }

    try {
      final now = DateTime.now();
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .add({
            'title': title,
            'content': content,
            'userId': uid,
            'userEmail': userEmail,
            'createdAt': now,
            'updatedAt': now,
          });

      return CloudNote(
        id: docRef.id,
        title: title,
        content: content,
        wordCount: CloudNote._countWords(content),
        charCount: content.length,
        createdAt: now,
        updatedAt: now,
        userId: uid,
        userEmail: userEmail,
      );
    } catch (e) {
      throw 'Failed to create note: $e';
    }
  }

  /// Update an existing note
  Future<CloudNote> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;
    final userEmail = _auth.currentUser!.email;

    if (userEmail == null) {
      throw UserNotAuthenticatedException('User email not available');
    }

    try {
      final now = DateTime.now();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(noteId)
          .update({'title': title, 'content': content, 'updatedAt': now});

      return CloudNote(
        id: noteId,
        title: title,
        content: content,
        wordCount: CloudNote._countWords(content),
        charCount: content.length,
        createdAt: DateTime.now(),
        updatedAt: now,
        userId: uid,
        userEmail: userEmail,
      );
    } catch (e) {
      throw 'Failed to update note: $e';
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      throw 'Failed to delete note: $e';
    }
  }

  /// Delete all notes for current user
  Future<int> deleteAllNotes() async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .get();

      int count = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        count++;
      }
      return count;
    } catch (e) {
      throw 'Failed to delete all notes: $e';
    }
  }

  /// Search notes by title or content
  Future<List<CloudNote>> searchNotes(String query) async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;

    if (query.isEmpty) {
      return getAllNotes();
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .get();

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final content = (data['content'] ?? '').toString().toLowerCase();
            return title.contains(lowerQuery) || content.contains(lowerQuery);
          })
          .map((doc) => CloudNote.fromFirestore(doc, doc.id))
          .toList();
    } catch (e) {
      throw 'Failed to search notes: $e';
    }
  }

  /// Get note count for current user
  Future<int> getNoteCount() async {
    _validateAuthenticated();
    final uid = _auth.currentUser!.uid;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw 'Failed to get note count: $e';
    }
  }
}
