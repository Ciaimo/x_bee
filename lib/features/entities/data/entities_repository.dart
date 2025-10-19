import 'package:x_bee/services/firebase_services.dart';

class EntitiesRepository {
  final firestore = FirebaseServices.firestore;

  Future<String?> createEntity(
      String type, String name, String organisationId) async {
    // Simulate a network call or database operation
    final docRef = firestore
        .collection('organisations')
        .doc(organisationId)
        .collection('entities')
        .doc(name);

    await docRef.set({
      'type': type,
      'name': name,
      'createdAt': DateTime.now(),
    });

    return docRef.id;
  }
}
