import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/organisation/providers/organisation_providers.dart';
import 'package:x_bee/main.dart';
import 'package:x_bee/services/firebase_services.dart';
import 'package:x_bee/widgets/cred_text_field.dart';

class JoinOrganisationScreen extends ConsumerStatefulWidget {
  const JoinOrganisationScreen({super.key});

  @override
  ConsumerState<JoinOrganisationScreen> createState() =>
      _JoinOrganisationScreenState();
}

class _JoinOrganisationScreenState
    extends ConsumerState<JoinOrganisationScreen> {
  @override
  Widget build(BuildContext context) {
    final TextEditingController joinOriganisationController =
        TextEditingController();

    final orgRepo = ref.watch(organisationRepositoryProvider);
    //final authRepo = ref.watch(authRepositoryProvider);
    final auth = FirebaseServices.auth;
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Organisation'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          CredTextField(
              controller: joinOriganisationController,
              labelText: 'Organisation ID'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle organisation creation logic here
              final organisationId = joinOriganisationController.text;
              // You can call your repository method to create the organisation
              try {
                orgRepo.addMemberToOrganisation(
                    orgId: organisationId,
                    uid: auth.currentUser!.uid,
                    email: auth.currentUser!.email.toString());

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Organisation Joined Successfully')),
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
            child: Text('Join Organisation'),
          ),
        ],
      ),
    );
  }
}
