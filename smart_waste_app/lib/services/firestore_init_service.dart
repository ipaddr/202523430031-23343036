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

  /// Initialize sample pickup requests for testing/development
  Future<bool> initializeSamplePickupRequests() async {
    try {
      // Sample data dengan koordinat Jakarta area
      final sampleRequests = [
        {
          'uid': 'user_123',
          'user_id': 'user_123', // Sesuaikan dengan user ID
          'status': 'in_progress',
          'wasteType': 'Anorganik',
          'waste_type': 'Anorganik',
          'weight': '10 kg',
          'location': 'Jl. Ahmad Yani No. 45',
          'address': 'Jl. Ahmad Yani No. 45',
          'truck_location': {'latitude': -6.2088, 'longitude': 106.8456},
          'driver_name': 'Budi Santoso',
          'driver_phone': '08123456789',
          'estimated_arrival_time': '15 Menit',
          'notes': 'Sampah plastik dan kertas',
          'createdAt': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'user_456',
          'user_id': 'user_456',
          'status': 'pending',
          'wasteType': 'Organik',
          'waste_type': 'Organik',
          'weight': '5 kg',
          'location': 'Jl. Sudirman No. 12',
          'address': 'Jl. Sudirman No. 12',
          'truck_location': {'latitude': -6.2155, 'longitude': 106.8270},
          'driver_name': 'Ahmad Ridho',
          'driver_phone': '08987654321',
          'estimated_arrival_time': '20 Menit',
          'notes': 'Sampah dapur organik',
          'createdAt': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
      ];

      // Tambahkan sample requests ke collection
      for (var request in sampleRequests) {
        await _firestore.collection('pickup_requests').add(request);
      }

      debugPrint('✅ Sample pickup requests initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing sample requests: $e');
      return false;
    }
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

  /// Delete all sample data (for cleanup during testing)
  Future<bool> deleteSampleData() async {
    try {
      final querySnapshot = await _firestore
          .collection('pickup_requests')
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Sample data deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting sample data: $e');
      return false;
    }
  }

  /// Check if pickup requests collection exists and has data
  Future<bool> checkPickupRequestsCollection() async {
    try {
      final querySnapshot = await _firestore
          .collection('pickup_requests')
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking collection: $e');
      return false;
    }
  }
}
