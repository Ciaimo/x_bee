import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:x_bee/features/entities/presentation/scan_entity_screen.dart';
import 'package:x_bee/features/home/presentation/home_screen.dart';
import 'package:x_bee/features/home/presentation/settings_screen.dart';
import 'package:x_bee/features/home/providers/home_providers.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  Future<void> _onCameraPressed(BuildContext context) async {
    // Request camera permission first
    final status = await Permission.camera.request();

    if (!context.mounted) return;

    if (status.isGranted) {
     // Permission granted, navigate to scanner
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanEntityScreen()),
      );
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show dialog to open settings
      _showPermissionDialog(context);
    } else {
      // Permission denied (but not permanently)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan QR codes'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPermissionDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access has been permanently denied. Please enable it in your device settings to scan QR codes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(c).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

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
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: IconButton(
                  icon: const Icon(
                    Icons.home,
                    size: 30,
                  ),
                  color: indexBottomNavbar == 0
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  onPressed: () {
                    ref.read(indexBottomNavBarProvider.notifier).state = 0;
                  },
                ),
              ),
              const SizedBox(width: 60), // Space for the FAB
              Expanded(
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    size: 30,
                  ),
                  color: indexBottomNavbar == 1
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  onPressed: () {
                    ref.read(indexBottomNavBarProvider.notifier).state = 1;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onCameraPressed(context),
        elevation: 2.0,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
