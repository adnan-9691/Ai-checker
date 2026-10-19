import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';

/// Provider responsible for managing authentication state, loading status,
/// error handling, and orchestrating interactions with [FirebaseAuthService].
class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({FirebaseAuthService? authService})
      : _authService = authService ?? FirebaseAuthService() {
    _currentUser = _authService.currentUser;
    _listenToAuthChanges();
  }

  /// The currently signed-in Firebase [User], or null if unauthenticated.
  User? get currentUser => _currentUser;

  /// Whether an authentication request is actively running.
  bool get isLoading => _isLoading;

  /// The last recorded error message, or null if no error occurred.
  String? get errorMessage => _errorMessage;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _currentUser != null;

  /// Subscribes to Firebase auth state changes.
  void _listenToAuthChanges() {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  /// Clears any existing error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Sets the loading state and clears previous errors.
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Handles sign in with email and password.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      _errorMessage = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Handles user registration with email and password.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = credential.user;
      _errorMessage = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Handles signing out the current user.
  Future<bool> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to sign out. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
