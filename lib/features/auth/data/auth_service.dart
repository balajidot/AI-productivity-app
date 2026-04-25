import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Watch auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('AuthService: Starting Google Sign-In...');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('AuthService: User cancelled Google Sign-In.');
        return null;
      }

      debugPrint('AuthService: Google User obtained.');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('AuthService: Obtaining Firebase credential from Google Auth...');
      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      debugPrint('AuthService: Signing in to Firebase with credential...');
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('AuthService: Successfully signed in to Firebase.');
      return userCredential;
    } catch (e) {
      debugPrint('AuthService: Error during Google Sign-In: $e');
      rethrow; // Re-throw to allow UI to handle and show error
    }
  }

  // Update Display Name
  Future<void> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error updating display name: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // FIX M6: Clear onboarding flag so a new user on the same device
      // sees the onboarding flow instead of being silently skipped.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_complete');
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error during Sign-Out: $e');
    }
  }
}
