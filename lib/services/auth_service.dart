import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';

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
      Logger.instance.error('Sign in error: $error');
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
      Logger.instance.error('Registration error: $error');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      Logger.instance.info('Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        Logger.instance.info('Google Sign-In was cancelled by user');
        return null; // User cancelled the sign-in
      }

      Logger.instance.info('Google Sign-In successful, getting authentication...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      Logger.instance.info('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      Logger.instance.info('Signing in to Firebase with Google credential...');
      UserCredential result = await _auth.signInWithCredential(credential);

      // Create user document if it doesn't exist
      if (result.user != null) {
        await _createUserDocumentIfNotExists(result.user!);
      }

      Logger.instance.info('Google Sign-In completed successfully');
      return result;
    } catch (error) {
      Logger.instance.error('Google sign in error: $error');
      Logger.instance.error('Error type: ${error.runtimeType}');
      rethrow;
    }
  }


  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (error) {
      Logger.instance.error('Sign out error: $error');
      rethrow;
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      // Initialize with default free user status
      // Pro status should be managed through proper subscription system
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'isPro': false, // Default to free user
        'routineSlots': [],
      });
    } catch (error) {
      Logger.instance.error('Error creating user document: $error');
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
      Logger.instance.error('Error checking/creating user document: $error');
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

          // Temporary PRO member email check for testing
          // TODO: Replace with proper subscription validation before production
          final proEmails = {
            'kwanapps2025@gmail.com',
            'back7930@gmail.com', // Your current test account
          };

          if (data != null && proEmails.contains(currentUser!.email)) {
            data['isPro'] = true;
            // Update Firestore to persist PRO status
            await _firestore.collection('users').doc(currentUser!.uid).update({
              'isPro': true,
            });
          }

          return data;
        }
      }
      return null;
    } catch (error) {
      Logger.instance.error('Error getting user data: $error');
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
      Logger.instance.error('Error updating pro status: $error');
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
      Logger.instance.error('Error saving routine slots: $error');
    }
  }
}