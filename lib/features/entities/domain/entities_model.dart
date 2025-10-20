class EntitiesModel {
  String name;
  String type;

  bool hasQueen;
  int queenYear;
  int queenRating;
  //List<, int> frameCount;

  String? createdAt;

  EntitiesModel({
    required this.name,
    required this.type,
    required this.hasQueen,
    required this.queenYear,
    required this.queenRating,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'hasQueen': hasQueen,
      'queenYear': queenYear,
      'queenRating': queenRating,
      'createdAt': createdAt,
    };
  }

  factory EntitiesModel.fromMap(Map<String, dynamic> map) {
    return EntitiesModel(
      name: map['name'],
      type: map['type'],
      hasQueen: map['hasQueen'],
      queenYear: map['queenYear'],
      queenRating: map['queenRating'],
      createdAt: map['createdAt'],
    );
  }
}
