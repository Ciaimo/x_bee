import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/organisation/presentation/create_organisation_screen.dart';
import 'package:x_bee/features/organisation/presentation/join_organisation_screen.dart';

class MainCreateOrganisationScreen extends ConsumerStatefulWidget {
  const MainCreateOrganisationScreen({super.key});

  @override
  ConsumerState<MainCreateOrganisationScreen> createState() =>
      _MainCreateOrganisationScreenState();
}

class _MainCreateOrganisationScreenState
    extends ConsumerState<MainCreateOrganisationScreen> {
  final bodies = [CreateOrganisationScreen(), JoinOrganisationScreen()];
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: bodies[index],
      // ... inside your build method

      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add), // Use a standard icon or simple Text widget
            label: 'Create', // The required label
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.group_add), // Use a standard icon or simple Text widget
            label: 'Join', // The required label
          ),
        ],
        currentIndex: index, // Highlight the currently selected item
        onTap: (newIndex) {
          // Handle the tap on the BottomNavigationBar
          setState(() {
            index = newIndex; // Update the index
          });
        },
      ),
    );
  }
}
