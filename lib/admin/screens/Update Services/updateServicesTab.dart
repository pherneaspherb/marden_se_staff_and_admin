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

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    final laundryDoc = await _firestore.collection('services').doc('laundry').get();
    final waterDoc = await _firestore.collection('services').doc('water').get();

    setState(() {
      _laundryControllers = _mapToControllers(laundryDoc.data() ?? {});
      _waterControllers = _mapToControllers(waterDoc.data() ?? {});
      _loading = false;
    });
  }

  Map<String, TextEditingController> _mapToControllers(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(
        key, TextEditingController(text: value?.toString() ?? '')));
  }

  Future<void> updateServices(String category, Map<String, TextEditingController> controllers) async {
    final Map<String, dynamic> updates = {};

    for (var entry in controllers.entries) {
      final val = entry.value.text.trim();
      if (val.isEmpty) continue;

      final parsed = double.tryParse(val);
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Invalid number for "${_formatLabel(entry.key)}"')));
        return;
      }
      updates[entry.key] = parsed;
    }

    try {
      await _firestore.collection('services').doc(category).update(updates);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$category services updated successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update $category services'),
      ));
    }
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'washAndDry':
        return 'Wash & Dry';
      case 'washOnly':
        return 'Wash Only';
      case 'dryOnly':
        return 'Dry Only';
      case 'fabricSoftener':
        return 'Fabric Softener';
      case 'fold':
        return 'Fold';
      case 'perKilogram':
        return 'Per Kilogram';
      case 'pickup':
        return 'Pick Up';
      case 'deliveryFee':
        return 'Delivery Fee';
      case 'tubContainer':
        return 'Tube Container';
      case 'jugContainer':
        return 'Jug Container';
      default:
        return key.replaceAll("_", " ");
    }
  }

  Widget _buildServiceSection(
      String title, Map<String, TextEditingController> controllers, String type) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$title Services',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: _formatLabel(entry.key),
                  prefixText: '₱ ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => updateServices(type, controllers),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B007D),
              ),
              child: const Text('Save Changes'),
            ),
          )
        ]),
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

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildServiceSection('Laundry', _laundryControllers, 'laundry'),
        _buildServiceSection('Water', _waterControllers, 'water'),
      ],
    );
  }
}