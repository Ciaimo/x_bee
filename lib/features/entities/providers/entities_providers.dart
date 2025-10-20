import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/entities/data/entities_repository.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
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

  // Add equality overrides for proper provider caching
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

// FIXED: Added .autoDispose to properly manage the stream lifecycle
final singleEntityProvider = StreamProvider.autoDispose
    .family<EntitiesModel?, SingleEntityParams>((ref, params) {
  final docRef = FirebaseServices.firestore
      .collection('organisations')
      .doc(params.organisationId)
      .collection('entities')
      .doc(params.entityId);

  return docRef.snapshots().map((snap) {
    print(
        'singleEntityProvider: ${params.organisationId}/${params.entityId} -> exists=${snap.exists} data=${snap.data()}');

    if (!snap.exists) return null;
    final data = snap.data()!;
    final name = (data['name'] ?? '').toString();
    final type = (data['type'] ?? '').toString();
    final hasQueen = (data['hasQueen'] == true) ||
        (data['hasQueen']?.toString().toLowerCase() == 'true');

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final queenYear = parseInt(data['queenYear']);
    final queenRating = parseInt(data['queenRating']);
    String? createdAt;
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate().toIso8601String();
    } else if (createdAtRaw != null) {
      createdAt = createdAtRaw.toString();
    }

    return EntitiesModel(
      name: name,
      type: type,
      hasQueen: hasQueen,
      queenYear: queenYear,
      queenRating: queenRating,
      createdAt: createdAt,
    );
  });
});
