import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  late final FirebaseFirestore _firestore;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  // Create pickup request
  Future<bool> createPickupRequest({
    required String uid,
    required String wasteType,
    required String location,
    required String address,
    required double latitude,
    required double longitude,
    String weight = '',
    String notes = '',
    String? userName,
    String? userPhone,
  }) async {
    try {
      final createdAt = FieldValue.serverTimestamp();
      await _firestore.collection('pickup_requests').add({
        'uid': uid,
        'user_id': uid,
        if (userName != null && userName.isNotEmpty) 'user_name': userName,
        if (userPhone != null && userPhone.isNotEmpty) 'user_phone': userPhone,
        'wasteType': wasteType,
        'waste_type': wasteType,
        'weight': weight,
        'estimated_weight': _parseWeightKg(weight),
        'location': location,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'user_lat': latitude,
        'user_lon': longitude,
        'pickup_location': {'latitude': latitude, 'longitude': longitude},
        'driver_name': '',
        'driver_phone': '',
        'estimated_arrival_time': '',
        'schedule_time': 'Menunggu verifikasi admin',
        'notes': notes,
        'status': 'pending',
        'createdAt': createdAt,
        'created_at': createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error creating pickup request: $e');
      return false;
    }
  }

  // Get user pickup requests
  Future<List<Map<String, dynamic>>> getUserPickupRequests(String uid) async {
    try {
      final byUid = await _firestore
          .collection('pickup_requests')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      final byUserId = await _firestore
          .collection('pickup_requests')
          .where('user_id', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      final merged = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      void addResults(QuerySnapshot snapshot) {
        for (final doc in snapshot.docs) {
          if (seenIds.add(doc.id)) {
            merged.add({
              'id': doc.id,
              ...Map<String, dynamic>.from(doc.data() as Map),
            });
          }
        }
      }

      addResults(byUid);
      addResults(byUserId);

      merged.sort(
        (a, b) =>
            _pickupRequestTimestamp(b).compareTo(_pickupRequestTimestamp(a)),
      );

      return merged;
    } catch (e) {
      debugPrint('Error getting pickup requests: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamUserPickupRequests(String uid) {
    return _firestore
        .collection('pickup_requests')
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  ...Map<String, dynamic>.from(doc.data() as Map),
                },
              )
              .toList();

          requests.sort(
            (a, b) => _pickupRequestTimestamp(
              b,
            ).compareTo(_pickupRequestTimestamp(a)),
          );

          return requests;
        });
  }

  // Update pickup request status
  Future<bool> updatePickupRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating pickup request: $e');
      return false;
    }
  }

  // Create waste record
  Future<bool> createWasteRecord({
    required String uid,
    required String wasteType,
    required double weight,
    required String description,
  }) async {
    try {
      await _firestore.collection('waste_records').add({
        'uid': uid,
        'wasteType': wasteType,
        'weight': weight,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error creating waste record: $e');
      return false;
    }
  }

  // Get user waste records
  Future<List<Map<String, dynamic>>> getUserWasteRecords(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('waste_records')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...Map<String, dynamic>.from(doc.data() as Map),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting waste records: $e');
      return [];
    }
  }

  // Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'uid': doc.id,
              ...Map<String, dynamic>.from(doc.data() as Map),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  // Search users by name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'uid': doc.id,
              ...Map<String, dynamic>.from(doc.data() as Map),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>?> getUserStatistics(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data();
      if (userData == null) return null;

      return {
        'points': userData['points'] ?? 0,
        'wasteCollected': userData['wasteCollected'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return null;
    }
  }

  // Create notification
  Future<bool> createNotification({
    required String uid,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'uid': uid,
        'title': title,
        'message': message,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return false;
    }
  }

  // Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...Map<String, dynamic>.from(doc.data() as Map),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });

      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getSchedulesStream() {
    return _firestore
        .collection('schedules')
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  ...Map<String, dynamic>.from(doc.data() as Map),
                },
              )
              .toList(),
        );
  }

  Future<bool> createSchedule({
    required String category,
    required String route,
    required String startTime,
    required String endTime,
    required DateTime date,
    String status = 'Aktif',
  }) async {
    try {
      await _firestore.collection('schedules').add({
        'category': category,
        'area': category,
        'route': route,
        'zone': route,
        'start_time': startTime,
        'end_time': endTime,
        'time': '$startTime - $endTime',
        'date': Timestamp.fromDate(date),
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error creating schedule: $e');
      return false;
    }
  }

  Future<bool> updateScheduleStatus({
    required String scheduleId,
    required String status,
  }) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('schedules').doc(scheduleId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getWasteCategoriesStream({String? kind}) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      'waste_categories',
    );

    if (kind != null) {
      query = query.where('kind', isEqualTo: kind);
    }

    return query
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  ...Map<String, dynamic>.from(doc.data() as Map),
                },
              )
              .toList(),
        );
  }

  Future<bool> createWasteCategory({
    required String name,
    required String kind,
    String description = '',
  }) async {
    try {
      await _firestore.collection('waste_categories').add({
        'name': name,
        'kind': kind,
        'description': description,
        'total_weight': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error creating waste category: $e');
      return false;
    }
  }

  Future<bool> deleteWasteCategory(String categoryId) async {
    try {
      await _firestore.collection('waste_categories').doc(categoryId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting waste category: $e');
      return false;
    }
  }

  DateTime _pickupRequestTimestamp(Map<String, dynamic> data) {
    final rawTimestamp = data['createdAt'] ?? data['created_at'];

    if (rawTimestamp is Timestamp) {
      return rawTimestamp.toDate();
    }

    if (rawTimestamp is DateTime) {
      return rawTimestamp;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double _parseWeightKg(String value) {
    final match = RegExp(r'[\d]+([.,]\d+)?').firstMatch(value);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
  }
}
