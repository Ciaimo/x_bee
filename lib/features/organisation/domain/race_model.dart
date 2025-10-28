import 'package:uuid/uuid.dart';

const Uuid uuid = Uuid();

class Race {
  // Use a unique ID to safely identify and update the map within the list
  final String id;
  final String name;
  final List<String> lines; // The lines specific to THIS race

  Race({
    required this.id,
    required this.name,
    this.lines = const [],
  });

  // Factory to create a Race from a Firestore map
  factory Race.fromMap(Map<String, dynamic> map) {
    return Race(
      // 💡 If 'id' is missing (e.g., in legacy data), generate a new one.
      id: map['id'] ?? uuid.v4(),
      name: map['name'] as String? ?? '',
      lines: _parseList(map['lines']),
    );
  }

  // Method to convert the Race back into a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lines': lines,
    };
  }

  // Helper to safely parse the lines list
  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
