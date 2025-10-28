import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/features/organisation/domain/race_model.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'package:x_bee/main.dart'; // For AuthWrapper

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ✅ The TextEditingController must be here
  final TextEditingController _nameController = TextEditingController();

  // For Line management dialog (for the current line being edited)
  final TextEditingController _lineController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lineController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgIdAsync = ref.watch(organisationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: orgIdAsync.when(
        data: (orgId) {
          if (orgId == null || orgId.isEmpty) {
            return const Center(child: Text('No organisation found'));
          }

          final orgAsync = ref.watch(organisationProvider(orgId));

          return orgAsync.when(
            data: (organisation) {
              if (organisation == null) {
                return const Center(child: Text('Organisation not found'));
              }

              // Parse the List of Maps into a List of Race objects
              final List<Race> races = organisation.constants?.races ?? [];

              return _buildContent(context, orgId, races);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Error loading organisation: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  // ✅ All helper methods are now correctly inside the _SettingsScreenState class

  Widget _buildContent(BuildContext context, String orgId, List<Race> races) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, 'Account'),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile & Security'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        _buildLogoutButton(context),
        const Divider(height: 32),
        _buildRacesSection(
          context,
          title: 'Bee Races',
          description:
              'Define bee races and their specific lines available in your organisation.',
          races: races,
          orgId: orgId,
        ),
        const Divider(height: 32),
        _buildSectionHeader(context, 'App Preferences'),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Theme'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final repo = ref.watch(authRepositoryProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          await repo.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildRacesSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<Race> races,
    required String orgId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSectionHeader(context, title)),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New'),
              onPressed: () => _showAddRaceDialog(context, orgId),
            ),
          ],
        ),
        Text(description, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        if (races.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'No races defined yet. Tap "Add New" to create one.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: races.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 0.5, indent: 16),
              itemBuilder: (context, index) {
                final race = races[index];
                return ListTile(
                  leading: const Icon(Icons.hive_outlined),
                  title: Text(race.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${race.lines.length} lines defined'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ UPDATED: Call the new line management dialog
                      IconButton(
                        icon: const Icon(Icons.category_outlined,
                            size: 20, color: Colors.indigo),
                        onPressed: () =>
                            _showLineManagementDialog(context, orgId, race),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showEditRaceNameDialog(context, race.name, orgId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () => _showDeleteRaceConfirmation(
                            context, race.name, orgId),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // ✅ NEW: LINE MANAGEMENT DIALOG
  // -----------------------------------------------------------------------

  void _showLineManagementDialog(
      BuildContext context, String orgId, Race race) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Lines for ${race.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add New Line Button
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Line'),
                      onPressed: () =>
                          _showAddLineDialog(context, orgId, race.name),
                    ),
                  ],
                ),
              ),
              // List of Lines
              if (race.lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No lines defined for this race.'),
                )
              else
                Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: race.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 0.5),
                    itemBuilder: (context, index) {
                      final line = race.lines[index];
                      return ListTile(
                        title: Text(line),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditLineDialog(
                                  context, orgId, race.name, line),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 20, color: Colors.red),
                              onPressed: () => _showDeleteLineConfirmation(
                                  context, orgId, race.name, line),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // ✅ NEW: LINE DIALOGS (Add, Edit, Delete)
  // -----------------------------------------------------------------------

  void _showAddLineDialog(
      BuildContext parentContext, String orgId, String raceName) {
    _lineController.clear();

    // Close the parent dialog if it's open, then open the new one
    Navigator.pop(parentContext);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Line to $raceName'),
        content: TextField(
          controller: _lineController,
          decoration: const InputDecoration(labelText: 'Line Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final lineName = _lineController.text.trim();
              if (lineName.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(organisationRepositoryProvider);

              try {
                // 🎯 REPOSITORY CALL: Add line to a race
                await repo.updateOrganisation(
                  organisationId: orgId,
                  raceToUpdateName: raceName,
                  linesToAdd: [lineName],
                );

                Navigator.pop(ctx);
                _lineController.clear();
                messenger.showSnackBar(SnackBar(
                    content: Text('Added line "$lineName" to $raceName')));
              } catch (e) {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                    SnackBar(content: Text('Error adding line: $e')));
              }

              // Re-open the Line Management dialog after action
              final currentOrg = ref.read(organisationProvider(orgId)).value;
              final updatedRace = currentOrg?.constants?.races.firstWhere(
                (r) => r.name == raceName,
                orElse: () => Race(id: '', name: raceName, lines: const []),
              );

              if (updatedRace != null) {
                _showLineManagementDialog(context, orgId, updatedRace);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditLineDialog(BuildContext parentContext, String orgId,
      String raceName, String oldLineName) {
    _lineController.text = oldLineName;

    // Close the parent dialog
    Navigator.pop(parentContext);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Line in $raceName'),
        content: TextField(
          controller: _lineController,
          decoration: const InputDecoration(labelText: 'New Line Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newLineName = _lineController.text.trim();
              if (newLineName.isEmpty || newLineName == oldLineName) return;

              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(organisationRepositoryProvider);

              try {
                // 🎯 REPOSITORY CALL: Atomic update (Remove then Add)
                await repo.updateOrganisation(
                  organisationId: orgId,
                  raceToUpdateName: raceName,
                  linesToRemove: [oldLineName],
                );
                await repo.updateOrganisation(
                  organisationId: orgId,
                  raceToUpdateName: raceName,
                  linesToAdd: [newLineName],
                );

                Navigator.pop(ctx);
                _lineController.clear();
                messenger.showSnackBar(SnackBar(
                    content:
                        Text('Renamed line "$oldLineName" to "$newLineName"')));
              } catch (e) {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                    SnackBar(content: Text('Error editing line: $e')));
              }

              // Re-open the Line Management dialog after action
              final currentOrg = ref.read(organisationProvider(orgId)).value;
              final updatedRace = currentOrg?.constants?.races.firstWhere(
                (r) => r.name == raceName,
                orElse: () => Race(id: '', name: raceName, lines: const []),
              );

              if (updatedRace != null) {
                _showLineManagementDialog(context, orgId, updatedRace);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLineConfirmation(BuildContext parentContext, String orgId,
      String raceName, String lineName) {
    // Close the parent dialog
    Navigator.pop(parentContext);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Line'),
        content: Text(
            'Are you sure you want to delete the line "$lineName" from race "$raceName"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(organisationRepositoryProvider);

              try {
                // 🎯 REPOSITORY CALL: Remove line from a race
                await repo.updateOrganisation(
                  organisationId: orgId,
                  raceToUpdateName: raceName,
                  linesToRemove: [lineName],
                );

                Navigator.pop(ctx);
                messenger.showSnackBar(
                    SnackBar(content: Text('Deleted line "$lineName"')));
              } catch (e) {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                    SnackBar(content: Text('Error deleting line: $e')));
              }

              // Re-open the Line Management dialog after action
              final currentOrg = ref.read(organisationProvider(orgId)).value;
              final updatedRace = currentOrg?.constants?.races.firstWhere(
                (r) => r.name == raceName,
                orElse: () => Race(id: '', name: raceName, lines: const []),
              );

              if (updatedRace != null) {
                _showLineManagementDialog(context, orgId, updatedRace);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // ✅ RACE DIALOGS (Unchanged from previous update, now correctly scoped)
  // -----------------------------------------------------------------------

  void _showAddRaceDialog(BuildContext context, String orgId) {
    _nameController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Add New Race'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Race Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.label_important_outline),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(organisationRepositoryProvider);

              try {
                await repo.updateOrganisation(
                  organisationId: orgId,
                  newRaceName: name,
                );

                Navigator.pop(ctx);
                _nameController.clear();

                messenger.showSnackBar(
                  SnackBar(content: Text('Added "$name" to Races')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                _nameController.clear();

                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditRaceNameDialog(
    BuildContext context,
    String currentValue,
    String orgId,
  ) {
    _nameController.text = currentValue;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Edit Race Name'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              if (newName.isEmpty || newName == currentValue) return;

              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(organisationRepositoryProvider);

              try {
                await repo.updateOrganisation(
                  organisationId: orgId,
                  raceToRenameOldName: currentValue,
                  raceToRenameNewName: newName,
                );

                Navigator.pop(ctx);
                _nameController.clear();

                messenger.showSnackBar(
                  SnackBar(
                      content: Text('Renamed "$currentValue" → "$newName"')),
                );
              } catch (e) {
                Navigator.pop(ctx);
                _nameController.clear();

                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRaceConfirmation(
    BuildContext context,
    String raceName,
    String orgId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Delete Race'),
        content: Text(
            'Are you sure you want to delete the race "$raceName" and all its associated lines?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final repo = ref.read(organisationRepositoryProvider);
              try {
                await repo.updateOrganisation(
                  organisationId: orgId,
                  raceToDeleteName: raceName,
                );

                Navigator.pop(ctx);

                messenger.showSnackBar(
                  SnackBar(content: Text('Deleted race "$raceName"')),
                );
              } catch (e) {
                Navigator.pop(ctx);

                messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
