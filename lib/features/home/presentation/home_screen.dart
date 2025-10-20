import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/features/entities/presentation/read_entity_screen.dart';
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
          Text(
              'Logged in as the boss: ${auth.currentUser?.email ?? 'No Email'}'),
          Text('UID: ${auth.currentUser?.uid ?? 'No UID'}'),
          orgRepo.when(
            data: (organisationId) => Text(
                'Organisation ID: ${organisationId ?? 'No Organisation ID'}'),
            loading: () => CircularProgressIndicator(),
            error: (error, stack) {
              return Text('Error: $error');
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/CreateEntity');
              },
              child: Text('Create Entity')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ReadEntityScreen(entityId: 'beehy')));
              },
              child: Text('Read Entity')),
        ],
      ),
    );
  }
}
