import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> signOut() async {
    try {
      await _auth.signOut();
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
        'createdAt': FieldValue.serverTimestamp(),
        'isPro': isPro,
        'routineSlots': [],
      });
    } catch (error) {
      print('Error creating user document: $error');
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