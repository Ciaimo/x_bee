class EntitiesModel {
  String name;
  String type;

  //bool hasQueen;
  //int queenYear;
  //List<, int> frameCount;

  String? createdAt;

  EntitiesModel({
    required this.name,
    required this.type,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'createdAt': createdAt,
    };
  }

  factory EntitiesModel.fromMap(Map<String, dynamic> map) {
    return EntitiesModel(
      name: map['name'],
      type: map['type'],
      createdAt: map['createdAt'],
    );
  }
}
