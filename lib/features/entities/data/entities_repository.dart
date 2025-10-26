import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
import 'package:x_bee/services/firebase_services.dart';

class EntitiesRepository {
  final FirebaseFirestore firestore = FirebaseServices.firestore;

  Future<String?> createEntity({
  required String organisationId,
  required EntitiesModel entity,
}) async {
  final docRef = firestore
      .collection('organisations')
      .doc(organisationId)
      .collection('entities')
      .doc(entity.name);

  await docRef.set(entity.toMap());
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
