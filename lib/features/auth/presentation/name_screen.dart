import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/organisation/presentation/create_organisation_screen.dart';
import 'package:x_bee/features/organisation/presentation/main_create_organisation_screen.dart';
import 'package:x_bee/widgets/cred_text_field.dart';
import '../providers/auth_providers.dart';

class NameScreen extends ConsumerWidget {
  final String uid;
  const NameScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final repo = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Name')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CredTextField(
                controller: nameController,
                labelText: 'Pleases enter your full name!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await repo.addUserName(uid, nameController.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name saved!')),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainCreateOrganisationScreen(),
                    ),
                  );
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
