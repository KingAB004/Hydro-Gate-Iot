import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '223103795490-ftkqt4jcmij5jmjduso1ji4fokrkbej1.apps.googleusercontent.com',
  );

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Save user to Firestore if they don't exist yet
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
        final snapshot = await userDoc.get();
        
        if (!snapshot.exists) {
          await userDoc.set({
            'username': userCredential.user!.displayName ?? 'Google User',
            'email': userCredential.user!.email ?? '',
            'role': 'Homeowner', 
            'status': 'Active',
            'joined': DateTime.now().toIso8601String().split('T')[0],
          });
        }
      }

      return userCredential;
    } catch (e) {
      print("Error signing in with Google: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
