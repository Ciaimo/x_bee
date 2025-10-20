import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/entities/providers/entities_providers.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';

// ----------------------------------------------------------------------
// 1. Placeholder Data
// ----------------------------------------------------------------------

/// Enum to represent the different types of entities.
enum EntityType {
  beehive,
  nuc,
  mating_nuc,
  starter,
  Finisher,
}

/// Helper function to convert the enum to a human-readable string.
String getEntityTypeName(EntityType type) {
  switch (type) {
    case EntityType.beehive:
      return 'Beehive';
    case EntityType.nuc:
      return 'Nuc';
    case EntityType.mating_nuc:
      return 'Mating Nuc';
    case EntityType.starter:
      return 'Starter';
    case EntityType.Finisher:
      return 'Finisher';
  }
}

// ----------------------------------------------------------------------
// 2. The Entity Creation Page Widget
// ----------------------------------------------------------------------

class CreateEntityScreen extends ConsumerStatefulWidget {
  const CreateEntityScreen({super.key});

  @override
  ConsumerState<CreateEntityScreen> createState() => _CreateEntityScreenState();
}

class _CreateEntityScreenState extends ConsumerState<CreateEntityScreen> {
  // State variables for the form
  EntityType? _selectedType; // Null initially for the placeholder
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String orgID = '';

  bool _hasQueen = false;
  final TextEditingController _queenYearController = TextEditingController();
  int? _queenRating;

  @override
  Widget build(BuildContext context) {
    final entitiesRef = ref.watch(entitiesProvider);
    final orgIdRepo = ref.watch(organisationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Entity'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- 1. Entity Type Dropdown ---
                const Text(
                  'Select Entity Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<EntityType>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    // labelText: 'Entity Type', // Not needed if using the hint
                  ),
                  // *** Placeholder for you to change ***
                  hint: const Text('Choose a Type (Required)'),
                  // **********************************

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

                  // Validation logic for the dropdown
                  validator: (EntityType? value) {
                    if (value == null) {
                      return 'Please select an entity type.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24.0),

                // --- 2. Entity Name Text Field ---
                const Text(
                  'Entity Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Beehive 101',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.drive_file_rename_outline),
                  ),
                  // Validation logic for the text field
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Entity Name cannot be empty.';
                    }
                    return null;
                  },
                ),

                Card(
                  margin: const EdgeInsets.symmetric(vertical: 20.0),
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Has Queen'),
                                Switch(
                                  value: _hasQueen,
                                  onChanged: (val) =>
                                      setState(() => _hasQueen = val),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _hasQueen
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    const Text('Queen details',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _queenYearController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Queen Year (e.g. 2023)',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0)),
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
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<int>(
                                      initialValue: _queenRating,
                                      decoration: InputDecoration(
                                        labelText: 'Queen Rating (1-5)',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0)),
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
                const SizedBox(height: 40.0),
                orgIdRepo.when(
                  data: (orgId) {
                    orgID = orgId ?? '';

                    return SizedBox(height: 0);
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                ),

                // --- 3. Submission Button ---
                ElevatedButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    // ensure queen fields are validated and captured
                    final hasQueen = _hasQueen;
                    final queenYear = hasQueen
                        ? int.tryParse(_queenYearController.text)
                        : null;
                    final queenRating = hasQueen ? _queenRating : null;

                    entitiesRef.createEntity(
                        type: _selectedType != null
                            ? getEntityTypeName(_selectedType!)
                            : '',
                        name: _nameController.text,
                        organisationId: orgID,
                        hasQueen: hasQueen,
                        queenYear:
                            queenYear != null ? queenYear.toString() : '',
                        queenRating:
                            queenRating != null ? queenRating.toString() : '');

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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
