import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInitService {
  static final FirestoreInitService _instance =
      FirestoreInitService._internal();
  late final FirebaseFirestore _firestore;

  factory FirestoreInitService() {
    return _instance;
  }

  FirestoreInitService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Create a new pickup request with proper structure
  Future<String?> createPickupRequest({
    required String userId,
    required String wasteType,
    required String weight,
    required String location,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final docRef = await _firestore.collection('pickup_requests').add({
        'uid': userId,
        'user_id': userId,
        'status': 'pending', // Initial status is pending
        'wasteType': wasteType,
        'waste_type': wasteType,
        'weight': weight,
        'location': location,
        'address': location,
        'truck_location': {'latitude': latitude, 'longitude': longitude},
        'driver_name': '', // Will be assigned by admin
        'driver_phone': '', // Will be assigned by admin
        'estimated_arrival_time': '', // Will be calculated
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Pickup request created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating pickup request: $e');
      return null;
    }
  }

  /// Update truck location for a pickup request (for admin/petugas)
  Future<bool> updateTruckLocation(
    String requestId, {
    required double latitude,
    required double longitude,
    required String driverName,
    required String driverPhone,
    required String estimatedArrivalTime,
  }) async {
    try {
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'truck_location': {'latitude': latitude, 'longitude': longitude},
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'estimated_arrival_time': estimatedArrivalTime,
        'status': 'in_progress',
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Truck location updated for request: $requestId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating truck location: $e');
      return false;
    }
  }

  /// Update pickup request status
  Future<bool> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Request status updated: $requestId → $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating request status: $e');
      return false;
    }
  }

  /// Get all pickup requests for a user
  Future<List<Map<String, dynamic>>> getUserPickupRequests(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('pickup_requests')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...Map<String, dynamic>.from(doc.data() as Map),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user pickup requests: $e');
      return [];
    }
  }
}
