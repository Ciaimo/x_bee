import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
import 'package:x_bee/features/entities/domain/frames_model.dart';
import 'package:x_bee/features/entities/domain/queen_model.dart';
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

  // 💡 NEW METHOD: Responsible for all Firestore stream logic
  Stream<EntitiesModel?> getSingleEntityStream({
    required String organisationId,
    required String entityId,
  }) {
    final docRef = firestore
        .collection('organisations')
        .doc(organisationId)
        .collection('entities')
        .doc(entityId);

    // ALL data access and mapping logic goes here
    return docRef.snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;

      // --- ALL data parsing logic moved here ---

      String? createdAt;

      final createdAtRaw = data['createdAt'];

      if (createdAtRaw is Timestamp) {
        createdAt = createdAtRaw.toDate().toIso8601String();
      } else if (createdAtRaw != null) {
        createdAt = createdAtRaw.toString();
      }

      // 🧩 Nested maps
      final framesMap = Map<String, dynamic>.from(data['frames'] ?? {});
      final queenMap = data['queen'] != null
          ? Map<String, dynamic>.from(data['queen'])
          : null;

      // Safely parse integers (Helper function is also best placed in the model or repository)
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
                race: queenMap['race'],
                line: queenMap['line'],
              )
            : null,
      );
    });
  }
}
