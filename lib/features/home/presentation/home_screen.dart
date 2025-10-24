import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/features/entities/presentation/read_entity_screen.dart';
import 'package:x_bee/features/organisation/presentation/main_create_organisation_screen.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'package:x_bee/services/firebase_services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(authRepositoryProvider);
    final orgRepo = ref.watch(organisationIdProvider);

    final auth = FirebaseServices.auth;
    // final firestore = FirebaseServices.firestore;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text('Welcome to the Home Screen!'),
          ),
          SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Logged in as the boss: ${auth.currentUser?.email ?? 'No Email'}'),
                  ],
                ),
                SizedBox(height: 5),
              ],
            ),
          ),
          Text('UID: ${auth.currentUser?.uid ?? 'No UID'}'),
          SafeArea(
            child: Card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  orgRepo.when(
                    data: (organisationId) => organisationId != 'null'
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Organisation ID: ',
                              ),
                              Text(
                                organisationId.toString(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(
                                      text:
                                          'Intra in organizatia mea: ${organisationId.toString()}'));
                                },
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          MainCreateOrganisationScreen()));
                            },
                            child: Text('Create/Join Organisation')),
                    loading: () => CircularProgressIndicator(),
                    error: (error, stack) {
                      return Text('Error: $error');
                    },
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/CreateEntity');
              },
              child: Text('Create Entity')),
        ],
      ),
    );
  }
}
