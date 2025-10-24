import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:x_bee/services/firebase_services.dart';

class EntitiesRepository {
  final FirebaseFirestore firestore = FirebaseServices.firestore;

  Future<String?> createEntity(
      {required String type,
      required String name,
      required String organisationId,
      required bool hasQueen,
      required bool queenMarked,
      required String queenYear,
      required String queenRating}) async {
    // Simulate a network call or database operation
    final docRef = firestore
        .collection('organisations')
        .doc(organisationId)
        .collection('entities')
        .doc(name);

    await docRef.set({
      'type': type,
      'name': name,
      'hasQueen': hasQueen,
      'queenMarked': queenMarked,
      'queenYear': hasQueen ? int.parse(queenYear) : null,
      'queenRating': hasQueen ? int.parse(queenRating) : null,
      'createdAt': DateTime.now(),
    });

    return docRef.id;
  }

  Future<void> updateEntity({
    required String organisationId,
    required String entityId,
    required Map<String, dynamic> updates,
    bool merge = true,
  }) async {
    try {
      final docRef = firestore
          .collection('organisations')
          .doc(organisationId)
          .collection('entities')
          .doc(entityId);

      await docRef.set(
        {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: merge),
      );
    } catch (e) {
      throw Exception('Failed to update entity: $e');
    }
  }
}
