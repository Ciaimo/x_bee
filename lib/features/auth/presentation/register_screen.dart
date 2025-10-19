import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/presentation/name_screen.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/widgets/cred_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.read(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CredTextField(controller: emailController, labelText: 'Email'),
              SizedBox(height: 8),
              CredTextField(
                controller: passwordController,
                labelText: 'Password',
                isPassword: true,
              ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          final result =
                              await authRepo.registerWithEmailAndPassword(
                                  emailController.text,
                                  passwordController.text);

                          if (result != null && result.isNotEmpty) {
                            // Registration successful
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Registration Successful')));

                            if (mounted) {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => NameScreen(uid: result)));
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())));
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                      child: Text('Register'),
                    ),
            ],
          )),
    );
  }
}
