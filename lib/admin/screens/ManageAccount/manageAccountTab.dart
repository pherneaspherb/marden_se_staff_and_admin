import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageAccountTab extends StatelessWidget {
  const ManageAccountTab({Key? key}) : super(key: key);

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
        backgroundColor: Colors.blue,
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

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateColor.resolveWith(
                    (states) => const Color(0xFF40025B)),
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Phone', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Created At', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                ],
                rows: staffAccounts.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return DataRow(
                    cells: [
                      DataCell(Text(fullName, style: const TextStyle(color: Colors.black))),
                      DataCell(Text(data['email'] ?? '', style: const TextStyle(color: Colors.black))),
                      DataCell(Text(data['phone'] ?? '', style: const TextStyle(color: Colors.black))),
                      DataCell(Text(
                        DateFormat('MMM d, yyyy').format(createdAt),
                        style: const TextStyle(color: Colors.black),
                      )),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              tooltip: 'View',
                              onPressed: () => _showDetailsDialog(context, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(context, doc.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF40025B),
        title: const Text('Staff Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
                style: const TextStyle(color: Colors.white)),
            Text('Email: ${data['email'] ?? ''}', style: const TextStyle(color: Colors.white)),
            Text('Phone: ${data['phone'] ?? ''}', style: const TextStyle(color: Colors.white)),
            Text('Role: ${data['role'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF40025B),
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this account?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('staff').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF40025B),
        title: const Text('Add Staff', style: TextStyle(color: Colors.white)),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('staff').add({
                'firstName': firstNameController.text.trim(),
                'lastName': lastNameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'role': 'staff',
                'createdAt': Timestamp.now(),
              });
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
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
}
