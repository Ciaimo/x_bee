import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
import 'package:x_bee/features/entities/domain/frames_model.dart';
import 'package:x_bee/features/entities/domain/queen_model.dart';
import 'package:x_bee/features/entities/providers/entities_providers.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';

// ----------------------------------------------------------------------
// 1. Placeholder Data (Kept as is)
// ----------------------------------------------------------------------

/// Enum to represent the different types of entities.
enum EntityType {
  beehive,
  nuc,
  matingnuc,
  starter,
  finisher,
}

/// Helper function to convert the enum to a human-readable string.
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

// ----------------------------------------------------------------------
// 2. The Entity Creation Page Widget (Styled)
// ----------------------------------------------------------------------

class CreateEntityScreen extends ConsumerStatefulWidget {
  const CreateEntityScreen({super.key});

  @override
  ConsumerState<CreateEntityScreen> createState() => _CreateEntityScreenState();
}

class _CreateEntityScreenState extends ConsumerState<CreateEntityScreen> {
  // State variables for the form
  EntityType? _selectedType;
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String orgID = '';

  // queen info
  bool _hasQueen = false;
  bool _queenMarked = false;
  final TextEditingController _queenYearController = TextEditingController();
  int? _queenRating;

  // **CRITICAL FIX: Renamed and added unique controllers**
  // beehive info
  final TextEditingController _honeyFramesController = TextEditingController();
  final TextEditingController _broodFramesController = TextEditingController();
  final TextEditingController _pollenFramesController =
      TextEditingController(); // Corrected spelling
  final TextEditingController _emptyFramesController = TextEditingController();

  @override
  void dispose() {
    // Dispose of all controllers to prevent memory leaks
    _nameController.dispose();
    _queenYearController.dispose();
    _honeyFramesController.dispose();
    _broodFramesController.dispose();
    _pollenFramesController.dispose();
    _emptyFramesController.dispose();
    super.dispose();
  }

