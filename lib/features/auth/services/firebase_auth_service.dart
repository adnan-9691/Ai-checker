import 'package:firebase_auth/firebase_auth.dart';

/// Custom exception class to encapsulate Firebase Authentication errors
/// with user-friendly error messages.
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// A service wrapper around [FirebaseAuth] providing authentication methods
/// and translating Firebase-specific error codes into human-readable messages.
class FirebaseAuthService {
  final FirebaseAuth? _firebaseAuth;

  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? _safeFirebaseAuth();


  static FirebaseAuth? _safeFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Current authenticated [User] or null if unauthenticated.
  User? get currentUser => _firebaseAuth?.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges =>
      _firebaseAuth?.authStateChanges() ?? const Stream.empty();


  /// Signs in a user using email and password.
  ///
  /// Throws [AuthException] on failure.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuth == null) {
      throw AuthException('Firebase is not initialized.');
    }
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw AuthException(
        'An unexpected error occurred. Please try again later.',
      );
    }
  }

  /// Registers a new user with email and password.
  ///
  /// Throws [AuthException] on failure.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuth == null) {
      throw AuthException('Firebase is not initialized.');
    }
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw AuthException(
        'An unexpected error occurred. Please try again later.',
      );
    }
  }

  /// Signs out the currently authenticated user.
  ///
  /// Throws [AuthException] on failure.
  Future<void> signOut() async {
    if (_firebaseAuth == null) return;
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw AuthException(
        'Failed to sign out. Please check your connection.',
      );
    }
  }


  /// Maps [FirebaseAuthException] codes to clean, human-readable error messages.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please verify and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Access is temporarily disabled. Try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
