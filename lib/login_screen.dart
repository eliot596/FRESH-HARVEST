import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart';
import 'customer_home.dart';
import 'index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _phoneController;
  late final TextEditingController _resetEmailController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showForgotPassword = false;
  bool _showResetForm = false;
  bool _isRequestSent = false;
  String _resetRequestId = '';
  String? _selectedLocation;
  bool _useCustomLocation = false;
  
  final List<String> _availableLocations = [
    'Mbarara City Center',
    'Kakoba',
    'Nyamitanga',
    'Kamukuzi',
    'Boma',
    'Ruharo',
    'Kisenyi',
    'Katete',
    'Kijungu',
    'Rwanyamahe',
  ];
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();
    _resetEmailController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _resetEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _goBackToIndex() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IndexPage()),
    );
  }
  
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        if (_isLogin) {
          final result = await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          final user = result.user;
          if (user != null) {
            final userDoc = await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists && userDoc['role'] == 'admin') {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboard()),
                );
              }
            } else {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerHome()),
                );
              }
            }
          }
        } else {
          final result = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          // Determine final location
          String finalLocation;
          if (_useCustomLocation) {
            finalLocation = _locationController.text.trim();
          } else {
            finalLocation = _selectedLocation ?? '';
          }
          
          await _firestore.collection('users').doc(result.user!.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': 'customer',
            'location': finalLocation,
            'phone': _phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! Please login.'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _isLogin = true;
              _emailController.clear();
              _passwordController.clear();
              _nameController.clear();
              _locationController.clear();
              _phoneController.clear();
              _selectedLocation = null;
              _useCustomLocation = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLogin ? 'Login failed: ${e.toString().split(']').last}' : 'Registration failed: ${e.toString().split(']').last}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _requestPasswordReset() async {
    if (_resetEmailController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    if (_newPasswordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter new password'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    if (_newPasswordController.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: _resetEmailController.text.trim())
          .get();
      
      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found with this email'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      final userDoc = userQuery.docs.first;
      final userId = userDoc.id;
      final userName = userDoc['name'] ?? 'User';
      final isAdmin = userDoc['role'] == 'admin';
      
      if (isAdmin) {
        await _auth.sendPasswordResetEmail(email: _resetEmailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent! Check your inbox.'), backgroundColor: Colors.green),
          );
        }
        setState(() {
          _showForgotPassword = false;
          _resetEmailController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _isLoading = false;
        });
        if (mounted) Navigator.pop(context);
      } else {
        final existingRequest = await _firestore
            .collection('password_resets')
            .where('email', isEqualTo: _resetEmailController.text.trim())
            .where('status', isEqualTo: 'pending')
            .get();
        
        if (existingRequest.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You already have a pending reset request. Please wait for admin approval.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        final docRef = await _firestore.collection('password_resets').add({
          'userId': userId,
          'email': _resetEmailController.text.trim(),
          'userName': userName,
          'newPassword': _newPasswordController.text,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _resetRequestId = docRef.id;
          _isRequestSent = true;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset request sent to admin! Please wait for approval.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }
  
  void _checkRequestStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Status'),
        content: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('password_resets').doc(_resetRequestId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final request = snapshot.data!;
            if (!request.exists) {
              return const Text('Request not found');
            }
            
            final status = request['status'];
            
            if (status == 'approved') {
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Password reset approved! You can now login with your new password.'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {
                  _showForgotPassword = false;
                  _isRequestSent = false;
                });
              });
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 50, color: Colors.green),
                  SizedBox(height: 16),
                  Text('✓ Request Approved!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Your password has been reset. You can now login.'),
                  SizedBox(height: 8),
                  CircularProgressIndicator(),
                ],
              );
            } else if (status == 'rejected') {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel, size: 50, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('✗ Request Rejected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(request['rejectionReason'] != null 
                      ? 'Reason: ${request['rejectionReason']}' 
                      : 'Your password reset request was rejected.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isRequestSent = false;
                        _showResetForm = true;
                      });
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.pending, size: 50, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Request Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Waiting for admin approval...'),
                  SizedBox(height: 8),
                  CircularProgressIndicator(),
                ],
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showForgotPasswordDialog() {
    _resetEmailController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _isRequestSent = false;
    _showResetForm = true;
    _resetRequestId = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          if (_isRequestSent) {
            return AlertDialog(
              title: const Text('Password Reset Request'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send, size: 50, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Your request has been sent to admin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait for admin approval.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _checkRequestStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Status'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _isRequestSent = false;
                    });
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          }
          
          return AlertDialog(
            title: const Text('Reset Password'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Container(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, size: 50, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your email and choose a new password.\nAdmin will need to approve your request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _resetEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      helperText: 'Minimum 6 characters',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  await _requestPasswordReset();
                  setDialogState(() {});
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Send Request'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade700, Colors.green.shade300],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back to Index Button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.green),
                          onPressed: _goBackToIndex,
                          tooltip: 'Back to Home',
                        ),
                      ),
                      
                      Icon(Icons.agriculture, size: 80, color: Colors.green.shade700),
                      const SizedBox(height: 16),
                      Text(
                        'FreshHarvest',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),
                      
                      // Full Name - Only for Registration
                      if (!_isLogin)
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Enter full name' : null,
                        ),
                      
                      if (!_isLogin) const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter email';
                          if (!value.contains('@')) return 'Enter valid email';
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter password';
                          if (value.length < 6) return 'Password must be 6+ chars';
                          return null;
                        },
                      ),
                      
                      // Phone Number - Only for Registration
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: 'e.g., 0772 123 456',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                      
                      // Location Selection - Only for Registration
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        
                        // Radio buttons to choose location type
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Select from list'),
                                value: false,
                                groupValue: _useCustomLocation,
                                onChanged: (value) {
                                  setState(() {
                                    _useCustomLocation = false;
                                    _locationController.clear();
                                  });
                                },
                                activeColor: Colors.green,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Enter manually'),
                                value: true,
                                groupValue: _useCustomLocation,
                                onChanged: (value) {
                                  setState(() {
                                    _useCustomLocation = true;
                                    _selectedLocation = null;
                                  });
                                },
                                activeColor: Colors.green,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Show dropdown or text field based on selection
                        if (!_useCustomLocation)
                          DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            decoration: InputDecoration(
                              labelText: 'Select Delivery Location *',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            hint: const Text('Choose your delivery location'),
                            items: _availableLocations.map((location) {
                              return DropdownMenuItem(
                                value: location,
                                child: Text(location),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                            validator: (value) => _selectedLocation == null ? 'Please select your delivery location' : null,
                          )
                        else
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Enter Your Location *',
                              prefixIcon: const Icon(Icons.edit_location),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'e.g., Nkoma, Buremba, Rukindo, etc.',
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your location' : null,
                          ),
                      ],
                      
                      // Forgot Password Link (only for login)
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Login' : 'Register',
                                  style: const TextStyle(fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Back to Home Button
                      OutlinedButton.icon(
                        onPressed: _goBackToIndex,
                        icon: const Icon(Icons.home, size: 18),
                        label: const Text('Back to Home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Toggle between Login and Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLogin ? "Don't have an account?" : "Already have an account?"),
                          TextButton(
                            onPressed: () => setState(() {
                              _isLogin = !_isLogin;
                              _selectedLocation = null;
                              _locationController.clear();
                              _phoneController.clear();
                              _nameController.clear();
                              _useCustomLocation = false;
                            }),
                            child: Text(_isLogin ? 'Register' : 'Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}