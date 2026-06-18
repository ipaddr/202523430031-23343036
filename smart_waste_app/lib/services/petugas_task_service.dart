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

  /// Resolves the officer ID used in pickup_requests (assigned_officer_id).
  /// Admin always stores the Firebase Auth UID as assigned_officer_id,
  /// so we look up in the 'users' collection (role=petugas) first.
  Future<String> resolveOfficerId({
    required String authUid,
    String? email,
  }) async {
    if (authUid.isEmpty) return '';

    try {
      // 1. Check if authUid directly exists in 'users' collection with role petugas
      final userDoc = await _firestore.collection('users').doc(authUid).get();
      if (userDoc.exists) {
        final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
        if (role == 'petugas') {
          debugPrint('✅ Resolved officer ID from users collection: $authUid');
          return authUid;
        }
      }

      // 2. Try finding by email in 'users' collection
      if (email != null && email.isNotEmpty) {
        final byEmail = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'petugas')
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          final docId = byEmail.docs.first.id;
          debugPrint(
            '✅ Resolved officer ID by email from users collection: $docId',
          );
          return docId;
        }
      }

      // 3. Fallback: search users by email (any role)
      if (email != null && email.isNotEmpty) {
        final byEmail = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          final docId = byEmail.docs.first.id;
          debugPrint('✅ Resolved officer ID by email fallback: $docId');
          return docId;
        }
      }
    } catch (e) {
      debugPrint('Could not resolve officer id: $e');
    }

    // Final fallback: return authUid as-is
    // (admin stores Firebase Auth UID as assigned_officer_id)
    debugPrint('⚠️ Using authUid as fallback officer ID: $authUid');
    return authUid;
  }

  /// Get real-time stream of tasks assigned to specific petugas.
  /// Only approved requests that match an active admin schedule are shown.
  Stream<List<Map<String, dynamic>>> getAssignedTasks(String officerId) {
    try {
      return _firestore
          .collection('pickup_requests')
          .where('assigned_officer_id', isEqualTo: officerId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final schedules = await _getActiveSchedules();
            final tasks = snapshot.docs
                .map((doc) {
                  return _normalizeTask(
                    doc.id,
                    Map<String, dynamic>.from(doc.data() as Map),
                    schedules,
                    requireSchedule: false,
                    requireApprovedStatus: true,
                  );
                })
                .whereType<Map<String, dynamic>>()
                .toList();

            tasks.sort(_compareTasksBySchedule);
            return tasks;
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
    if (status == 'semua') return getAssignedTasks(officerId);

    try {
      return _firestore
          .collection('pickup_requests')
          .where('assigned_officer_id', isEqualTo: officerId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            final schedules = await _getActiveSchedules();
            final tasks = snapshot.docs
                .map((doc) {
                  return _normalizeTask(
                    doc.id,
                    Map<String, dynamic>.from(doc.data() as Map),
                    schedules,
                    requireSchedule: false,
                    requireApprovedStatus: true,
                  );
                })
                .whereType<Map<String, dynamic>>()
                .where((task) {
                  return (task['status'] ?? '').toString() == status;
                })
                .toList();

            tasks.sort(_compareTasksBySchedule);
            return tasks;
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
        final schedules = await _getActiveSchedules();
        return _normalizeTask(
              doc.id,
              Map<String, dynamic>.from(doc.data() as Map),
              schedules,
              requireSchedule: false,
              requireApprovedStatus: false,
            ) ??
            {'id': doc.id, ...Map<String, dynamic>.from(doc.data() as Map)};
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

      int accepted = 0;
      int inProgress = 0;
      int completed = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final status = doc['status'] as String?;
        switch (status) {
          case 'accepted':
            accepted++;
            break;
          case 'in_progress':
          case 'arrived':
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
        'accepted': accepted,
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

  /// Start task (change status from accepted to in_progress)
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

  /// Get officer details from users collection
  Future<Map<String, dynamic>?> getOfficerDetails(String officerId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(officerId).get();
      if (userDoc.exists) {
        return Map<String, dynamic>.from(userDoc.data() as Map);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching officer details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getActiveSchedules() async {
    try {
      final snapshot = await _firestore.collection('schedules').get();
      final today = DateTime.now();

      return snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            final date = _readDate(data['date']);
            final status = (data['status'] ?? 'Aktif').toString();
            final startTime = (data['start_time'] ?? '').toString();
            final endTime = (data['end_time'] ?? '').toString();

            return {
              'id': doc.id,
              ...data,
              'category': (data['category'] ?? data['area'] ?? '').toString(),
              'route': (data['route'] ?? data['zone'] ?? '').toString(),
              'time': (data['time'] ?? '$startTime - $endTime').toString(),
              'date_value': date,
              'status': status,
            };
          })
          .where((schedule) {
            final status = schedule['status'].toString().toLowerCase();
            final date = schedule['date_value'];
            final isActive = status == 'aktif' || status == 'active';
            final isUsableDate =
                date is! DateTime ||
                _isSameDay(date, today) ||
                date.isAfter(_startOfDay(today));

            return isActive && isUsableDate;
          })
          .toList();
    } catch (e) {
      debugPrint('Could not load active schedules: $e');
      return [];
    }
  }

  Map<String, dynamic>? _normalizeTask(
    String id,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> schedules, {
    bool requireSchedule = true,
    bool requireApprovedStatus = true,
  }) {
    final status = (data['status'] ?? '').toString();
    if (requireApprovedStatus && !_isApprovedTaskStatus(status)) return null;

    final schedule = _matchingSchedule(data, schedules);
    if (requireSchedule && schedule == null) return null;

    final enriched = {'id': id, ...data};
    if (schedule != null) {
      enriched.addAll({
        'schedule_id': schedule['id'],
        'schedule_category': schedule['category'],
        'schedule_route': schedule['route'],
        'schedule_time': schedule['time'],
        'schedule_date': schedule['date_value'],
        'schedule_date_text': _formatDate(schedule['date_value']),
      });
    }

    return enriched;
  }

  bool _isApprovedTaskStatus(String status) {
    return const {
      'accepted',
      'in_progress',
      'arrived',
      'completed',
    }.contains(status.toLowerCase());
  }

  Map<String, dynamic>? _matchingSchedule(
    Map<String, dynamic> task,
    List<Map<String, dynamic>> schedules,
  ) {
    for (final schedule in schedules) {
      if (_scheduleMatchesTask(schedule, task)) return schedule;
    }
    return null;
  }

  bool _scheduleMatchesTask(
    Map<String, dynamic> schedule,
    Map<String, dynamic> task,
  ) {
    final category = schedule['category'].toString().toLowerCase();
    final wasteType = (task['waste_type'] ?? task['wasteType'] ?? '')
        .toString()
        .toLowerCase();

    if (category.isEmpty || wasteType.isEmpty) return false;
    if (category.contains('kertas')) {
      return wasteType.contains('kertas') ||
          wasteType.contains('paper') ||
          wasteType.contains('cardboard') ||
          wasteType.contains('tisu');
    }
    if (category.contains('b3')) return wasteType.contains('b3');
    if (category.contains('anorganik')) {
      return wasteType.contains('anorganik') ||
          wasteType.contains('plastic') ||
          wasteType.contains('plastik') ||
          wasteType.contains('metal') ||
          wasteType.contains('logam') ||
          wasteType.contains('glass') ||
          wasteType.contains('kaca') ||
          wasteType.contains('textile') ||
          wasteType.contains('miscellaneous');
    }
    if (category.contains('organik')) {
      return (wasteType.contains('organik') &&
              !wasteType.contains('anorganik')) ||
          wasteType.contains('food') ||
          wasteType.contains('vegetation');
    }

    return wasteType.contains(category) || category.contains(wasteType);
  }

  int _compareTasksBySchedule(Map<String, dynamic> a, Map<String, dynamic> b) {
    final dateA = a['schedule_date'];
    final dateB = b['schedule_date'];

    if (dateA is DateTime && dateB is DateTime) {
      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
    } else if (dateA is DateTime) {
      return -1;
    } else if (dateB is DateTime) {
      return 1;
    }

    final timeCompare = (a['schedule_time'] ?? '').toString().compareTo(
      (b['schedule_time'] ?? '').toString(),
    );
    if (timeCompare != 0) return timeCompare;

    final createdA = _readDate(a['created_at'] ?? a['createdAt']);
    final createdB = _readDate(b['created_at'] ?? b['createdAt']);
    if (createdA == null || createdB == null) return 0;
    return createdB.compareTo(createdA);
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(dynamic value) {
    if (value is! DateTime) return '';
    return '${value.day}/${value.month}/${value.year}';
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

      // Update officer statistics in 'users' collection (petugas stored in users)
      await _firestore.collection('users').doc(officerId).update({
        'completedRequests': FieldValue.increment(1),
        'assignedRequests': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Task completed with notifications: $taskId');
      return true;
    } catch (e) {
      debugPrint('❌ Error completing task with notifications: $e');
      return false;
    }
  }

  /// Submit a rating for a completed task's officer
  /// Updates the officer's average rating in the officers collection
  Future<bool> submitRating({
    required String taskId,
    required int rating, // 1-5
    required String officerId,
    String? comment,
  }) async {
    try {
      // Save rating on the pickup request
      await _firestore.collection('pickup_requests').doc(taskId).update({
        'user_rating': rating,
        'user_rating_comment': comment ?? '',
        'rated_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Recalculate officer average rating
      await _recalculateOfficerRating(officerId);

      debugPrint(
        'Rating submitted: task=$taskId, rating=$rating, officer=$officerId',
      );
      return true;
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      return false;
    }
  }

  /// Recalculate officer's average rating from all rated tasks
  Future<void> _recalculateOfficerRating(String officerId) async {
    try {
      final snapshot = await _firestore
          .collection('pickup_requests')
          .where('assigned_officer_id', isEqualTo: officerId)
          .where('status', isEqualTo: 'completed')
          .get();

      int totalRating = 0;
      int ratedCount = 0;

      for (final doc in snapshot.docs) {
        final r = doc['user_rating'];
        if (r is int && r >= 1 && r <= 5) {
          totalRating += r;
          ratedCount++;
        }
      }

      final avgRating = ratedCount > 0 ? totalRating / ratedCount : 0.0;

      // Update in users collection (petugas stored here)
      await _firestore.collection('users').doc(officerId).update({
        'average_rating': double.parse(avgRating.toStringAsFixed(1)),
        'total_ratings': ratedCount,
        'rating_updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error recalculating officer rating: $e');
    }
  }

  /// Get officer's rating info (average rating and total ratings)
  Future<Map<String, dynamic>> getOfficerRating(String officerId) async {
    try {
      // Try users collection first
      final doc = await _firestore.collection('users').doc(officerId).get();
      if (doc.exists) {
        final data = doc.data();
        return {
          'average_rating':
              (data?['average_rating'] as num?)?.toDouble() ?? 0.0,
          'total_ratings': data?['total_ratings'] as int? ?? 0,
        };
      }
      return {'average_rating': 0.0, 'total_ratings': 0};
    } catch (e) {
      debugPrint('Error fetching officer rating: $e');
      return {'average_rating': 0.0, 'total_ratings': 0};
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
