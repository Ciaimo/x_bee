import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  // Basic Info Controllers & State
  late TextEditingController _nameController;
  EntityType? _selectedType;

  // Queen Info State
  bool _hasQueen = false;
  bool _queenMarked = false;
  late TextEditingController _queenYearController;
  int? _queenRating;

  // Frames Info Controllers (NEW)
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
    // Initialize new controllers
    _honeyFramesController = TextEditingController();
    _broodFramesController = TextEditingController();
    _pollenFramesController = TextEditingController();
    _emptyFramesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _queenYearController.dispose();
    // Dispose new controllers
    _honeyFramesController.dispose();
    _broodFramesController.dispose();
    _pollenFramesController.dispose();
    _emptyFramesController.dispose();
    super.dispose();
  }

  void _initializeFromEntity(EntitiesModel entity) {
    if (_initializedForEntity) return;
    _initializedForEntity = true;

    // 🟡 Basic Info
    _nameController.text = entity.name;
    _selectedType = EntityType.values.firstWhere(
      (e) => getEntityTypeName(e).toLowerCase() == entity.type.toLowerCase(),
      orElse: () => EntityType.beehive,
    );

    // 👑 Queen Info (nested, nullable)
    _hasQueen = entity.queen?.hasQueen ?? false;
    _queenMarked = entity.queen?.marked ?? false;

    _queenYearController.text =
        (entity.queen?.year ?? 0) > 0 ? entity.queen!.year.toString() : '';

    _queenRating =
        (entity.queen?.rating ?? 0) > 0 ? entity.queen!.rating : null;

    // 🍯 Frames Info (nested)
    _honeyFramesController.text = (entity.frames.honeyFrames > 0)
        ? entity.frames.honeyFrames.toString()
        : '';
    _broodFramesController.text = (entity.frames.broodFrames > 0)
        ? entity.frames.broodFrames.toString()
        : '';
    _pollenFramesController.text = (entity.frames.pollenFrames > 0)
        ? entity.frames.pollenFrames.toString()
        : '';
    _emptyFramesController.text = (entity.frames.emptyFrames > 0)
        ? entity.frames.emptyFrames.toString()
        : '';
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return "—";
    }
    try {
      // 1. Parse the string into a DateTime object
      final dateTime = DateTime.parse(isoString);

      // 2. Format the DateTime object using the user's locale
      // This will automatically adjust order (DD/MM/YYYY vs MM/DD/YYYY)
      // Example format: Oct 26, 2025 at 16:38
      return DateFormat.yMMMd().add_Hm().format(dateTime);
    } catch (e) {
      // Return the original unformatted string or an error message if parsing fails
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgRepo = ref.watch(organisationIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Entity' : 'Entity Details'),
        automaticallyImplyLeading: false,
        actions: [
          _editMode
              ? SizedBox(
                  height: 0.0,
                )
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
        ],
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

              // Initialize controllers and state when data is available
              _initializeFromEntity(entity);

              return _editMode
                  ? _buildEditForm(entity, orgId, entitiesRepo)
                  : _buildPreview(entity);
            },
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildPreview(EntitiesModel e) {
    final totalFrames = e.frames.honeyFrames +
        e.frames.broodFrames +
        e.frames.pollenFrames +
        e.frames.emptyFrames;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic Information Card
          _DetailCard(
            title: "Basic Information 🐝",
            children: [
              _infoRow("ID", e.name, Icons.label_outline),
              _infoRow("Type", e.type, Icons.inventory_2_outlined),
              _infoRow(
                  "Created At", _formatDateTime(e.createdAt), Icons.date_range),
              _infoRow("Last Check", "—", Icons.access_time), // placeholder
            ],
          ),
          const SizedBox(height: 16),

          // 🐝 Queen Information Card (updated for nested structure)
          if (e.queen != null && e.queen!.hasQueen)
            _DetailCard(
              title: "Queen Information 👑",
              children: [
                _infoRow("Has Queen", e.queen!.hasQueen ? "Yes" : "No",
                    Icons.check_circle_outline,
                    color: Colors.green),
                _infoRow("Queen Marked", e.queen!.marked ? "Yes" : "No",
                    Icons.bookmark_border),
                // 🟢 FIX: Custom Row for Queen Year and Color Code (REVISED)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // 1. Icon and Label (Left side)
                      Icon(Icons.calendar_today_outlined,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        "Queen Year",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),

                      const Spacer(), // Pushes the rest to the right

                      // 2. Year Text and Color Indicator (Right side - Grouped)
                      // Grouping them ensures they stay together.
                      Row(
                        mainAxisSize: MainAxisSize
                            .min, // Crucial: ensures the Row only takes the space it needs
                        children: [
                          // Year Text
                          Text(
                            e.queen!.year > 0 ? e.queen!.year.toString() : "—",
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 16),
                          ),

                          // Queen Color Indicator
                          _buildColorIndicator(e.queen!.year, e.queen!.marked),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
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
              title: "Queen Information 😔",
              color: Colors.red.shade100,
              children: [
                Center(
                  child: Text(
                    'Queenless',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow("Has Queen", "No", Icons.cancel_outlined,
                    color: Colors.red),
              ],
            ),

          const SizedBox(height: 16),

          // Frames Information Card (NEW)
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
                    color: Theme.of(context).primaryColor,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: totalFrames.toString(),
                      style: const TextStyle(
                        color: Colors.red, // 🔴 Applied Red Color
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const TextSpan(
                      text: " 🍯",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              _infoRow("Honey Frames", e.frames.honeyFrames.toString(),
                  Icons.hexagon_outlined),
              _infoRow("Brood Frames", e.frames.broodFrames.toString(),
                  Icons.bug_report_outlined),
              _infoRow("Pollen Frames", e.frames.pollenFrames.toString(),
                  Icons.flare_outlined),
              _infoRow("Empty Frames", e.frames.emptyFrames.toString(),
                  Icons.texture),
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
            onPressed: () {
              // Ensure initialization runs before entering edit mode
              _initializeFromEntity(e);
              setState(() => _editMode = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(
      EntitiesModel e, String orgId, EntitiesRepository entitiesRepo) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Basic Information Card
            _DetailCard(
              title: "Basic Information ✍️",
              children: [
                // Type Dropdown
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

                // Name Field
                const Text('Name',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), hintText: 'Entity Name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _infoRow("Created At", e.createdAt ?? "—", Icons.date_range),
                _infoRow("Last Check", "—", Icons.access_time),
              ],
            ),

            const SizedBox(height: 16),

            // Queen Information Card
            _DetailCard(
              title: "Queen Information ✍️",
              children: [
                SwitchListTile(
                  title: const Text('Has Queen'),
                  value: _hasQueen,
                  onChanged: (v) => setState(() {
                    _hasQueen = v;
                    // Reset queen-related fields if 'Has Queen' is turned off
                    if (!v) {
                      _queenMarked = false;
                      _queenYearController.clear();
                      _queenRating = null;
                    }
                  }),
                ),
                if (_hasQueen) ...[
                  SwitchListTile(
                    title: const Text('Queen Marked'),
                    value: _queenMarked,
                    onChanged: (v) => setState(() => _queenMarked = v),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _queenYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Queen Year (e.g., 2024)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v!.isNotEmpty && int.tryParse(v) == null) {
                        return 'Must be a valid year (number)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _queenRating,
                    hint: const Text('Select Queen Rating (1-5)'),
                    items: List.generate(5, (i) => i + 1)
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text('$r star${r > 1 ? 's' : ''}')))
                        .toList(),
                    onChanged: (v) => setState(() => _queenRating = v),
                    decoration: const InputDecoration(
                      labelText: 'Queen Rating',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ]
              ],
            ),

            const SizedBox(height: 16),

            // Frames Information Card (NEW)
            _DetailCard(
              title: "Frame Count ✍️",
              children: [
                _buildFrameTextField('Honey Frames', _honeyFramesController),
                _buildFrameTextField('Brood Frames', _broodFramesController),
                _buildFrameTextField('Pollen Frames', _pollenFramesController),
                _buildFrameTextField('Empty Frames', _emptyFramesController),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
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

  // --- HELPER METHODS AND WIDGETS ---

  Future<void> _saveChanges(
      String orgId, EntitiesRepository entitiesRepo) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Helper to safely parse int from controller, defaulting to 0
    int _safeParse(TextEditingController controller) {
      return int.tryParse(controller.text.trim()) ?? 0;
    }

    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': getEntityTypeName(_selectedType ?? EntityType.beehive),
      'frames': {
        'honeyFrames': _safeParse(_honeyFramesController),
        'broodFrames': _safeParse(_broodFramesController),
        'pollenFrames': _safeParse(_pollenFramesController),
        'emptyFrames': _safeParse(_emptyFramesController),
      },
      'queen': _hasQueen
          ? {
              'hasQueen': _hasQueen,
              'marked': _queenMarked,
              'year': _safeParse(_queenYearController),
              'rating': _queenRating ?? 0,
            }
          : null,
    };

    try {
      await entitiesRepo.updateEntity(
          organisationId: orgId, entityId: widget.entityId, updates: updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entity updated successfully!')));
        setState(() => _editMode = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed. Error: $e')));
      }
    }
  }

  Widget _infoRow(String title, String value, IconData icon, {Color? color}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.black54, fontSize: 14),
      ),
      isThreeLine: true,
    );
  }

  Widget _buildFrameTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (v!.isNotEmpty && int.tryParse(v) == null) {
            return 'Must be a valid number';
          }
          // Optional: Add a check for non-negative numbers
          if (v.isNotEmpty && (int.tryParse(v) ?? 0) < 0) {
            return 'Cannot be negative';
          }
          return null;
        },
      ),
    );
  }

  /// Builds a star rating display like ⭐⭐⭐⭐☆
  Widget _buildRatingStars(int? rating) {
    const maxStars = 5;
    if (rating == null || rating <= 0) {
      return const Text('—',
          style: TextStyle(color: Colors.black54, fontSize: 16));
    }
    final filledStars = '⭐' * rating;
    final emptyStars = '☆' * (maxStars - rating);
    return Text(
      '$filledStars$emptyStars',
      style: const TextStyle(fontSize: 16),
    );
  }
}

/// Returns the International Queen Bee Color based on the year.
Color _getQueenColor(int year) {
  if (year <= 0) return Colors.grey;
  final lastDigit = year % 10;

  switch (lastDigit) {
    case 1:
    case 6:
      return Colors.white; // Often represented by a grey box in UI
    case 2:
    case 7:
      return Colors.yellow;
    case 3:
    case 8:
      return Colors.red;
    case 4:
    case 9:
      return Colors.green;
    case 5:
    case 0:
      return Colors.blue;
    default:
      return Colors.grey;
  }
}

/// Returns a small colored circle widget representing the queen color code.
Widget _buildColorIndicator(int year, bool isMarked) {
  if (!isMarked || year <= 0) {
    return const SizedBox.shrink();
  }

  final color = _getQueenColor(year);
  final isWhite = color == Colors.white;

  // For White, use a small grey border to make it visible against a white background
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

// Custom Card Widget for reusability and styling
class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? color;
  final bool? divider; // This is now useful

  const _DetailCard(
      {required this.title,
      required this.children,
      this.color,
      this.divider = true // Default the divider to true for existing calls
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
            // 🟢 1. CONDITIONALLY RENDER THE DEFAULT TITLE
            if (title.isNotEmpty)
              Text(
                title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color != null
                        ? Colors.black
                        : Theme.of(context).primaryColor),
              ),

            // 🟢 2. CONDITIONALLY RENDER THE DIVIDER
            if (title.isNotEmpty && (divider ?? true))
              const Divider(height: 16),

            // 3. Render all custom children (including your RichText title)
            ...children,
          ],
        ),
      ),
    );
  }
}
