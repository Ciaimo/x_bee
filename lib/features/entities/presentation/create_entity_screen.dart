import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
import 'package:x_bee/features/entities/domain/frames_model.dart';
import 'package:x_bee/features/entities/domain/queen_model.dart';
import 'package:x_bee/features/entities/providers/entities_providers.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'package:x_bee/features/organisation/domain/race_model.dart'; // <-- already there

enum EntityType { beehive, nuc, matingnuc, starter, finisher }

String getEntityTypeName(EntityType type) {
  switch (type) {
    case EntityType.beehive:
      return 'Beehive';
    case EntityType.nuc:
      return 'Nuc';
    case EntityType.matingnuc:
      return 'Mating Nuc';
    case EntityType.starter:
      return 'Starter';
    case EntityType.finisher:
      return 'Finisher';
  }
}

class CreateEntityScreen extends ConsumerStatefulWidget {
  const CreateEntityScreen({super.key});

  @override
  ConsumerState<CreateEntityScreen> createState() => _CreateEntityScreenState();
}

class _CreateEntityScreenState extends ConsumerState<CreateEntityScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _queenYearController = TextEditingController();
  final _honeyFramesController = TextEditingController();
  final _broodFramesController = TextEditingController();
  final _pollenFramesController = TextEditingController();
  final _emptyFramesController = TextEditingController();

  // State variables
  EntityType? _selectedType;
  Race? _selectedRace;          // <-- full Race object
  String? _selectedLine;        // <-- line string (belongs to the selected race)
  bool _hasQueen = false;
  bool _queenMarked = false;
  int? _queenRating;

  @override
  void dispose() {
    _nameController.dispose();
    _queenYearController.dispose();
    _honeyFramesController.dispose();
    _broodFramesController.dispose();
    _pollenFramesController.dispose();
    _emptyFramesController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // UI helpers (unchanged)
  // ──────────────────────────────────────────────────────────────
  Widget _buildNumberField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _getInputDecoration(labelText: label, prefixIcon: icon),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (int.tryParse(v) == null) return 'Enter a valid number';
        return null;
      },
    );
  }

  InputDecoration _getInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // MAIN BUILD
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final entitiesRef = ref.watch(entitiesProvider);
    final orgIdAsync = ref.watch(organisationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Entity'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: orgIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error this is orgIDASYNC: $err')),
        data: (orgId) {
          if (orgId == null || orgId.isEmpty) {
            return const Center(child: Text('No organisation linked.'));
          }

          final organisationAsync = ref.watch(organisationProvider(orgId));

          return organisationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading organisation ID: $orgId $err'),
            data: (org) {
              if (org == null) {
                return const Center(child: Text('Organisation not found.'));
              }

              // ----------------------------------------------------
              // 1. Races (already parsed inside OrganisationConstants)
              // ----------------------------------------------------
              final List<Race> races = org.constants?.races ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ------------------ Entity Details ------------------
                        _buildSectionTitle('General Entity Details', Icons.info_outline),

                        DropdownButtonFormField<EntityType>(
                          value: _selectedType,
                          decoration: _getInputDecoration(
                            labelText: 'Entity Type',
                            prefixIcon: Icons.hive_outlined,
                          ),
                          hint: const Text('Choose a Type (Required)'),
                          isExpanded: true,
                          items: EntityType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(getEntityTypeName(type)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedType = val),
                          validator: (val) => val == null ? 'Please select an entity type' : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nameController,
                          decoration: _getInputDecoration(
                            labelText: 'Entity Name',
                            hintText: 'e.g., Beehive 101',
                            prefixIcon: Icons.drive_file_rename_outline,
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Entity name required' : null,
                        ),

                        const SizedBox(height: 32),

                        // ------------------ Queen Section ------------------
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSectionTitle('Queen Information', Icons.pets_outlined),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Has Queen', style: TextStyle(fontSize: 16)),
                                    Switch.adaptive(
                                      value: _hasQueen,
                                      onChanged: (val) => setState(() => _hasQueen = val),
                                      activeColor: primaryColor,
                                    ),
                                  ],
                                ),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: !_hasQueen
                                      ? const SizedBox.shrink()
                                      : Column(
                                          children: [
                                            const Divider(height: 24),

                                            // Queen Year
                                            TextFormField(
                                              controller: _queenYearController,
                                              keyboardType: TextInputType.number,
                                              decoration: _getInputDecoration(
                                                labelText: 'Queen Year (e.g. 2024)',
                                                prefixIcon: Icons.calendar_today,
                                              ),
                                              validator: (v) {
                                                if (_hasQueen) {
                                                  if (v == null || v.isEmpty) return 'Please enter queen year';
                                                  if (int.tryParse(v) == null) return 'Enter a valid year';
                                                }
                                                return null;
                                              },
                                            ),

                                            const SizedBox(height: 16),

                                            // Queen Marked
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Queen Marked', style: TextStyle(fontSize: 16)),
                                                Switch.adaptive(
                                                  value: _queenMarked,
                                                  onChanged: (val) => setState(() => _queenMarked = val),
                                                  activeColor: primaryColor,
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 16),

                                            // ───── RACE DROPDOWN ─────
                                            DropdownButtonFormField<Race>(
                                              value: _selectedRace,
                                              decoration: _getInputDecoration(
                                                labelText: 'Queen Race',
                                                prefixIcon: Icons.pets_outlined,
                                              ),
                                              hint: const Text('Select race'),
                                              items: races
                                                  .map((race) => DropdownMenuItem<Race>(
                                                        value: race,
                                                        child: Text(race.name),
                                                      ))
                                                  .toList(),
                                              onChanged: (Race? newRace) {
                                                setState(() {
                                                  _selectedRace = newRace;
                                                  _selectedLine = null; // reset line when race changes
                                                });
                                              },
                                            ),

                                            const SizedBox(height: 16),

                                            // ───── LINE DROPDOWN (depends on selected race) ─────
                                            Consumer(
                                              builder: (context, ref, child) {
                                                final List<String> currentLines =
                                                    _selectedRace?.lines ?? [];

                                                return DropdownButtonFormField<String>(
                                                  value: _selectedLine,
                                                  decoration: _getInputDecoration(
                                                    labelText: 'Queen Line',
                                                    prefixIcon: Icons.line_weight_outlined,
                                                  ),
                                                  hint: const Text('Select line (optional)'),
                                                  items: currentLines
                                                      .map((line) => DropdownMenuItem(
                                                            value: line,
                                                            child: Text(line),
                                                          ))
                                                      .toList(),
                                                  onChanged: (String? line) => setState(() => _selectedLine = line),
                                                );
                                              },
                                            ),

                                            const SizedBox(height: 16),

                                            // Rating
                                            DropdownButtonFormField<int>(
                                              value: _queenRating,
                                              decoration: _getInputDecoration(
                                                labelText: 'Queen Rating (1–5)',
                                                prefixIcon: Icons.star_half_outlined,
                                              ),
                                              items: List.generate(5, (i) => i + 1)
                                                  .map((v) => DropdownMenuItem(value: v, child: Text(v.toString())))
                                                  .toList(),
                                              onChanged: (v) => setState(() => _queenRating = v),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ------------------ Frames Section ------------------
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildSectionTitle('Beehive Interior Status', Icons.dashboard_outlined),

                                _buildNumberField(_honeyFramesController, 'Number of Honey Frames', Icons.cake_outlined),
                                const SizedBox(height: 16),
                                _buildNumberField(_broodFramesController, 'Number of Brood Frames', Icons.child_care_outlined),
                                const SizedBox(height: 16),
                                _buildNumberField(_pollenFramesController, 'Number of Pollen Frames', Icons.eco_outlined),
                                const SizedBox(height: 16),
                                _buildNumberField(_emptyFramesController, 'Number of Empty Frames', Icons.texture_outlined),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ------------------ Submit ------------------
                        ElevatedButton.icon(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;

                            final entity = EntitiesModel(
                              name: _nameController.text.trim(),
                              type: _selectedType != null ? getEntityTypeName(_selectedType!) : '',
                              createdAt: DateTime.now().toIso8601String(),
                              frames: Frames(
                                honeyFrames: int.tryParse(_honeyFramesController.text) ?? 0,
                                broodFrames: int.tryParse(_broodFramesController.text) ?? 0,
                                pollenFrames: int.tryParse(_pollenFramesController.text) ?? 0,
                                emptyFrames: int.tryParse(_emptyFramesController.text) ?? 0,
                              ),
                              queen: _hasQueen
                                  ? Queen(
                                      hasQueen: _hasQueen,
                                      marked: _queenMarked,
                                      year: int.tryParse(_queenYearController.text) ?? 0,
                                      rating: _queenRating ?? 0,
                                      race: _selectedRace?.name ?? '',
                                      line: _selectedLine ?? '',
                                    )
                                  : null,
                            );

                            entitiesRef.createEntity(organisationId: orgId, entity: entity);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Create Entity', style: TextStyle(fontSize: 18)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}