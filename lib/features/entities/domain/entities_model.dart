import 'frames_model.dart';
import 'queen_model.dart';

class EntitiesModel {
  final String name;
  final String type;
  final Frames frames;
  final Queen? queen;
  final String? createdAt;

  EntitiesModel({
    required this.name,
    required this.type,
    required this.frames,
    this.queen,
    this.createdAt,
  });

  // Optional: fromJson / toJson if you use Firebase or API
  factory EntitiesModel.fromMap(Map<String, dynamic> data) {
    return EntitiesModel(
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      frames: Frames.fromMap(data['frames'] ?? {}),
      queen: data['queen'] != null ? Queen.fromMap(data['queen']) : null,
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'frames': frames.toMap(),
      if (queen != null) 'queen': queen!.toMap(),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
