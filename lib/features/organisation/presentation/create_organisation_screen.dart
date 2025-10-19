import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'package:x_bee/main.dart';
import 'package:x_bee/services/firebase_services.dart';
import 'package:x_bee/widgets/cred_text_field.dart';

class CreateOrganisationScreen extends ConsumerStatefulWidget {
  const CreateOrganisationScreen({super.key});

  @override
  ConsumerState<CreateOrganisationScreen> createState() =>
      _CreateOrganisationScreenState();
}

class _CreateOrganisationScreenState
    extends ConsumerState<CreateOrganisationScreen> {
  @override
  Widget build(BuildContext context) {
    final TextEditingController organisationNameController =
        TextEditingController();

    final orgRepo = ref.watch(organisationRepositoryProvider);
    //final authRepo = ref.watch(authRepositoryProvider);
    final auth = FirebaseServices.auth;
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Organisation'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text('Organisation Creation Form Goes Here'),
          ),
          SizedBox(height: 20),
          CredTextField(
              controller: organisationNameController,
              labelText: 'Organisation Name'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle organisation creation logic here
              final organisationName = organisationNameController.text;
              // You can call your repository method to create the organisation
              try {
                orgRepo.createOrganisation(
                    organisationName, auth.currentUser!.uid);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Organisation Created Successfully')),
                );

                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AuthWrapper()));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: Text('Create Organisation'),
          ),
        ],
      ),
    );
  }
}
