import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = false;
  bool _isAdmin = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _isAdmin;
  
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      print('Auth state changed: ${user?.email}');
      _user = user;
      if (user != null) {
        await _checkAdminStatus(user.uid);
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }
  
  Future<void> _checkAdminStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      print('User document exists: ${doc.exists}');
      if (doc.exists) {
        final role = doc['role'];
        print('User role: $role');
        _isAdmin = role == 'admin';
      } else {
        print('User document not found!');
        _isAdmin = false;
      }
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
    }
    print('Is admin: $_isAdmin');
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = result.user;
      await _checkAdminStatus(result.user!.uid);
      _isLoading = false;
      notifyListeners();
      print('Login successful, isAdmin: $_isAdmin');
      return true;
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String name, String email, String password, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email.trim(),
        'role': isAdmin ? 'admin' : 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _user = result.user;
      _isAdmin = isAdmin;
      _isLoading = false;
      notifyListeners();
      print('Registration successful, isAdmin: $_isAdmin');
      return true;
    } catch (e) {
      print('Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _isAdmin = false;
    notifyListeners();
  }
  
  // Request password reset (for customers - sends request to admin)
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if user exists
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();
      
      if (userQuery.docs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final isAdmin = userDoc['role'] == 'admin';
      
      if (isAdmin) {
        // Admin can reset directly via email
        await _auth.sendPasswordResetEmail(email: email.trim());
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Customer needs admin approval
        // Check if there's already a pending request
        final existingRequest = await _firestore
            .collection('password_resets')
            .where('email', isEqualTo: email.trim())
            .where('status', isEqualTo: 'pending')
            .get();
        
        if (existingRequest.docs.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          return false; // Request already exists
        }
        
        // Generate a random reset code
        final resetCode = _generateResetCode();
        
        // Save reset request to Firestore
        await _firestore.collection('password_resets').add({
          'userId': userId,
          'email': email.trim(),
          'resetCode': resetCode,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        });
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Password reset request error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Check if reset request is approved and reset password
  Future<bool> resetPasswordWithCode(String email, String resetCode, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Find the approved reset request
      final resetQuery = await _firestore
          .collection('password_resets')
          .where('email', isEqualTo: email.trim())
          .where('resetCode', isEqualTo: resetCode)
          .where('status', isEqualTo: 'approved')
          .get();
      
      if (resetQuery.docs.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final resetDoc = resetQuery.docs.first;
      
      // Send password reset email (Firebase handles the actual password change)
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      // Update the reset request status
      await resetDoc.reference.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Password reset error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // For admin to check pending reset requests
  Stream<QuerySnapshot> getPendingResetRequests() {
    return _firestore
        .collection('password_resets')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }
  
  // For admin to approve a reset request
  Future<bool> approveResetRequest(String requestId) async {
    try {
      await _firestore.collection('password_resets').doc(requestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _user?.uid,
      });
      return true;
    } catch (e) {
      print('Error approving reset request: $e');
      return false;
    }
  }
  
  // For admin to reject a reset request
  Future<bool> rejectResetRequest(String requestId) async {
    try {
      await _firestore.collection('password_resets').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _user?.uid,
      });
      return true;
    } catch (e) {
      print('Error rejecting reset request: $e');
      return false;
    }
  }
  
  // Generate a 6-digit random code
  String _generateResetCode() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(random.length - 6, random.length);
  }
  
  // Direct password reset (for authenticated users)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error changing password: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Send password reset email directly (forgot password - sends email)
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error sending reset email: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}