import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return UserModel.fromFirebase(credential.user!);
  }

  Future<UserModel> register(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name);
    // Reload to get updated display name
    await credential.user!.reload();
    final updatedUser = _auth.currentUser!;
    return UserModel.fromFirebase(updatedUser);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
