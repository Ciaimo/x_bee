import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/entities/data/entities_repository.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
import 'package:x_bee/features/entities/providers/entities_providers.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'create_entity_screen.dart'; // for EntityType + getEntityTypeName

class ReadEntityScreen extends ConsumerStatefulWidget {
  final String entityId;
  const ReadEntityScreen({super.key, required this.entityId});

  @override
  ConsumerState<ReadEntityScreen> createState() => _ReadEntityScreenState();
}

class _ReadEntityScreenState extends ConsumerState<ReadEntityScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editMode = false;

  late TextEditingController _nameController = TextEditingController();
  EntityType? _selectedType;
  bool _hasQueen = false;
  late TextEditingController _queenYearController;
  int? _queenRating;

  bool _initializedForEntity = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _queenYearController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _queenYearController.dispose();
    super.dispose();
  }

  void _initializeFromEntity(EntitiesModel entity) {
    if (_initializedForEntity) return;
    _initializedForEntity = true;
    _nameController.text = entity.name;
    _selectedType = EntityType.values.firstWhere(
      (e) => getEntityTypeName(e).toLowerCase() == entity.type.toLowerCase(),
      orElse: () => EntityType.beehive,
    );
    _hasQueen = entity.hasQueen;
    _queenYearController.text =
        entity.queenYear > 0 ? entity.queenYear.toString() : '';
    _queenRating = entity.queenRating > 0 ? entity.queenRating : null;
  }

  @override
  Widget build(BuildContext context) {
    final orgRepo = ref.watch(organisationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entity Details'),
      ),
      body: orgRepo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Failed to load organisation: $err')),
        data: (orgId) {
          if (orgId == null || orgId.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No organisation available for this user.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/CreateOrganisation'),
                    child: const Text('Create / Join Organisation'),
                  ),
                ],
              ),
            );
          }

          final params = SingleEntityParams(
            organisationId: orgId,
            entityId: widget.entityId,
          );

          final entityAsync = ref.watch(singleEntityProvider(params));
          final entitiesRepo = ref.watch(entitiesProvider);

          return entityAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Error loading entity: $err')),
            data: (entity) {
              if (entity == null) {
                return const Center(child: Text('Entity not found.'));
              }

              // show preview when not editing, form when editing
              Widget buildPreview(EntitiesModel e) {
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Card(
                        child: ListTile(
                            title: const Text('Name'),
                            subtitle: Text(e.name.isNotEmpty ? e.name : '—'))),
                    const SizedBox(height: 8),
                    Card(
                        child: ListTile(
                            title: const Text('Type'),
                            subtitle: Text(e.type.isNotEmpty ? e.type : '—'))),
                    const SizedBox(height: 8),
                    Card(
                        child: ListTile(
                            title: const Text('Has Queen'),
                            subtitle: Text(e.hasQueen ? 'Yes' : 'No'))),
                    if (e.hasQueen) ...[
                      const SizedBox(height: 8),
                      Card(
                          child: ListTile(
                              title: const Text('Queen Year'),
                              subtitle: Text(e.queenYear > 0
                                  ? e.queenYear.toString()
                                  : '—'))),
                      const SizedBox(height: 8),
                      Card(
                          child: ListTile(
                              title: const Text('Queen Rating'),
                              subtitle: Text(e.queenRating > 0
                                  ? e.queenRating.toString()
                                  : '—'))),
                    ],
                    const SizedBox(height: 8),
                    Card(
                        child: ListTile(
                            title: const Text('Created At'),
                            subtitle: Text(e.createdAt ?? '—'))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // initialize controllers with current values then enter edit mode
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _initializeFromEntity(e);
                          setState(() => _editMode = true);
                        });
                      },
                      child: const Padding(
                          padding: EdgeInsets.all(12.0), child: Text('Edit')),
                    ),
                  ],
                );
              }

              Widget buildEditForm(EntitiesModel e, String orgId,
                  EntitiesRepository entitiesRepo) {
                // controllers already initialized in _initializeFromEntity when edit begins
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Type
                        const Text('Type',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<EntityType>(
                          initialValue: _selectedType,
                          items: EntityType.values
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(getEntityTypeName(t))))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedType = v),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),

                        // Name
                        const Text('Name',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                            controller: _nameController,
                            enabled: true,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name required';
                              }
                              return null;
                            }),
                        const SizedBox(height: 16),

                        // Queen
                        SwitchListTile(
                            title: const Text('Has Queen'),
                            value: _hasQueen,
                            onChanged: (v) => setState(() => _hasQueen = v)),
                        if (_hasQueen) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                              controller: _queenYearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Queen Year',
                                  border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                              initialValue: _queenRating,
                              items: List.generate(5, (i) => i + 1)
                                  .map((r) => DropdownMenuItem(
                                      value: r, child: Text(r.toString())))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _queenRating = v),
                              decoration: const InputDecoration(
                                  labelText: 'Queen Rating',
                                  border: OutlineInputBorder())),
                        ],

                        const SizedBox(height: 24),
                        Card(
                            child: ListTile(
                                title: const Text('Created At'),
                                subtitle: Text(e.createdAt ?? '—'))),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final updates = <String, dynamic>{
                                    'name': _nameController.text.trim(),
                                    'type': getEntityTypeName(
                                        _selectedType ?? EntityType.beehive),
                                    'hasQueen': _hasQueen,
                                    'queenYear': _hasQueen
                                        ? int.tryParse(
                                            _queenYearController.text)
                                        : null,
                                    'queenRating':
                                        _hasQueen ? _queenRating : null,
                                  };
                                  try {
                                    await entitiesRepo.updateEntity(
                                        organisationId: orgId,
                                        entityId: widget.entityId,
                                        updates: updates);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Saved')));
                                    setState(() => _editMode = false);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('Save failed: $e')));
                                  }
                                },
                                child: const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('Save Changes')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _editMode = false),
                              child: const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('Cancel')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              // end data branch - return preview or edit form
              return _editMode
                  ? buildEditForm(entity, orgId, entitiesRepo)
                  : buildPreview(entity);
            },
          );
        },
      ),
    );
  }
}
