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

// ✅ Updated provider for nested structure
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

    String? createdAt;
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate().toIso8601String();
    } else if (createdAtRaw != null) {
      createdAt = createdAtRaw.toString();
    }

    // 🧩 Nested maps
    final framesMap = Map<String, dynamic>.from(data['frames'] ?? {});
    final queenMap =
        data['queen'] != null ? Map<String, dynamic>.from(data['queen']) : null;

    // Safely parse integers
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return EntitiesModel(
      name: (data['name'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      createdAt: createdAt,
      frames: Frames(
        honeyFrames: parseInt(framesMap['honeyFrames']),
        broodFrames: parseInt(framesMap['broodFrames']),
        pollenFrames: parseInt(framesMap['pollenFrames']),
        emptyFrames: parseInt(framesMap['emptyFrames']),
      ),
      queen: queenMap != null
          ? Queen(
              hasQueen: queenMap['hasQueen'] == true,
              marked: queenMap['marked'] == true,
              year: parseInt(queenMap['year']),
              rating: parseInt(queenMap['rating']),
            )
          : null,
    );
  });
});
