import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:x_bee/features/auth/data/auth_repository.dart';
import 'package:x_bee/features/auth/domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userDataProvider = FutureProvider<UserModel?>((ref) async {
  // Get the current Firebase User (using .value to read the current state)
  final firebaseUser = ref.watch(authStateProvider).value;

  if (firebaseUser == null) {
    // If no user is logged in, return null
    return null;
  }

  // Use the AuthRepository to fetch the UserModel from Firestore
  final authRepo = ref.read(authRepositoryProvider);
  return authRepo.getUserData(firebaseUser.uid);
});