  // Helper for consistent field styling
  InputDecoration _getInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      fillColor: Colors.white, // Lighter background for fields
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), // More rounded corners
        borderSide:
            BorderSide.none, // Hide default border when using filled: true
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0), // Highlight on focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  // Helper for section titles
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final entitiesRef = ref.watch(entitiesProvider);
    final orgIdRepo = ref.watch(organisationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Entity'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- 1. Entity Type Dropdown ---
                _buildSectionTitle(
                    'General Entity Details', Icons.info_outline),

                DropdownButtonFormField<EntityType>(
                  initialValue: _selectedType,
                  decoration: _getInputDecoration(
                    labelText: 'Entity Type',
                    prefixIcon: Icons.hive_outlined,
                  ),
                  hint: const Text('Choose a Type (Required)'),
                  isExpanded: true,
                  items: EntityType.values.map((EntityType type) {
                    return DropdownMenuItem<EntityType>(
                      value: type,
                      child: Text(getEntityTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (EntityType? newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  validator: (EntityType? value) {
                    if (value == null) {
                      return 'Please select an entity type.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16.0),

                // --- 2. Entity Name Text Field ---
                TextFormField(
                  controller: _nameController,
                  decoration: _getInputDecoration(
                    labelText: 'Entity Name',
                    hintText: 'e.g., Beehive 101',
                    prefixIcon: Icons.drive_file_rename_outline,
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Entity Name cannot be empty.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32.0),

                // -------------------------------------------------------------
                // --- 3. Queen Information Card (Styled) ----------------------
                // -------------------------------------------------------------
                Card(
                  elevation: 6.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle('Queen Information', Icons.info),

                        // Has Queen Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Has Queen',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            Switch.adaptive(
                              value: _hasQueen,
                              onChanged: (val) =>
                                  setState(() => _hasQueen = val),
                              activeColor: primaryColor,
                            ),
                          ],
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _hasQueen
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Divider(height: 24),

                                    // Queen Year Input
                                    TextFormField(
                                      controller: _queenYearController,
                                      keyboardType: TextInputType.number,
                                      decoration: _getInputDecoration(
                                        labelText: 'Queen Year (e.g. 2023)',
                                        prefixIcon: Icons.calendar_today,
                                      ),
                                      validator: (v) {
                                        if (_hasQueen) {
                                          if (v == null || v.isEmpty) {
                                            return 'Please enter queen year';
                                          }
                                          if (int.tryParse(v) == null) {
                                            return 'Enter a valid year';
                                          }
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Queen Marked Switch
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Queen Marked',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Switch.adaptive(
                                          value: _queenMarked,
                                          onChanged: (val) => setState(
                                              () => _queenMarked = val),
                                          activeColor: primaryColor,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Queen Rating Dropdown
                                    DropdownButtonFormField<int>(
                                      value: _queenRating,
                                      decoration: _getInputDecoration(
                                        labelText: 'Queen Rating (1-5)',
                                        prefixIcon: Icons.star_half_outlined,
                                      ),
                                      items: List.generate(5, (i) => i + 1)
                                          .map((v) => DropdownMenuItem<int>(
                                              value: v,
                                              child: Text(v.toString())))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _queenRating = v),
                                      validator: (v) {
                                        if (_hasQueen && v == null) {
                                          return 'Please select a rating';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // -------------------------------------------------------------
                // --- 4. Beehive Interior Status Card (Styled and Fixed) ------
                // -------------------------------------------------------------
                Card(
                  elevation: 6.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  // Removed explicit background color
                  // color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionTitle('Beehive Interior Status',
                            Icons.dashboard_outlined),

                        // 1. Honey Frames Input
                        TextFormField(
                          // **FIXED CONTROLLER**
                          controller: _honeyFramesController,
                          keyboardType: TextInputType.number,
                          decoration: _getInputDecoration(
                            labelText: 'Number of Honey Frames',
                            hintText: 'e.g., 5',
                            prefixIcon: Icons.cake_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter number of honey frames';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16.0),

                        // 2. Brood Frames Input
                        TextFormField(
                          // **FIXED CONTROLLER**
                          controller: _broodFramesController,
                          keyboardType: TextInputType.number,
                          decoration: _getInputDecoration(
                            labelText: 'Number of Brood Frames',
                            hintText: 'e.g., 8',
                            prefixIcon: Icons.child_care_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter number of brood frames';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16.0),

                        // 3. Pollen Frames Input (Corrected 'polen' to 'pollen' in both label and controller)
                        TextFormField(
                          // **FIXED CONTROLLER**
                          controller: _pollenFramesController,
                          keyboardType: TextInputType.number,
                          decoration: _getInputDecoration(
                            labelText: 'Number of Pollen Frames',
                            hintText: 'e.g., 2',
                            prefixIcon: Icons.eco_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter number of pollen frames';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16.0),

                        // 4. Empty Frames Input
                        TextFormField(
                          // **FIXED CONTROLLER**
                          controller: _emptyFramesController,
                          keyboardType: TextInputType.number,
                          decoration: _getInputDecoration(
                            labelText: 'Number of Empty Frames',
                            hintText: 'e.g., 1',
                            prefixIcon: Icons.texture_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter number of empty frames';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40.0),

                // Organisation ID handling (Kept as is)
                orgIdRepo.when(
                  data: (orgId) {
                    orgID = orgId ?? '';
                    return const SizedBox.shrink(); // Use shrink for zero space
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Error: $err'),
                ),

                // --- 5. Submission Button (Styled) ---
                ElevatedButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    final newEntity = EntitiesModel(
                      name: _nameController.text,
                      type: _selectedType != null
                          ? getEntityTypeName(_selectedType!)
                          : '',
                      frames: Frames(
                        honeyFrames:
                            int.tryParse(_honeyFramesController.text) ?? 0,
                        broodFrames:
                            int.tryParse(_broodFramesController.text) ?? 0,
                        pollenFrames:
                            int.tryParse(_pollenFramesController.text) ?? 0,
                        emptyFrames:
                            int.tryParse(_emptyFramesController.text) ?? 0,
                      ),
                      queen: _hasQueen
                          ? Queen(
                              hasQueen: _hasQueen,
                              marked: _queenMarked,
                              year:
                                  int.tryParse(_queenYearController.text) ?? 0,
                              rating: _queenRating ?? 0,
                            )
                          : null,
                    );

                    entitiesRef.createEntity(
                        organisationId: orgID, entity: newEntity);

                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Create Entity',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
