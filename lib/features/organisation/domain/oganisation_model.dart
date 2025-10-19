class OrganisationModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> membersIds;
  final DateTime createdAt;

  OrganisationModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.membersIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'membersIds': membersIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrganisationModel.fromMap(Map<String, dynamic> map) {
    return OrganisationModel(
      id: map['id'],
      name: map['name'],
      ownerId: map['ownerId'],
      membersIds: List<String>.from(map['membersIds']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
