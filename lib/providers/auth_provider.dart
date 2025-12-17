import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser; 

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _currentUser = credential.user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _currentUser = credential.user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}