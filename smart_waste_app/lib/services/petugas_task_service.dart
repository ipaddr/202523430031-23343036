import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PetugasTaskService {
  static final PetugasTaskService _instance = PetugasTaskService._internal();
  late final FirebaseFirestore _firestore;

  factory PetugasTaskService() {
    return _instance;
  }

  PetugasTaskService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Get real-time stream of tasks assigned to specific petugas
  /// Status: pending (belum diambil), in_progress (sedang dikerjakan), arrived (tiba di lokasi), completed (selesai)
  Stream<List<Map<String, dynamic>>> getAssignedTasks(String officerId) {
    try {
      return _firestore
          .collection('pickup_requests')
          .where('assigned_officer_id', isEqualTo: officerId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                ...Map<String, dynamic>.from(doc.data() as Map),
              };
            }).toList();
          });
    } catch (e) {
      debugPrint('❌ Error fetching assigned tasks: $e');
      return Stream.value([]);
    }
  }

  /// Get filtered tasks by status
  Stream<List<Map<String, dynamic>>> getTasksByStatus(
    String officerId,
    String status,
  ) {
    try {
      return _firestore
          .collection('pickup_requests')
          .where('assigned_officer_id', isEqualTo: officerId)
          .where('status', isEqualTo: status)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                ...Map<String, dynamic>.from(doc.data() as Map),
              };
            }).toList();
          });
    } catch (e) {
      debugPrint('❌ Error fetching tasks by status: $e');
      return Stream.value([]);
    }
  }

  /// Get single task details
  Future<Map<String, dynamic>?> getTaskDetail(String taskId) async {
    try {
      final doc = await _firestore
          .collection('pickup_requests')
          .doc(taskId)
          .get();
      if (doc.exists) {
        return {'id': doc.id, ...Map<String, dynamic>.from(doc.data() as Map)};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching task detail: $e');
      return null;
    }
  }

  /// Update task status
  /// Statuses: pending → in_progress → arrived → completed → rejected
  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _firestore.collection('pickup_requests').doc(taskId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Task status updated: $taskId → $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating task status: $e');
      return false;
    }
  }

  /// Update task with completion data (weight, photos, notes)
  Future<bool> completeTask({
    required String taskId,
    required double actualWeight,
    required List<String> photoUrls, // URLs dari Firebase Storage
    required String notes,
    required String officerId,
  }) async {
    try {
      await _firestore.collection('pickup_requests').doc(taskId).update({
        'status': 'completed',
        'actual_weight': actualWeight,
        'photo_urls': photoUrls,
        'completion_notes': notes,
        'completed_by': officerId,
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Task completed: $taskId');
      return true;
    } catch (e) {
      debugPrint('❌ Error completing task: $e');
      return false;
    }
  }

  /// Get task statistics for petugas dashboard
  Future<Map<String, int>> getTaskStatistics(String officerId) async {
    try {
      final snapshot = await _firestore
          .collection('pickup_requests')
          .where('assigned_officer_id', isEqualTo: officerId)
          .get();

      int pending = 0;
      int inProgress = 0;
      int completed = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final status = doc['status'] as String?;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'in_progress':
            inProgress++;
            break;
          case 'completed':
            completed++;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return {
        'pending': pending,
        'in_progress': inProgress,
        'completed': completed,
        'rejected': rejected,
        'total': snapshot.size,
      };
    } catch (e) {
      debugPrint('❌ Error fetching task statistics: $e');
      return {'total': 0};
    }
  }

  /// Start task (change status from pending to in_progress)
  Future<bool> startTask(String taskId, String officerId) async {
    try {
      await _firestore.collection('pickup_requests').doc(taskId).update({
        'status': 'in_progress',
        'started_at': FieldValue.serverTimestamp(),
        'started_by': officerId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Task started: $taskId');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting task: $e');
      return false;
    }
  }

  /// Mark as arrived at location
  Future<bool> markArrived(String taskId, String officerId) async {
    try {
      await _firestore.collection('pickup_requests').doc(taskId).update({
        'status': 'arrived',
        'arrival_time': FieldValue.serverTimestamp(),
        'arrived_by': officerId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Marked arrived: $taskId');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking arrived: $e');
      return false;
    }
  }

  /// Reject task with reason
  Future<bool> rejectTask(
    String taskId,
    String reason,
    String officerId,
  ) async {
    try {
      await _firestore.collection('pickup_requests').doc(taskId).update({
        'status': 'rejected',
        'rejection_reason': reason,
        'rejected_by': officerId,
        'rejected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Task rejected: $taskId');
      return true;
    } catch (e) {
      debugPrint('❌ Error rejecting task: $e');
      return false;
    }
  }

  /// Get user details for task (used for displaying user info)
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return Map<String, dynamic>.from(doc.data() as Map);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user details: $e');
      return null;
    }
  }

  /// Get officer details
  Future<Map<String, dynamic>?> getOfficerDetails(String officerId) async {
    try {
      final doc = await _firestore.collection('officers').doc(officerId).get();
      if (doc.exists) {
        return Map<String, dynamic>.from(doc.data() as Map);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching officer details: $e');
      return null;
    }
  }

  /// Complete task and send notifications to user
  /// Also updates user statistics
  Future<bool> completeTaskWithNotifications({
    required String taskId,
    required double actualWeight,
    required List<String> photoUrls,
    required String notes,
    required String officerId,
  }) async {
    try {
      // Get task details first to get user ID
      final taskDoc = await _firestore
          .collection('pickup_requests')
          .doc(taskId)
          .get();
      if (!taskDoc.exists) {
        debugPrint('❌ Task not found: $taskId');
        return false;
      }

      final taskData = taskDoc.data();
      final userId = (taskData?['user_id'] ?? taskData?['uid']) as String?;
      final wasteType =
          (taskData?['waste_type'] ?? taskData?['wasteType'] ?? '').toString();
      if (userId == null) {
        debugPrint('❌ User ID not found in task');
        return false;
      }

      // Complete the task
      await _firestore.collection('pickup_requests').doc(taskId).update({
        'status': 'completed',
        'actual_weight': actualWeight,
        'photo_urls': photoUrls,
        'completion_notes': notes,
        'completed_by': officerId,
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Get user details for notification
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc['name'] as String? ?? 'User';

      // Create notification for user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'task_completed',
            'title': 'Pengambilan Sampah Selesai!',
            'message':
                'Sampah Anda telah berhasil diambil oleh petugas. Berat: ${actualWeight}kg',
            'requestId': taskId,
            'userName': userName,
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Update user statistics - increment completed requests and add points
      // Assuming 1 point per kg of waste
      final pointsEarned = actualWeight.toInt();
      await _firestore.collection('users').doc(userId).update({
        'totalRequests': FieldValue.increment(1),
        'totalPoints': FieldValue.increment(pointsEarned),
        'points': FieldValue.increment(pointsEarned),
        'wasteCollected': FieldValue.increment(actualWeight.toInt()),
        'totalWasteCollected': FieldValue.increment(actualWeight.toInt()),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _incrementWasteCategoryTotal(wasteType, actualWeight);

      // Update officer statistics
      await _firestore.collection('officers').doc(officerId).update({
        'completedRequests': FieldValue.increment(1),
        'assignedRequests': FieldValue.increment(
          -1,
        ), // Decrement assigned count
      });

      debugPrint('✅ Task completed with notifications: $taskId');
      return true;
    } catch (e) {
      debugPrint('❌ Error completing task with notifications: $e');
      return false;
    }
  }

  Future<void> _incrementWasteCategoryTotal(
    String wasteType,
    double actualWeight,
  ) async {
    if (wasteType.trim().isEmpty) return;

    try {
      final snapshot = await _firestore
          .collection('waste_categories')
          .where('name', isEqualTo: wasteType)
          .limit(5)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'total_weight': FieldValue.increment(actualWeight),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Could not update waste category total: $e');
    }
  }
}
