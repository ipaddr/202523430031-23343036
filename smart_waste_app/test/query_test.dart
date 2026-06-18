import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_waste_app/firebase_options.dart';

void main() {
  test('Query real Firestore data', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final firestore = FirebaseFirestore.instance;

    print('==================== FIRESTORE QUERY START ====================');

    // Query petugas dari users collection (role=petugas)
    final petugas = await firestore
        .collection('users')
        .where('role', isEqualTo: 'petugas')
        .get();
    print('PETUGAS COUNT: ${petugas.docs.length}');
    for (var doc in petugas.docs) {
      print('PetugasDocId: ${doc.id}');
      print('  Name: ${doc.data()['name']}');
      print('  Email: ${doc.data()['email']}');
      print('  Status: ${doc.data()['status']}');
      print('  AssignedRequests: ${doc.data()['assignedRequests']}');
    }

    // Query pickup_requests
    final requests = await firestore.collection('pickup_requests').get();
    print('REQUESTS COUNT: ${requests.docs.length}');
    for (var doc in requests.docs) {
      print('RequestDocId: ${doc.id}');
      print('  Status: ${doc.data()['status']}');
      print('  OfficerID: ${doc.data()['officer_id']}');
      print('  AssignedOfficerID: ${doc.data()['assigned_officer_id']}');
      print('  UserName: ${doc.data()['user_name'] ?? doc.data()['name']}');
    }

    print('==================== FIRESTORE QUERY END ====================');
  });
}
