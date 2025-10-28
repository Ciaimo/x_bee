import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:x_bee/features/auth/data/auth_repository.dart';
import 'package:x_bee/features/organisation/domain/oganisation_model.dart';
import 'package:x_bee/features/organisation/domain/race_model.dart';
import 'package:x_bee/services/firebase_services.dart';

class OrganisationRepository {
  final authRepo = AuthRepository();
  final FirebaseFirestore firestore = FirebaseServices.firestore;

  Future<OrganisationModel?> createOrganisation(
      String name, String ownerId) async {
    try {
      final firestore = FirebaseServices.firestore;

      //Step 1 create organisation
      final orgRef = await firestore.collection('organisations').add({
        'name': name,
        'ownerId': ownerId,
        'membersIds': [ownerId],
        'createdAt': DateTime.now().toIso8601String(),
      });

      //Step 2: Add owner as memeber inside subcolletion
      final ownerDoc = await firestore.collection('users').doc(ownerId).get();
      final ownerData = ownerDoc.data();

      await firestore
          .collection('organisations')
          .doc(orgRef.id)
          .collection('users')
          .doc(ownerId)
          .set({
        'email': ownerData?['email'] ?? '',
        'role': 'owner',
        'joinedAt': DateTime.now().toIso8601String(),
        'constants': {
          'races': ['NOT DEFINED'],
          'lines': ['NOT DEFINED']
        }
      });

      //update global user doc
      await authRepo.addOrganisationId(ownerId, orgRef.id);
      // ✅ Return a typed model
      return OrganisationModel(
        id: orgRef.id,
        name: name,
        ownerId: ownerId,
        membersIds: [ownerId],
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Create Organisation Error: ${e.toString()}');
    }
  }

  Stream<String?> getOrganisationIdByUserId(String userId) {
    return FirebaseServices.firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      // ✅ Don’t throw — just return null if no document yet
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      return data?['organisationId'].toString();
    });
  }

  // 🎯 THE CRITICAL METHOD TO UPDATE 🎯
  Future<void> updateOrganisation({
    required String organisationId,
    // Use a map of updates for flexibility
    Map<String, dynamic>? organisationFieldsToUpdate,

    // Parameters for Race Management (Add/Rename/Delete)
    String? newRaceName,
    String? raceToRenameOldName,
    String? raceToRenameNewName,
    String? raceToDeleteName,

    // Parameters for Race Line Management
    String? raceToUpdateName, // Name of the race to modify lines for
    List<String> linesToAdd = const [],
    List<String> linesToRemove = const [],
  }) async {
    final docRef = firestore.collection('organisations').doc(organisationId);

    // --- SIMPLE FIELD UPDATES (if any) ---
    if (organisationFieldsToUpdate != null) {
      await docRef.update(organisationFieldsToUpdate);
      // If only simple fields are updated, we return here.
    }

    // We MUST fetch the current document if we are modifying the nested list.
    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data == null || data['constants'] == null) {
      throw Exception('Organisation or constants field not found.');
    }

    // 1. Get and parse the current list of Races
    final rawRaces = data['constants']['races'] as List<dynamic>? ?? [];
    List<Race> currentRaces = rawRaces
        .whereType<Map<String, dynamic>>()
        .map((map) => Race.fromMap(map))
        .toList();

    // A. Handle Add/Rename/Delete Race
    if (newRaceName != null ||
        raceToRenameOldName != null ||
        raceToDeleteName != null) {
      currentRaces = _updateRacesList(
        currentRaces: currentRaces,
        newRaceName: newRaceName,
        oldName: raceToRenameOldName,
        newName: raceToRenameNewName,
        raceToDelete: raceToDeleteName,
      );
    }

    // B. Handle Lines within a Race
    else if (raceToUpdateName != null &&
        (linesToAdd.isNotEmpty || linesToRemove.isNotEmpty)) {
      currentRaces = _updateRaceLines(
        currentRaces: currentRaces,
        raceName: raceToUpdateName,
        linesToAdd: linesToAdd,
        linesToRemove: linesToRemove,
      );
    } else {
      // No specific updates, return
      return;
    }

    // 2. Prepare the final update map: convert List<Race> back to List<Map>
    final updatedRacesMapList = currentRaces.map((r) => r.toMap()).toList();

    // 3. Perform the direct update (overwriting the entire array)
    await docRef.update({
      'constants.races': updatedRacesMapList,
    });
  }

  Future<void> addMemberToOrganisation(
      {required String orgId,
      required String uid,
      required String email,
      String role = 'member'}) async {
    await FirebaseServices.firestore
        .collection('organisations')
        .doc(orgId)
        .collection('users')
        .doc(uid)
        .set({
      'email': email,
      'role': role,
      'joinedAt': DateTime.now().toIso8601String(),
    });

    await authRepo.addOrganisationId(uid, orgId);
  }

  List<Race> _updateRacesList({
    required List<Race> currentRaces,
    String? newRaceName,
    String? oldName,
    String? newName,
    String? raceToDelete,
  }) {
    List<Race> races = List.from(currentRaces); // Create a mutable copy

    if (raceToDelete != null) {
      // Delete Logic
      races.removeWhere((r) => r.name == raceToDelete);
    } else if (oldName != null && newName != null) {
      // Rename Logic
      final index = races.indexWhere((r) => r.name == oldName);
      if (index != -1) {
        final originalRace = races[index];
        races[index] = Race(
          id: originalRace.id,
          name: newName, // New name
          lines: originalRace.lines,
        );
      }
    } else if (newRaceName != null) {
      // Add Logic
      if (!races.any((r) => r.name == newRaceName)) {
        races.add(Race(id: uuid.v4(), name: newRaceName));
      }
    }
    return races;
  }

  List<Race> _updateRaceLines({
    required List<Race> currentRaces,
    required String raceName,
    required List<String> linesToAdd,
    required List<String> linesToRemove,
  }) {
    List<Race> races = List.from(currentRaces); // Create a mutable copy

    final index = races.indexWhere((r) => r.name == raceName);

    if (index != -1) {
      final raceToModify = races[index];

      // Perform set operations on lines for safe removal/addition
      Set<String> updatedLines = raceToModify.lines.toSet();
      updatedLines.removeAll(linesToRemove);
      updatedLines.addAll(linesToAdd);

      // Create a new updated Race object and replace the old one
      races[index] = Race(
        id: raceToModify.id,
        name: raceToModify.name,
        lines: updatedLines.toList(),
      );
    }
    return races;
  }
}
