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
      print('Starting Facebook Sign-In...');
      
      // Quick check if Facebook Auth is available and working
      bool isFacebookConfigured = false;
      try {
        // Simple check to see if Facebook SDK is responsive
        await FacebookAuth.instance.accessToken.timeout(Duration(seconds: 3));
        isFacebookConfigured = true;
      } catch (e) {
        print('Facebook Auth not properly configured: $e');
      }
      
      if (!isFacebookConfigured) {
        throw Exception('Facebook login is currently unavailable. Please use email or Google login, or try again later.');
      }
      
      // Add timeout to prevent getting stuck
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback,
      ).timeout(
        Duration(seconds: 15), // Reduced timeout for faster feedback
        onTimeout: () {
          print('Facebook login timeout');
          throw Exception('Facebook login timed out. Please try again or contact support if this persists.');
        },
      );

      print('Facebook login result status: ${loginResult.status}');
      
      if (loginResult.status == LoginStatus.success) {
        if (loginResult.accessToken == null) {
          print('Facebook login successful but no access token');
          throw Exception('Facebook login failed: No access token received');
        }
        
        print('Creating Facebook credential...');
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

        print('Signing in to Firebase with Facebook credential...');
        UserCredential result = await _auth.signInWithCredential(facebookAuthCredential).timeout(
          Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Firebase authentication timed out. Please try again.');
          },
        );
        
        // Create user document if it doesn't exist
        if (result.user != null) {
          await _createUserDocumentIfNotExists(result.user!);
        }
        
        print('Facebook Sign-In completed successfully');
        return result;
      } else if (loginResult.status == LoginStatus.cancelled) {
        print('Facebook login was cancelled by user');
        return null;
      } else if (loginResult.status == LoginStatus.failed) {
        print('Facebook login failed with error: ${loginResult.message}');
        throw Exception('Facebook login failed: ${loginResult.message ?? 'Authentication failed'}');
      } else if (loginResult.status == LoginStatus.operationInProgress) {
        print('Facebook login operation already in progress');
        throw Exception('Facebook login is already in progress. Please wait or try again.');
      } else {
        print('Facebook login failed with status: ${loginResult.status}');
        print('Facebook login error message: ${loginResult.message}');
        throw Exception('Facebook login failed: ${loginResult.message ?? 'Unknown error'}');
      }
    } on Exception catch (e) {
      print('Facebook sign in exception: $e');
      rethrow;
    } catch (error) {
      print('Facebook sign in error: $error');
      print('Error type: ${error.runtimeType}');
      throw Exception('Facebook login failed: $error');
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