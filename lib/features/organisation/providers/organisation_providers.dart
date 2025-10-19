import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/features/organisation/data/organisation_repository.dart';

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
