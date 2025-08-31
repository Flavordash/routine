import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (error) {
      print('Sign in error: $error');
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      if (result.user != null) {
        await _createUserDocument(result.user!);
      }
      
      return result;
    } catch (error) {
      print('Registration error: $error');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google Sign-In was cancelled by user');
        return null; // User cancelled the sign-in
      }

      print('Google Sign-In successful, getting authentication...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase with Google credential...');
      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Create user document if it doesn't exist
      if (result.user != null) {
        await _createUserDocumentIfNotExists(result.user!);
      }
      
      print('Google Sign-In completed successfully');
      return result;
    } catch (error) {
      print('Google sign in error: $error');
      print('Error type: ${error.runtimeType}');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

        UserCredential result = await _auth.signInWithCredential(facebookAuthCredential);
        
        // Create user document if it doesn't exist
        if (result.user != null) {
          await _createUserDocumentIfNotExists(result.user!);
        }
        
        return result;
      } else {
        print('Facebook login failed: ${loginResult.status}');
        return null;
      }
    } catch (error) {
      print('Facebook sign in error: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (error) {
      print('Sign out error: $error');
      rethrow;
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      // Check if this is the special PRO account
      bool isPro = user.email == 'back7930@gmail.com';
      
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'isPro': isPro,
        'routineSlots': [],
      });
    } catch (error) {
      print('Error creating user document: $error');
    }
  }

  Future<void> _createUserDocumentIfNotExists(User user) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        await _createUserDocument(user);
      } else {
        // Update user info if changed (for social login profile updates)
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        Map<String, dynamic> updates = {};
        
        if (data?['displayName'] != user.displayName) {
          updates['displayName'] = user.displayName;
        }
        if (data?['photoURL'] != user.photoURL) {
          updates['photoURL'] = user.photoURL;
        }
        
        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
        }
      }
    } catch (error) {
      print('Error checking/creating user document: $error');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        
        if (doc.exists) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          
          // Auto-upgrade back7930@gmail.com to PRO if not already
          if (data != null && 
              currentUser!.email == 'back7930@gmail.com' && 
              (data['isPro'] != true)) {
            await updateUserProStatus(true);
            data['isPro'] = true;
          }
          
          return data;
        }
      }
      return null;
    } catch (error) {
      print('Error getting user data: $error');
      return null;
    }
  }

  Future<void> updateUserProStatus(bool isPro) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isPro': isPro,
        });
      }
    } catch (error) {
      print('Error updating pro status: $error');
    }
  }

  Future<void> saveUserRoutineSlots(List<Map<String, dynamic>> routineSlots) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'routineSlots': routineSlots,
        });
      }
    } catch (error) {
      print('Error saving routine slots: $error');
    }
  }
}