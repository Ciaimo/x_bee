class UserModel {
  final String uid;
  final String email;
  final String? name;
  final String? organisationId;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.organisationId,  
    this.name,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'organisationId': organisationId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      organisationId: map['organisationId'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}
