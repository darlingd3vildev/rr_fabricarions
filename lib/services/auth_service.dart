import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rr_fabrication/models/user_role.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmailPassword(
      String name, String email, String password) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      // Update display name in Firebase Auth
      await user.updateDisplayName(name);
      await user.reload();

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'role': UserRole.CUSTOMER.name, // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<bool> doesUserExist(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.exists;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> updateAuthProfile(String name) async {
    final user = getCurrentUser();
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();
    }
  }
}