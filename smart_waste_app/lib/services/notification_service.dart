import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging Service untuk notifikasi push
/// Mengirim notifikasi ke user dan petugas
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await _messaging.getToken();
      if (token != null) {
        await _saveDeviceToken(token);
      }

      _messaging.onTokenRefresh.listen(_saveDeviceToken);
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  Future<void> _saveDeviceToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Kirim notifikasi request disetujui ke user
  /// [userId] - ID user pengirim request
  /// [requestId] - ID request yang disetujui
  /// [officerId] - ID petugas yang di-assign
  /// [officerName] - Nama petugas
  /// [officerPhone] - Nomor telepon petugas
  Future<void> sendRequestApprovedNotification({
    required String userId,
    required String requestId,
    required String officerId,
    required String officerName,
    required String officerPhone,
  }) async {
    try {
      final notification = {
        'type': 'request_approved',
        'title': 'Request Disetujui ✅',
        'message':
            'Permintaan penjemputan Anda telah disetujui. Petugas: $officerName',
        'requestId': requestId,
        'officerId': officerId,
        'officerName': officerName,
        'officerPhone': officerPhone,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'navigate_to_tracking',
      };

      // Save to user's notifications collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification);

      // Also add to global notifications collection for tracking
      await _firestore.collection('notifications').add({
        ...notification,
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error sending approved notification: $e');
    }
  }

  /// Kirim notifikasi request ditolak ke user
  Future<void> sendRequestRejectedNotification({
    required String userId,
    required String requestId,
    required String reason,
  }) async {
    try {
      final notification = {
        'type': 'request_rejected',
        'title': 'Request Ditolak ❌',
        'message': 'Permintaan penjemputan Anda ditolak. Alasan: $reason',
        'requestId': requestId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'navigate_to_home',
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification);

      await _firestore.collection('notifications').add({
        ...notification,
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error sending rejected notification: $e');
    }
  }

  /// Kirim notifikasi ke petugas bahwa ada request baru
  Future<void> sendOfficerNewRequestNotification({
    required String officerId,
    required String requestId,
    required String userName,
    required String wasteType,
    required String address,
  }) async {
    try {
      final notification = {
        'type': 'new_assignment',
        'title': 'Ada Request Baru 📍',
        'message':
            'Request penjemputan dari $userName - $wasteType di $address',
        'requestId': requestId,
        'userName': userName,
        'wasteType': wasteType,
        'address': address,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'navigate_to_officer_request',
      };

      await _firestore
          .collection('users')
          .doc(officerId)
          .collection('notifications')
          .add(notification);

      await _firestore.collection('notifications').add({
        ...notification,
        'officerId': officerId,
      });
    } catch (e) {
      debugPrint('Error sending officer notification: $e');
    }
  }

  /// Kirim notifikasi ke petugas bahwa request dimulai
  Future<void> sendOfficerInProgressNotification({
    required String officerId,
    required String requestId,
    required String userName,
  }) async {
    try {
      final notification = {
        'type': 'request_in_progress',
        'title': 'Request Dimulai 🚚',
        'message': 'Mulai penjemputan untuk $userName',
        'requestId': requestId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'navigate_to_tracking',
      };

      await _firestore
          .collection('users')
          .doc(officerId)
          .collection('notifications')
          .add(notification);
    } catch (e) {
      debugPrint('Error sending in-progress notification: $e');
    }
  }

  /// Kirim notifikasi ke user bahwa petugas sedang dalam perjalanan
  Future<void> sendUserPickupStartedNotification({
    required String userId,
    required String requestId,
    required String officerName,
    required String officerPhone,
  }) async {
    try {
      final notification = {
        'type': 'pickup_started',
        'title': 'Penjemputan Dimulai 🚚',
        'message': '$officerName sedang dalam perjalanan menuju Anda',
        'requestId': requestId,
        'officerName': officerName,
        'officerPhone': officerPhone,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'navigate_to_tracking',
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification);

      await _firestore.collection('notifications').add({
        ...notification,
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error sending pickup started notification: $e');
    }
  }

  /// Kirim notifikasi ke user bahwa penjemputan selesai
  Future<void> sendPickupCompletedNotification({
    required String userId,
    required String requestId,
    required double totalWeight,
    required int totalPoints,
  }) async {
    try {
      final notification = {
        'type': 'pickup_completed',
        'title': 'Penjemputan Selesai ✅',
        'message':
            'Sampah berhasil diambil: $totalWeight kg, Poin: $totalPoints',
        'requestId': requestId,
        'totalWeight': totalWeight,
        'totalPoints': totalPoints,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'action': 'navigate_to_history',
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification);

      await _firestore.collection('notifications').add({
        ...notification,
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error sending pickup completed notification: $e');
    }
  }

  /// Get user notifications stream
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get officer notifications stream
  Stream<QuerySnapshot> getOfficerNotifications(String officerId) {
    return _firestore
        .collection('users')
        .doc(officerId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead({
    required String userId,
    required String notificationId,
    required bool isOfficer,
  }) async {
    try {
      // Both officers and users now use the 'users' collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
    required bool isOfficer,
  }) async {
    try {
      // Both officers and users now use the 'users' collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId, {bool isOfficer = false}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}
