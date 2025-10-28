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

final userDataProvider = StreamProvider<UserModel?>((ref) {
  // Get the current Firebase User (using .value to read the current state)
  final firebaseUser = ref.watch(authStateProvider);

  // if (firebaseUser == null) {
  //   // If no user is logged in, return null
  //   return null;
  // }

  // // Use the AuthRepository to fetch the UserModel from Firestore
  // final authRepo = ref.read(authRepositoryProvider);
  // return authRepo.getUserData(firebaseUser.uid);

  return firebaseUser.when(
    loading: () => const Stream.empty(), // Return empty stream while loading
    error: (err, stack) => Stream.error(err), // Propagate errors
    data: (firebaseUser) {
      if (firebaseUser == null) {
        // If no user is logged in, return a stream that emits null once
        return Stream.value(null);
      }

      // 2. Use the AuthRepository to get the real-time stream for this UID
      final authRepo = ref.read(authRepositoryProvider);
      return authRepo.getUserDataStream(firebaseUser.uid);
    },
  );
});
