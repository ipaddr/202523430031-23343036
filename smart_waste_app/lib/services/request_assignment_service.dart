import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Service untuk menangani assignment request ke petugas
class RequestAssignmentService {
  static final RequestAssignmentService _instance =
      RequestAssignmentService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _notificationService = NotificationService();

  factory RequestAssignmentService() {
    return _instance;
  }

  RequestAssignmentService._internal();

  /// Approve request dan assign ke petugas
  /// [requestId] - ID request yang akan diapprove
  /// [userId] - ID user pengirim request
  /// [officerId] - ID petugas yang di-assign
  /// [estimatedArrivalTime] - Perkiraan waktu tiba dalam menit
  Future<Map<String, dynamic>> approveAndAssignRequest({
    required String requestId,
    required String userId,
    required String officerId,
    required int estimatedArrivalTime,
  }) async {
    try {
      // Get officer details
      final officerDoc = await _firestore
          .collection('officers')
          .doc(officerId)
          .get();
      if (!officerDoc.exists) {
        throw Exception('Petugas tidak ditemukan');
      }

      final officerData = officerDoc.data() ?? {};
      final officerName = officerData['name'] ?? 'Petugas';
      final officerPhone = officerData['phone'] ?? '';

      // Get request details
      final requestDoc = await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) {
        throw Exception('Request tidak ditemukan');
      }

      final requestData = requestDoc.data() ?? {};
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final userName =
          userData?['name'] ??
          requestData['user_name'] ??
          requestData['name'] ??
          'User';
      final wasteType =
          requestData['waste_type'] ?? requestData['wasteType'] ?? 'Unknown';
      final userLat = requestData['user_lat'] ?? requestData['latitude'] ?? 0.0;
      final userLon =
          requestData['user_lon'] ?? requestData['longitude'] ?? 0.0;

      // Calculate estimated arrival time
      final estimatedArrival = DateTime.now().add(
        Duration(minutes: estimatedArrivalTime),
      );

      // Update request dengan assignment info
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'status': 'accepted',
        'officer_id': officerId,
        'assigned_officer_id': officerId,
        'officer_name': officerName,
        'driver_name': officerName,
        'officer_phone': officerPhone,
        'driver_phone': officerPhone,
        'user_lat': userLat,
        'user_lon': userLon,
        'estimated_arrival': estimatedArrival,
        'estimated_arrival_minutes': estimatedArrivalTime,
        'estimated_arrival_time': '$estimatedArrivalTime Menit',
        'assigned_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update officer's assigned count
      await _firestore.collection('officers').doc(officerId).update({
        'assignedRequests': FieldValue.increment(1),
        'lastAssignment': FieldValue.serverTimestamp(),
      });

      // Send notifications
      await _notificationService.sendRequestApprovedNotification(
        userId: userId,
        requestId: requestId,
        officerId: officerId,
        officerName: officerName,
        officerPhone: officerPhone,
      );

      await _notificationService.sendOfficerNewRequestNotification(
        officerId: officerId,
        requestId: requestId,
        userName: userName,
        wasteType: wasteType,
        address: requestData['address'] ?? requestData['location'] ?? 'Unknown',
      );

      return {
        'success': true,
        'message': 'Request berhasil disetujui dan ditugaskan ke $officerName',
        'officerName': officerName,
        'estimatedArrival': estimatedArrival,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Reject request
  /// [requestId] - ID request yang akan ditolak
  /// [userId] - ID user pengirim request
  /// [reason] - Alasan penolakan
  Future<Map<String, dynamic>> rejectRequest({
    required String requestId,
    required String userId,
    required String reason,
  }) async {
    try {
      // Update request status to rejected
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'status': 'rejected',
        'rejection_reason': reason,
        'rejected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Send rejection notification to user
      await _notificationService.sendRequestRejectedNotification(
        userId: userId,
        requestId: requestId,
        reason: reason,
      );

      return {'success': true, 'message': 'Request berhasil ditolak'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get available officers (officers with status Aktif and not overloaded)
  /// [maxAssignments] - Maksimal tugas yang bisa ditugaskan (default: 5)
  Future<List<Map<String, dynamic>>> getAvailableOfficers({
    int maxAssignments = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('officers')
          .where('status', isEqualTo: 'Aktif')
          .get();

      final officers = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final assignedCount = data['assignedRequests'] ?? 0;

        // Only include officers with less than max assignments
        if (assignedCount < maxAssignments) {
          officers.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'phone': data['phone'] ?? '',
            'assignedRequests': assignedCount,
            'completedRequests': data['completedRequests'] ?? 0,
          });
        }
      }

      // Sort by assigned requests (least busy first)
      officers.sort(
        (a, b) => (a['assignedRequests'] as int).compareTo(
          b['assignedRequests'] as int,
        ),
      );

      return officers;
    } catch (e) {
      debugPrint('Error getting available officers: $e');
      return [];
    }
  }

  /// Get officer details
  Future<Map<String, dynamic>?> getOfficerDetails(String officerId) async {
    try {
      final doc = await _firestore.collection('officers').doc(officerId).get();
      if (doc.exists) {
        return {'id': doc.id, ...Map<String, dynamic>.from(doc.data() as Map)};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting officer details: $e');
      return null;
    }
  }

  /// Cancel assignment (revert to pending)
  /// [requestId] - ID request
  /// [userId] - ID user
  Future<Map<String, dynamic>> cancelAssignment({
    required String requestId,
    required String userId,
  }) async {
    try {
      // Get current request data
      final requestDoc = await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) {
        throw Exception('Request tidak ditemukan');
      }

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final officerId =
          requestData['officer_id'] ?? requestData['assigned_officer_id'];

      // Revert request to pending
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'status': 'pending',
        'officer_id': FieldValue.delete(),
        'assigned_officer_id': FieldValue.delete(),
        'officer_name': FieldValue.delete(),
        'driver_name': FieldValue.delete(),
        'officer_phone': FieldValue.delete(),
        'driver_phone': FieldValue.delete(),
        'estimated_arrival': FieldValue.delete(),
        'estimated_arrival_time': FieldValue.delete(),
        'estimated_arrival_minutes': FieldValue.delete(),
        'assigned_at': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Decrement officer's assigned count
      if (officerId != null) {
        await _firestore.collection('officers').doc(officerId).update({
          'assignedRequests': FieldValue.increment(-1),
        });
      }

      return {'success': true, 'message': 'Assignment berhasil dibatalkan'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
