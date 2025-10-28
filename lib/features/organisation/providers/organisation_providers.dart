import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/features/organisation/data/organisation_repository.dart';
import 'package:x_bee/features/organisation/domain/oganisation_model.dart';
import 'package:x_bee/services/firebase_services.dart';

final organisationRepositoryProvider = Provider<OrganisationRepository>((ref) {
  return OrganisationRepository();
});

final organisationIdProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final currentUser = auth.currentUser;

  if (currentUser == null) {
    return Stream.error('No authenticated user');
  }

  final orgRepo = ref.watch(organisationRepositoryProvider);
  return orgRepo.getOrganisationIdByUserId(currentUser.uid);
});

final organisationProvider =
    StreamProvider.family<OrganisationModel?, String>((ref, orgId) {
  if (orgId.isEmpty) return Stream.value(null);

  return FirebaseServices.firestore
      .collection('organisations')
      .doc(orgId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    return OrganisationModel.fromMap(data, documentId: snapshot.id);
  });
});
