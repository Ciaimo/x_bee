import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/entities/data/entities_repository.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
import 'package:x_bee/features/entities/domain/frames_model.dart';
import 'package:x_bee/features/entities/domain/queen_model.dart';
import 'package:x_bee/services/firebase_services.dart';

final entitiesProvider = Provider<EntitiesRepository>((ref) {
  return EntitiesRepository();
});

class SingleEntityParams {
  final String organisationId;
  final String entityId;

  const SingleEntityParams({
    required this.organisationId,
    required this.entityId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SingleEntityParams &&
          runtimeType == other.runtimeType &&
          organisationId == other.organisationId &&
          entityId == other.entityId;

  @override
  int get hashCode => organisationId.hashCode ^ entityId.hashCode;
}

// ✅ SIMPLIFIED: Provider only calls the Repository method.
final singleEntityProvider = StreamProvider.autoDispose
    .family<EntitiesModel?, SingleEntityParams>((ref, params) {
  // 1. Get the repository instance
  final repository = ref.watch(entitiesProvider);

  // 2. Return the stream directly from the repository
  // The repository handles the Firestore access and the data mapping.
  return repository.getSingleEntityStream(
    organisationId: params.organisationId,
    entityId: params.entityId,
  );
});
