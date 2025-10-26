import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/features/organisation/presentation/main_create_organisation_screen.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'package:x_bee/services/firebase_services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Function to show a simple confirmation toast/snackbar
  void _showCopyConfirmation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Organization ID copied to clipboard!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for the organisation ID state
    final orgRepo = ref.watch(organisationIdProvider);
    //final auth = FirebaseServices.auth;
    final userDataAsync = ref.watch(userDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('xBEE 🐝'),
        // You might want to add a logout button here later
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Welcome/Info Section (Styled) ---
                  const Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 10),

                  // 🆕 Consume the FutureProvider here to show the personalized name
                  userDataAsync.when(
                    loading: () => const Text(
                      'Loading Profile...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.black54),
                    ),
                    error: (error, stack) => Text(
                      'Error loading name: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, color: Colors.red),
                    ),
                    data: (userModel) {
                      final userName = userModel?.name ?? 'Apiarist';
                      return Text(
                        'Welcome, $userName!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // --- Organisation ID / Create/Join Block ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: orgRepo.when(
                        // --- DATA STATE: Organisation Exists ---
                        data: (organisationId) => organisationId != 'null'
                            ? Column(
                                children: [
                                  const Text(
                                    'Currently managing organization:',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Organisation ID Display
                                      Expanded(
                                        child: SelectableText(
                                          organisationId.toString(),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.amber[800],
                                              ),
                                        ),
                                      ),
                                      // Copy Button
                                      IconButton(
                                        icon: const Icon(Icons.copy,
                                            color: Colors.grey),
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(
                                              text: organisationId.toString()));
                                          _showCopyConfirmation(context);
                                        },
                                        tooltip: 'Copy Organization ID',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Share this ID for others to join your apiary.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              )
                            // --- DATA STATE: No Organisation ---
                            : Column(
                                children: [
                                  const Text(
                                    'No Organization Found',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 15),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MainCreateOrganisationScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.group_add),
                                    label:
                                        const Text('CREATE or JOIN an Apiary'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 15),
                                    ),
                                  ),
                                ],
                              ),
                        // --- LOADING STATE ---
                        loading: () => const Center(
                            child:
                                CircularProgressIndicator(color: Colors.amber)),
                        // --- ERROR STATE ---
                        error: (error, stack) {
                          return Text('Error fetching organization: $error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // --- Navigation Button ---
                  ElevatedButton.icon(
                    onPressed: () {
                      //TODO:
                      // Assuming this navigates to the list of entities (hives/apiaries)
                      //Navigator.pushNamed(context, '/EntityList');
                    },
                    icon: const Icon(Icons.view_list),
                    label: const Text('View Hives & Entities',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Bee-friendly color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),

                  // The original 'Create Entity' button is still available but moved:
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/CreateEntity');
                    },
                    icon: const Icon(Icons.add_box, color: Colors.blueGrey),
                    label: const Text('Quick Add New Entity',
                        style: TextStyle(color: Colors.blueGrey)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
