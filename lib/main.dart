import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/presentation/login_screen.dart';
import 'package:x_bee/features/auth/providers/auth_providers.dart';
import 'package:x_bee/features/entities/presentation/create_entity_screen.dart';
import 'package:x_bee/features/home/presentation/main_screen.dart';
import 'package:x_bee/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'xBee',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/settings': (context) => const MainScreen(),
        '/CreateEntity': (context) => const CreateEntityScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return MainScreen();
        } else {
          return LoginScreen();
        }
      },
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
