import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource {
  final FirebaseAuth _auth;

  FirebaseAuthDataSource(this._auth);

  // -------------------------
  // SIGN IN
  // -------------------------
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User is null after sign in',
        );
      }

      return user;
    } on FirebaseAuthException {
      // ✅ VERY IMPORTANT for Web:
      // Do NOT wrap, just rethrow
      rethrow;
    }
  }

  // -------------------------
  // SIGN UP
  // -------------------------
  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User is null after sign up',
        );
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // -------------------------
  // SIGN OUT
  // -------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // -------------------------
  // EMAIL VERIFICATION
  // -------------------------
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user logged in',
      );
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // -------------------------
  // PASSWORD RESET
  // -------------------------
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // -------------------------
  // USER STATE
  // -------------------------
  User? getCurrentUser() => _auth.currentUser;

  bool isLoggedIn() => _auth.currentUser != null;

  Future<void> reload() async {
    await _auth.currentUser?.reload();
  }

  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user logged in',
      );
    }
    await user.delete();
  }
}
