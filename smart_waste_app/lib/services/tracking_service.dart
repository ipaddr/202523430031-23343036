import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  late final FirebaseFirestore _firestore;

  factory TrackingService() {
    return _instance;
  }

  TrackingService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Get user's current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Stream user's real-time location with high accuracy
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Get truck location from Firestore based on request ID
  Future<Map<String, dynamic>?> getTruckLocation(String requestId) async {
    try {
      final doc = await _firestore
          .collection('pickup_requests')
          .doc(requestId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('truck_location')) {
          return {
            'latitude': data['truck_location']['latitude'],
            'longitude': data['truck_location']['longitude'],
            'driver_name': data['driver_name'] ?? 'Petugas',
            'estimated_time': data['estimated_arrival_time'] ?? '',
            'status': data['status'] ?? 'pending',
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting truck location: $e');
      return null;
    }
  }

  /// Stream truck location updates real-time
  Stream<Map<String, dynamic>> getTruckLocationStream(String requestId) {
    return _firestore
        .collection('pickup_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data();
            if (data != null && data.containsKey('truck_location')) {
              return {
                'latitude': data['truck_location']['latitude'],
                'longitude': data['truck_location']['longitude'],
                'driver_name': data['driver_name'] ?? 'Petugas',
                'estimated_time': data['estimated_arrival_time'] ?? '',
                'status': data['status'] ?? 'pending',
                'phone': data['driver_phone'] ?? '',
              };
            }
          }
          return {};
        });
  }

  /// Calculate distance between two coordinates (in km)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of Earth in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_toRad(lat1)) *
            Math.cos(_toRad(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2));
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double degree) {
    return degree * (3.14159265359 / 180);
  }

  /// Get all active pickup requests for user
  Future<List<Map<String, dynamic>>> getActiveRequests(String userId) async {
    try {
      final byUserId = await _firestore
          .collection('pickup_requests')
          .where('user_id', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
          .get();

      final byUid = await _firestore
          .collection('pickup_requests')
          .where('uid', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'accepted', 'in_progress'])
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

      addResults(byUserId);
      addResults(byUid);

      merged.sort((a, b) => _pickupRequestTimestamp(b).compareTo(
        _pickupRequestTimestamp(a),
      ));

      return merged;
    } catch (e) {
      debugPrint('Error getting active requests: $e');
      return [];
    }
  }

  /// Update tracking status in Firestore
  Future<bool> updateTrackingStatus(String requestId, String status) async {
    try {
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating tracking status: $e');
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
}

// Math helper since we can't import dart:math in some cases
class Math {
  static double sin(double x) => math.sin(x);
  static double cos(double x) => math.cos(x);
  static double sqrt(double x) => math.sqrt(x);
  static double atan2(double y, double x) => math.atan2(y, x);
}
