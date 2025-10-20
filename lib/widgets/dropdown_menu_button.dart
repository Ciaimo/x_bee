import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DropdownMenuExample extends ConsumerStatefulWidget {
   List<String> entitiesTypes;
   DropdownMenuExample({super.key, required this.entitiesTypes});

  @override
  ConsumerState<DropdownMenuExample> createState() =>
      _DropdownMenuExampleState();
}

typedef MenuEntry = DropdownMenuEntry<String>;

class _DropdownMenuExampleState extends ConsumerState<DropdownMenuExample> {
  late final List<String> list;
  late final List<MenuEntry> menuEntries;
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    list = widget.entitiesTypes;
    menuEntries = UnmodifiableListView<MenuEntry>(
      list.map<MenuEntry>((String name) => MenuEntry(value: name, label: name)).toList(),
    );
    dropdownValue = list.first;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: dropdownValue,
      onSelected: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
        });
      },
      dropdownMenuEntries: menuEntries,
    );
  }
}
