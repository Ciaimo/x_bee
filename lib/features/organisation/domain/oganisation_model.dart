import 'package:uuid/uuid.dart';
import 'package:x_bee/features/organisation/domain/race_model.dart';

class OrganisationModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> membersIds;
  final OrganisationConstants? constants;
  final DateTime createdAt;

  OrganisationModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.membersIds,
    required this.createdAt,
    this.constants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'membersIds': membersIds,
      'createdAt': createdAt.toIso8601String(),
      if (constants != null) 'constants': constants!.toMap(),
    };
  }

  factory OrganisationModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return OrganisationModel(
      id: documentId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      membersIds: List<String>.from(map['membersIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      constants: map['constants'] != null
          ? OrganisationConstants.fromMap(map['constants'])
          : null,
    );
  }
}

class OrganisationConstants {
  final List<Race> races;

  OrganisationConstants({required this.races});

  factory OrganisationConstants.fromMap(Map<String, dynamic> map) {
    List<Race> parsedRaces = [];

    final rawRaces = map['races'];

    if (rawRaces is List) {
      // CASE 1: List of Maps → normal case
      if (rawRaces.isNotEmpty && rawRaces.first is Map) {
        parsedRaces = rawRaces
            .whereType<Map<String, dynamic>>()
            .map((raceMap) => Race.fromMap(raceMap))
            .toList();
      }
      // CASE 2: List of Strings → legacy / corrupted data
      else if (rawRaces.isNotEmpty && rawRaces.first is String) {
        // Convert each string into a Race with name = string, empty lines
        parsedRaces = rawRaces
            .whereType<String>()
            .map((name) => Race(
                  id: const Uuid().v4(), // generate ID
                  name: name,
                  lines: const [],
                ))
            .toList();
      }
    }

    return OrganisationConstants(races: parsedRaces);
  }

  Map<String, dynamic> toMap() {
    return {
      'races': races.map((race) => race.toMap()).toList(),
    };
  }
}