import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  Future<void> cancelRequest(String uId) async {
    // Fetch the last booking document
    QuerySnapshot snapshot = await _db
        .collection('bookings')
        .where('uId', isEqualTo: uId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      DocumentSnapshot lastRequest = snapshot.docs.first;
      await lastRequest.reference.update({'status': 'cancelled'});
    }
  }

  Stream<Map<String, dynamic>?> streamLastRequestStatus(String uId) {
    return _db
        .collection('bookings')
        .where('uId', isEqualTo: uId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'status': doc['status'] as String?,
          'requestId': doc.id,
        };
      }
      return null;
    });
  }

  Future<String> getVehicleNumber(String documentId) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(documentId)
          .get();

      if (docSnapshot.exists) {
        String vehicleNumber = docSnapshot.get('vehicleNumber');
        return vehicleNumber;
      } else {
        return 'Error';
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return 'Error';
    }
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createRequest(
      String uId,
      String uName,
      String uEmail,
      String currentLocation,
      String destination,
      String designation,
      String luggage,
      String purpose) async {
    await _db.collection('bookings').add({
      'uId': uId,
      'uName': uName,
      'uEmail': uEmail,
      'currentLocation': currentLocation,
      'destination': destination,
      'designation': designation,
      'luggage': luggage,
      'purpose': purpose,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
