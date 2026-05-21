import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/api_keys.dart';

enum AuthStatus { idle, loading, emailConfirmationRequired, authenticated }

class AuthProvider extends ChangeNotifier {
  bool       _isLoading = false;
  String?    _error;
  User?      _user;
  AuthStatus _status    = AuthStatus.idle;
  String     _pendingEmail = '';

  bool       get isLoading                => _isLoading;
  String?    get error                    => _error;
  User?      get user                     => _user;
  bool       get isLoggedIn               => _user != null;
  AuthStatus get status                   => _status;
  String     get pendingEmail             => _pendingEmail;
  bool       get needsEmailConfirmation   => _status == AuthStatus.emailConfirmationRequired;
  String     get displayName              => _user?.userMetadata?['full_name']
                                              ?? _user?.email?.split('@').first ?? 'User';
  String     get email                    => _user?.email ?? '';
  String     get avatarUrl                => _user?.userMetadata?['avatar_url'] ?? '';

  AuthProvider() {
    _user = SupabaseService.currentUser;
    SupabaseService.authStream.listen((event) {
      _user = event.session?.user;
      if (_user != null) _status = AuthStatus.authenticated;
      notifyListeners();
    });
  }

  // ── Email / Password sign-in ────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await SupabaseService.signInWithEmail(email, password);
      _user = res.user;

      if (_user == null) {
        _error = 'Login failed — please check your credentials.';
        _setLoading(false);
        return false;
      }

      _status = AuthStatus.authenticated;
      _error  = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      // Give clear user-friendly messages
      _error = _friendlyAuthError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // ── Email / Password sign-up ────────────────────────────────────────────
  Future<SignUpResult> signUp(String name, String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await SupabaseService.signUpWithEmail(email, password, name);

      // Case 1: Immediate session (email confirmations disabled in Supabase)
      if (res.session != null && res.user != null) {
        _user   = res.user;
        _status = AuthStatus.authenticated;
        _error  = null;
        _setLoading(false);
        return SignUpResult.success;
      }

      // Case 2: User created but email confirmation required
      if (res.user != null) {
        _pendingEmail = email;
        _status       = AuthStatus.emailConfirmationRequired;
        _error        = null;
        _setLoading(false);
        return SignUpResult.confirmEmail;
      }

      _error = 'Account creation failed. Please try again.';
      _setLoading(false);
      return SignUpResult.failed;
    } on AuthException catch (e) {
      _error = _friendlyAuthError(e.message);
      _setLoading(false);
      return SignUpResult.failed;
    } catch (e) {
      _error = 'Sign up failed: ${e.toString()}';
      _setLoading(false);
      return SignUpResult.failed;
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    try {
      final googleSignIn = GoogleSignIn(
        // Use the Web Client ID — Android client auto-matches by SHA-1
        serverClientId: ApiKeys.googleWebClientId,
        scopes: ['email', 'profile'],
      );

      // Sign out first to always show account picker
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        _setLoading(false);
        return false;
      }

      final googleAuth  = await googleUser.authentication;
      final idToken     = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      debugPrint('[Auth] Google idToken: ${idToken != null ? "✓ received" : "✗ null"}');
      debugPrint('[Auth] Google accessToken: ${accessToken != null ? "✓ received" : "✗ null"}');

      if (idToken == null) {
        _error = 'Google sign-in failed: could not get ID token.\n'
            'Make sure your Android SHA-1 is registered in Google Cloud Console.';
        _setLoading(false);
        return false;
      }

      final res = await SupabaseService.signInWithGoogle(idToken, accessToken ?? '');
      _user   = res.user;
      _status = AuthStatus.authenticated;
      _error  = null;
      _setLoading(false);
      return _user != null;
    } on AuthException catch (e) {
      _error = 'Supabase auth error: ${e.message}';
      _setLoading(false);
      return false;
    } catch (e) {
      // Show the real error for debugging
      _error = 'Google sign-in error: ${e.toString()}';
      debugPrint('[Auth] Google sign-in exception: $e');
      _setLoading(false);
      return false;
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await SupabaseService.signOut();
    _user   = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // ── Password Reset ──────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      _error = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Reset failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetConfirmationState() {
    _status = AuthStatus.idle;
    _pendingEmail = '';
    notifyListeners();
  }

  String _friendlyAuthError(String supabaseMsg) {
    final msg = supabaseMsg.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Wrong email or password. Please try again.';
    }
    if (msg.contains('user already registered') || msg.contains('already registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before signing in. Check your inbox.';
    }
    if (msg.contains('password should be')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return supabaseMsg;
  }
}

enum SignUpResult { success, confirmEmail, failed }
