import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:x_bee/features/entities/data/entities_repository.dart';
import 'package:x_bee/features/entities/domain/entities_model.dart';
import 'package:x_bee/features/entities/providers/entities_providers.dart';
import 'package:x_bee/features/organisation/data/organisation_repository.dart';
import 'package:x_bee/features/organisation/domain/race_model.dart'; // <-- ADD THIS
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

  // Basic Info
  late TextEditingController _nameController;
  EntityType? _selectedType;

  // Queen Info
  bool _hasQueen = false;
  bool _queenMarked = false;
  late TextEditingController _queenYearController;
  String? _selectedRace; // stores race.name
  String? _selectedLine;
  int? _queenRating;

  // Frames
  late TextEditingController _honeyFramesController;
  late TextEditingController _broodFramesController;
  late TextEditingController _pollenFramesController;
  late TextEditingController _emptyFramesController;

  bool _initializedForEntity = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _queenYearController = TextEditingController();
    _honeyFramesController = TextEditingController();
    _broodFramesController = TextEditingController();
    _pollenFramesController = TextEditingController();
    _emptyFramesController = TextEditingController();
  }

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

  void _initializeFromEntity(EntitiesModel entity) {
    if (_initializedForEntity) return;
    _initializedForEntity = true;

    // Basic
    _nameController.text = entity.name;
    _selectedType = EntityType.values.firstWhere(
      (e) => getEntityTypeName(e).toLowerCase() == entity.type.toLowerCase(),
      orElse: () => EntityType.beehive,
    );

    // Queen
    final queen = entity.queen;
    _hasQueen = queen?.hasQueen ?? false;
    _queenMarked = queen?.marked ?? false;
    _queenYearController.text =
        (queen?.year ?? 0) > 0 ? queen!.year.toString() : '';
    _queenRating = (queen?.rating ?? 0) > 0 ? queen!.rating : null;
    _selectedRace = queen?.race;
    _selectedLine = queen?.line;

    // Frames
    final frames = entity.frames;
    _honeyFramesController.text =
        frames.honeyFrames > 0 ? frames.honeyFrames.toString() : '';
    _broodFramesController.text =
        frames.broodFrames > 0 ? frames.broodFrames.toString() : '';
    _pollenFramesController.text =
        frames.pollenFrames > 0 ? frames.pollenFrames.toString() : '';
    _emptyFramesController.text =
        frames.emptyFrames > 0 ? frames.emptyFrames.toString() : '';
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "—";
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat.yMMMd().add_Hm().format(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgIdAsync = ref.watch(organisationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Entity' : 'Entity Details'),
        automaticallyImplyLeading: false,
        actions: [
          _editMode
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
        ],
      ),
      body: orgIdAsync.when(
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
              organisationId: orgId, entityId: widget.entityId);
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

              _initializeFromEntity(entity);

              return _editMode
                  ? _buildEditForm(entity, orgId, entitiesRepo)
                  : _buildPreview(entity, orgId);
            },
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // PREVIEW MODE
  // ──────────────────────────────────────────────────────────────
  Widget _buildPreview(EntitiesModel e, String orgId) {
    final totalFrames = e.frames.honeyFrames +
        e.frames.broodFrames +
        e.frames.pollenFrames +
        e.frames.emptyFrames;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic Info
          _DetailCard(
            title: "Basic Information",
            children: [
              _infoRow("ID", e.name, Icons.label_outline),
              _infoRow("Type", e.type, Icons.inventory_2_outlined),
              _infoRow(
                  "Created At", _formatDateTime(e.createdAt), Icons.date_range),
              _infoRow("Last Check", "—", Icons.access_time),
            ],
          ),
          const SizedBox(height: 16),

          // Queen Info
          if (e.queen != null && e.queen!.hasQueen)
            _DetailCard(
              title: "Queen Information",
              children: [
                _infoRow("Has Queen", "Yes", Icons.check_circle_outline,
                    color: Colors.green),
                _infoRow("Queen Marked", e.queen!.marked ? "Yes" : "No",
                    Icons.bookmark_border),
                _infoRow(
                    "Queen Race",
                    e.queen!.race != null && e.queen!.race!.isNotEmpty
                        ? e.queen!.race!
                        : "—",
                    Icons.pets),
                _infoRow(
                    "Queen Line",
                    e.queen!.line != null && e.queen!.line!.isNotEmpty
                        ? e.queen!.line!
                        : "—",
                    Icons.line_weight),

                // Year + Color
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text("Queen Year",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.queen!.year > 0 ? e.queen!.year.toString() : "—",
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 16),
                          ),
                          _buildColorIndicator(e.queen!.year, e.queen!.marked),
                        ],
                      ),
                    ],
                  ),
                ),

                // Rating
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Queen Rating",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      _buildRatingStars(e.queen!.rating),
                    ],
                  ),
                ),
              ],
            )
          else
            _DetailCard(
              title: "Queen Information",
              color: Colors.red.shade100,
              children: [
                Center(
                  child: Text(
                    'Queenless',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow("Has Queen", "No", Icons.cancel_outlined,
                    color: Colors.red),
              ],
            ),

          const SizedBox(height: 16),

          // Frames
          _DetailCard(
            divider: false,
            title: '',
            children: [
              Text.rich(
                TextSpan(
                  text: "Frame Count: ",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  children: [
                    TextSpan(
                      text: totalFrames.toString(),
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w900),
                    ),
                    const TextSpan(
                        text: " ",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 16),
              _infoRow("Honey Frames", e.frames.honeyFrames.toString(),
                  Icons.cake_outlined),
              _infoRow("Brood Frames", e.frames.broodFrames.toString(),
                  Icons.child_care_outlined),
              _infoRow("Pollen Frames", e.frames.pollenFrames.toString(),
                  Icons.eco_outlined),
              _infoRow("Empty Frames", e.frames.emptyFrames.toString(),
                  Icons.texture_outlined),
            ],
          ),

          const SizedBox(height: 24),

          // Edit Button
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Edit Entity Data', style: TextStyle(fontSize: 16)),
            ),
            onPressed: () => setState(() => _editMode = true),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // EDIT MODE
  // ──────────────────────────────────────────────────────────────
  Widget _buildEditForm(
      EntitiesModel e, String orgId, EntitiesRepository entitiesRepo) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Basic Info
            _DetailCard(
              title: "Basic Information",
              children: [
                const Text('Type',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<EntityType>(
                  value: _selectedType,
                  items: EntityType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(getEntityTypeName(t))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Name',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: 'Entity Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 16),
                _infoRow("Created At", _formatDateTime(e.createdAt),
                    Icons.date_range),
                _infoRow("Last Check", "—", Icons.access_time),
              ],
            ),

            const SizedBox(height: 16),

            // Queen Info
            _DetailCard(
              title: "Queen Information",
              children: [
                SwitchListTile(
                  title: const Text('Has Queen'),
                  value: _hasQueen,
                  onChanged: (v) => setState(() {
                    _hasQueen = v;
                    if (!v) {
                      _queenMarked = false;
                      _queenYearController.clear();
                      _queenRating = null;
                      _selectedRace = null;
                      _selectedLine = null;
                    }
                  }),
                ),
                if (_hasQueen) ...[
                  SwitchListTile(
                    title: const Text('Queen Marked'),
                    value: _queenMarked,
                    onChanged: (v) => setState(() => _queenMarked = v),
                  ),

                  const SizedBox(height: 16),

                  // RACE DROPDOWN
                  Consumer(
                    builder: (context, ref, child) {
                      final orgAsync = ref.watch(organisationProvider(orgId));
                      return orgAsync.when(
                        data: (org) {
                          final races = org?.constants?.races ?? <Race>[];
                          final selectedRaceObj = races.isNotEmpty
                              ? races.firstWhere((r) => r.name == _selectedRace,
                                  orElse: () => races.first)
                              : null;

                          return DropdownButtonFormField<Race>(
                            value: selectedRaceObj,
                            hint: const Text('Select Queen Race'),
                            items: races
                                .map((race) => DropdownMenuItem(
                                    value: race, child: Text(race.name)))
                                .toList(),
                            onChanged: (Race? newRace) {
                              setState(() {
                                _selectedRace = newRace?.name;
                                _selectedLine = null;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Queen Race',
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Failed to load races'),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // LINE DROPDOWN
                  Consumer(
                    builder: (context, ref, child) {
                      final orgAsync = ref.watch(organisationProvider(orgId));
                      return orgAsync.when(
                        data: (org) {
                          final races = org?.constants?.races ?? <Race>[];
                          final selectedRaceObj = races.firstWhere(
                            (r) => r.name == _selectedRace,
                            orElse: () => Race(id: '', name: '', lines: []),
                          );

                          return DropdownButtonFormField<String>(
                            value: _selectedLine,
                            hint: const Text('Select Line (optional)'),
                            items: selectedRaceObj.lines
                                .map((line) => DropdownMenuItem(
                                    value: line, child: Text(line)))
                                .toList(),
                            onChanged: (line) =>
                                setState(() => _selectedLine = line),
                            decoration: const InputDecoration(
                              labelText: 'Queen Line',
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Failed to load lines'),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Year
                  TextFormField(
                    controller: _queenYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Queen Year (e.g., 2024)',
                        border: OutlineInputBorder()),
                    validator: (v) => v!.isNotEmpty && int.tryParse(v) == null
                        ? 'Invalid year'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Rating
                  DropdownButtonFormField<int>(
                    value: _queenRating,
                    hint: const Text('Select Rating (1-5)'),
                    items: List.generate(5, (i) => i + 1)
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text('$r star${r > 1 ? 's' : ''}')))
                        .toList(),
                    onChanged: (v) => setState(() => _queenRating = v),
                    decoration: const InputDecoration(
                        labelText: 'Queen Rating',
                        border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Frames
            _DetailCard(
              title: "Frame Count",
              children: [
                _buildFrameTextField('Honey Frames', _honeyFramesController),
                _buildFrameTextField('Brood Frames', _broodFramesController),
                _buildFrameTextField('Pollen Frames', _pollenFramesController),
                _buildFrameTextField('Empty Frames', _emptyFramesController),
              ],
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveChanges(orgId, entitiesRepo),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor),
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Save Changes',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _editMode = false),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // SAVE CHANGES
  // ──────────────────────────────────────────────────────────────
  Future<void> _saveChanges(
      String orgId, EntitiesRepository entitiesRepo) async {
    if (!_formKey.currentState!.validate()) return;

    int _parse(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': getEntityTypeName(_selectedType ?? EntityType.beehive),
      'frames': {
        'honeyFrames': _parse(_honeyFramesController),
        'broodFrames': _parse(_broodFramesController),
        'pollenFrames': _parse(_pollenFramesController),
        'emptyFrames': _parse(_emptyFramesController),
      },
      'queen': _hasQueen
          ? {
              'hasQueen': _hasQueen,
              'marked': _queenMarked,
              'year': _parse(_queenYearController),
              'rating': _queenRating ?? 0,
              'race': _selectedRace ?? '',
              'line': _selectedLine ?? '',
            }
          : null,
    };

    try {
      await entitiesRepo.updateEntity(
        organisationId: orgId,
        entityId: widget.entityId,
        updates: updates,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entity updated successfully!')),
        );
        _initializedForEntity = false;
        setState(() => _editMode = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ──────────────────────────────────────────────────────────────
  Widget _infoRow(String title, String value, IconData icon, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(value,
          style: const TextStyle(color: Colors.black54, fontSize: 14)),
    );
  }

  Widget _buildFrameTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (v) {
          if (v!.isNotEmpty && int.tryParse(v) == null) return 'Invalid number';
          if (v.isNotEmpty && (int.tryParse(v) ?? 0) < 0)
            return 'Cannot be negative';
          return null;
        },
      ),
    );
  }

  Widget _buildRatingStars(int? rating) {
    const max = 5;
    if (rating == null || rating <= 0)
      return const Text('—',
          style: TextStyle(color: Colors.black54, fontSize: 16));
    return Text('⭐' * rating + '☆' * (max - rating),
        style: const TextStyle(fontSize: 16));
  }

  Color _getQueenColor(int year) {
    if (year <= 0) return Colors.grey;
    final d = year % 10;
    return switch (d) {
      1 || 6 => Colors.white,
      2 || 7 => Colors.yellow,
      3 || 8 => Colors.red,
      4 || 9 => Colors.green,
      _ => Colors.blue,
    };
  }

  Widget _buildColorIndicator(int year, bool marked) {
    if (!marked || year <= 0) return const SizedBox.shrink();
    final color = _getQueenColor(year);
    final isWhite = color == Colors.white;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isWhite ? Border.all(color: Colors.grey, width: 1) : null,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// REUSABLE CARD
// ──────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? color;
  final bool divider;

  const _DetailCard({
    required this.title,
    required this.children,
    this.color,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: color != null
            ? BorderSide(color: color!, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color != null
                      ? Colors.black
                      : Theme.of(context).primaryColor,
                ),
              ),
            if (title.isNotEmpty && divider) const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
