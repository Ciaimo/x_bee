import 'package:x_bee/features/auth/data/auth_repository.dart';
import 'package:x_bee/services/firebase_services.dart';

class OrganisationRepository {
  final authRepo = AuthRepository();

  Future<String?> createOrganisation(String name, String ownerId) async {
    try {
      final firestore = FirebaseServices.firestore;

      //Step 1 create organisation
      final orgRef = await firestore.collection('organisations').add({
        'name': name,
        'ownerId': ownerId,
        'membersIds': [ownerId],
        'createdAt': DateTime.now().toIso8601String(),
      });

      //Step 2: Add owner as memeber inside subcolletion
      final ownerDoc = await firestore.collection('users').doc(ownerId).get();
      final ownerData = ownerDoc.data();

      await firestore
          .collection('organisations')
          .doc(orgRef.id)
          .collection('users')
          .doc(ownerId)
          .set({
        'email': ownerData?['email'] ?? '',
        'role': 'owner',
        'joinedAt': DateTime.now().toIso8601String(),
      });

      //update global user doc
      await authRepo.addOrganisationId(ownerId, orgRef.id);
      return orgRef.id;
    } catch (e) {
      throw Exception('Create Organisation Error: ${e.toString()}');
    }
  }

  Stream<String?> getOrganisationIdByUserId(String userId) {
    return FirebaseServices.firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      // ✅ Don’t throw — just return null if no document yet
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      return data?['organisationId'].toString();
    });
  }

  Future<void> addMemberToOrganisation(String orgId, String uid, String email,
      {String role = 'member'}) async {
    await FirebaseServices.firestore
        .collection('organisations')
        .doc(orgId)
        .collection('users')
        .doc(uid)
        .set({
      'email': email,
      'role': role,
      'joinedAt': DateTime.now().toIso8601String(),
    });

    await authRepo.addOrganisationId(uid, orgId);
  }
}
