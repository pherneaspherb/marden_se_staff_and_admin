import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthSignUpPage extends StatefulWidget {
  final String role; // 'admin' or 'staff'

  const AuthSignUpPage({Key? key, required this.role}) : super(key: key);

  @override
  State<AuthSignUpPage> createState() => _AuthSignUpPageState();
}

class _AuthSignUpPageState extends State<AuthSignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("FirebaseAuth returned null user");
      }

      // Store user data in Firestore collection based on role
      await FirebaseFirestore.instance
          .collection(widget.role == 'admin' ? 'admins' : 'staff')
          .doc(user.uid)
          .set({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'role': widget.role,
        'createdAt': Timestamp.now(),
      });

      // Navigate to respective dashboard
      if (widget.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/staff-dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email already in use';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print("Unexpected error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    bool obscureText = isPassword
        ? (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword)
        : false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Enter $label' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() {
                    if (isConfirmPassword) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  }),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String roleCapitalized = widget.role[0].toUpperCase() + widget.role.substring(1);

    return Scaffold(
      backgroundColor: const Color(0xFF40025B),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    '$roleCapitalized Sign Up',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _firstName, label: 'First Name'),
                  _buildTextField(controller: _lastName, label: 'Last Name'),
                  _buildTextField(
                    controller: _phone,
                    label: 'Phone Number',
                    type: TextInputType.phone,
                  ),
                  _buildTextField(
                    controller: _email,
                    label: 'Email',
                    type: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    controller: _password,
                    label: 'Password',
                    isPassword: true,
                  ),
                  _buildTextField(
                    controller: _confirmPassword,
                    label: 'Confirm Password',
                    isPassword: true,
                    isConfirmPassword: true,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF40025B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                          child: Text('Create $roleCapitalized Account'),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
