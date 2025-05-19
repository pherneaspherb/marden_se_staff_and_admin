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
      // No appBar here
      body: StreamBuilder<QuerySnapshot>(
        stream: getStaffAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No staff accounts found.'));
          }

          final staffAccounts = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Actions')),
              ],
              rows: staffAccounts.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fullName = "${data['firstName']} ${data['lastName']}";
                final createdAt = (data['createdAt'] as Timestamp).toDate();

                return DataRow(
                  cells: [
                    DataCell(Text(fullName)),
                    DataCell(Text(data['email'] ?? '')),
                    DataCell(Text(data['phone'] ?? '')),
                    DataCell(
                      Text(DateFormat('MMM d, yyyy').format(createdAt)),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View',
                            onPressed: () => _showDetailsDialog(context, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
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
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Staff Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${data['firstName']} ${data['lastName']}'),
            Text('Email: ${data['email']}'),
            Text('Phone: ${data['phone']}'),
            Text('Role: ${data['role']}'),
          ],
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

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete this account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('staff')
                  .doc(docId)
                  .delete();
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('staff').add({
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'email': emailController.text,
                'phone': phoneController.text,
                'role': 'staff',
                'createdAt': Timestamp.now(),
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
