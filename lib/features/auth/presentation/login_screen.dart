import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/presentation/register_screen.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/widgets/cred_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(authRepositoryProvider);

    final TextEditingController emailController = TextEditingController();

    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CredTextField(controller: emailController, labelText: 'Email'),
            SizedBox(height: 16),
            CredTextField(
                controller: passwordController,
                labelText: 'Password',
                isPassword: true),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await repo.loginWithEmailAndPassword(
                    emailController.text.trim(),
                    passwordController.text.trim());
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()));
              },
              child: Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
