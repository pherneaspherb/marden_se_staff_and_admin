import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateServicesTab extends StatefulWidget {
  @override
  _UpdateServicesTabState createState() => _UpdateServicesTabState();
}

class _UpdateServicesTabState extends State<UpdateServicesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, TextEditingController> _laundryControllers = {};
  Map<String, TextEditingController> _waterControllers = {};
  bool _loading = true;

  // Ordered keys to display in correct order
  final List<String> laundryKeys = [
    'wash_and_dry',
    'wash_only',
    'dry_only',
    'fabric_softener',
    'fold',
    'per_kilogram',
    'pickup',
    'deliver',
  ];

  final List<String> waterKeys = [
    'tube_container',
    'jug_container',
    'pickup',
    'deliver',
  ];

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    final laundryDoc =
        await _firestore.collection('services').doc('laundry').get();
    final waterDoc = await _firestore.collection('services').doc('water').get();

    setState(() {
      _laundryControllers = _mapToControllers(laundryDoc.data() ?? {});
      _waterControllers = _mapToControllers(waterDoc.data() ?? {});
      _loading = false;
    });
  }

  Map<String, TextEditingController> _mapToControllers(
    Map<String, dynamic> data,
  ) {
    return data.map(
      (key, value) =>
          MapEntry(key, TextEditingController(text: value?.toString() ?? '')),
    );
  }

  Future<void> updateServices(
    String category,
    Map<String, TextEditingController> controllers,
  ) async {
    final Map<String, dynamic> updates = {};

    for (var entry in controllers.entries) {
      final val = entry.value.text.trim();
      if (val.isEmpty) continue;

      final parsed = double.tryParse(val);
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid number for "${_formatLabel(entry.key)}"'),
          ),
        );
        return;
      }
      updates[entry.key] = parsed;
    }

    try {
      await _firestore.collection('services').doc(category).update(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$category services updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $category services')),
      );
    }
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'wash_and_dry':
        return 'Wash & Dry';
      case 'wash_only':
        return 'Wash Only';
      case 'dry_only':
        return 'Dry Only';
      case 'fabric_softener':
        return 'Fabric Softener';
      case 'fold':
        return 'Fold';
      case 'per_kilogram':
        return 'Per Kilogram';
      case 'pickup':
        return 'Pick Up';
      case 'deliver':
        return 'Delivery Fee';
      case 'tube_container':
        return 'Tube Container';
      case 'jug_container':
        return 'Jug Container';
      default:
        return key.replaceAll("_", " ").replaceAllMapped(
          RegExp(r'(^|_)([a-z])'),
          (match) => ' ${match[2]!.toUpperCase()}',
        ).trim();
    }
  }

  Widget _buildServiceSection(
    String title,
    Map<String, TextEditingController> controllers,
    String type,
  ) {
    final keyOrder = type == 'laundry' ? laundryKeys : waterKeys;

    return Card(
      color: const Color(0xFF40025B),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title Services',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...keyOrder.where((key) => key != 'pickup').map((key) {
              final controller = controllers[key];
              if (controller == null) return SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: _formatLabel(key),
                    prefixText: '₱ ',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => updateServices(type, controllers),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _laundryControllers.values.forEach((c) => c.dispose());
    _waterControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: AppBar(
            backgroundColor: const Color(0xFF40025B),
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [Tab(text: 'Laundry Service'), Tab(text: 'Water Service')],
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildServiceSection('Laundry', _laundryControllers, 'laundry'),
              ],
            ),
            ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildServiceSection('Water', _waterControllers, 'water'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
