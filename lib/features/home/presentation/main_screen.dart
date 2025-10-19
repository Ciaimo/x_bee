import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/home/presentation/home_screen.dart';
import 'package:x_bee/features/home/presentation/settings_screen.dart';
import 'package:x_bee/features/home/providers/home_providers.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 Real screens instead of text placeholders
    final bodies = [
      const HomeScreen(),
      const SettingsScreen(),
    ];

    final indexBottomNavbar = ref.watch(indexBottomNavBarProvider);

    return Scaffold(
      body: bodies[indexBottomNavbar],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indexBottomNavbar,
        onTap: (value) {
          ref.read(indexBottomNavBarProvider.notifier).state = value;
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
