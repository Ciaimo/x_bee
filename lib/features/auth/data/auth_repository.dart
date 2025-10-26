import 'package:firebase_auth/firebase_auth.dart';
import 'package:x_bee/features/auth/domain/user_model.dart';
import 'package:x_bee/services/firebase_services.dart';

class AuthRepository {
  final _auth = FirebaseServices.auth;
  final _firestore = FirebaseServices.firestore;

  //Stream of current user (auth changes)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  final currentUser = FirebaseServices.auth.currentUser;

  //Register with email and password
  Future<String?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          createdAt: DateTime.now());

      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw Exception('Registration Error: ${e.message}');
    }
  }

  //Login with email and password
  Future<String?> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw Exception('Login Error: ${e.message}');
    }
  }

  Future<void> addUserName(String uid, String name) async {
    try {
      await _firestore.collection('users').doc(uid).update({'name': name});
    } catch (e) {
      throw Exception('Update Name Error: ${e.toString()}');
    }
  }

  Future<void> addOrganisationId(String uid, String organisationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'organisationId': organisationId});
    } catch (e) {
      throw Exception('Update Organisation ID Error: ${e.toString()}');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        // Convert the raw map data into a type-safe UserModel
        return UserModel.fromMap(docSnapshot.data()!);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: ${e.toString()}');
    }
  }

  //Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
