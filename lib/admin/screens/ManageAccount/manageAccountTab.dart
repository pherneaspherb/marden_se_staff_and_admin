import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageAccountTab extends StatefulWidget {
  const ManageAccountTab({Key? key}) : super(key: key);

  @override
  State<ManageAccountTab> createState() => _ManageAccountTabState();
}

class _ManageAccountTabState extends State<ManageAccountTab> {
  Stream<QuerySnapshot> getStaffAccounts() {
    return FirebaseFirestore.instance
        .collection('staff')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: const Color(0xFF40025B),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: getStaffAccounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No staff accounts found.',
                  style: TextStyle(color: Colors.black),
                ),
              );
            }

            final staffAccounts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: staffAccounts.length,
              itemBuilder: (context, index) {
                final doc = staffAccounts[index];
                final data = doc.data() as Map<String, dynamic>;
                final fullName =
                    "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
                final createdAt =
                    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                return Card(
                  color: const Color(0xFF40025B),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Email: ${data['email'] ?? ''}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Phone: ${data['phone'] ?? ''}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Created: ${DateFormat('MMM d, yyyy').format(createdAt)}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context, doc.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF40025B),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this account?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('staff').doc(docId).delete();
              // Note: Deleting the Firebase Auth user here requires admin privileges or callable cloud function
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool passwordVisible = false;
    bool confirmPasswordVisible = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF40025B),
              title: const Text(
                'Add Staff',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildInputField('First Name', firstNameController),
                    const SizedBox(height: 10),
                    _buildInputField('Last Name', lastNameController),
                    const SizedBox(height: 10),
                    _buildInputField('Email', emailController),
                    const SizedBox(height: 10),
                    _buildInputField('Phone', phoneController),
                    const SizedBox(height: 10),
                    _buildPasswordField(
                      'Password',
                      passwordController,
                      passwordVisible,
                      () => setState(() => passwordVisible = !passwordVisible),
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordField(
                      'Confirm Password',
                      confirmPasswordController,
                      confirmPasswordVisible,
                      () => setState(() => confirmPasswordVisible = !confirmPasswordVisible),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final password = passwordController.text;
                    final confirmPassword = confirmPasswordController.text;
                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }
                    try {
                      final auth = FirebaseAuth.instance;
                      UserCredential userCredential =
                          await auth.createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: password,
                      );

                      await FirebaseFirestore.instance
                          .collection('staff')
                          .doc(userCredential.user!.uid)
                          .set({
                        'firstName': firstNameController.text.trim(),
                        'lastName': lastNameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'role': 'staff',
                        'createdAt': Timestamp.now(),
                      });

                      Navigator.pop(context);
                    } on FirebaseAuthException catch (e) {
                      String errorMsg = 'Failed to add staff.';
                      if (e.code == 'email-already-in-use') {
                        errorMsg = 'Email already in use.';
                      } else if (e.code == 'weak-password') {
                        errorMsg = 'Password is too weak.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMsg)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('An unexpected error occurred.')),
                      );
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool isVisible,
      VoidCallback toggleVisibility,
      ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
