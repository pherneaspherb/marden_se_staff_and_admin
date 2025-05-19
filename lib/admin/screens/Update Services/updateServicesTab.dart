import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateServicesTab extends StatefulWidget {
  const UpdateServicesTab({super.key});

  @override
  State<UpdateServicesTab> createState() => _UpdateServicesTabState();
}

class _UpdateServicesTabState extends State<UpdateServicesTab> {
  final _laundryControllers = {
    'washAndDry': TextEditingController(),
    'washOnly': TextEditingController(),
    'dryOnly': TextEditingController(),
    'deliveryFee': TextEditingController(),
  };

  final _waterControllers = {
    'tubContainer': TextEditingController(),
    'jugContainer': TextEditingController(),
    'deliveryFee': TextEditingController(),
  };

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final laundrySnap =
          await FirebaseFirestore.instance.collection('services').doc('laundry').get();
      final waterSnap =
          await FirebaseFirestore.instance.collection('services').doc('water').get();

      final laundryData = laundrySnap.data();
      final waterData = waterSnap.data();

      void setController(
          Map<String, TextEditingController> controllers, Map<String, dynamic>? data) {
        if (data == null) return;
        controllers.forEach((key, controller) {
          controller.text = data[key]?.toString() ?? '0';
        });
      }

      setController(_laundryControllers, laundryData);
      setController(_waterControllers, waterData);

      setState(() => _loading = false);
    } catch (e) {
      print('Error loading service data: $e');
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load service data')),
      );
    }
  }

  Future<void> _saveData(
      String type, Map<String, TextEditingController> controllers) async {
    final Map<String, dynamic> updatedData = {};

    for (var entry in controllers.entries) {
      final value = double.tryParse(entry.value.text);
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Invalid input for "${_formatLabel(entry.key)}". Please enter a valid number.')));
        return; // stop saving if invalid input
      }
      updatedData[entry.key] = value;
    }

    try {
      await FirebaseFirestore.instance.collection('services').doc(type).update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type services updated successfully!')),
      );
    } catch (e) {
      print('Error updating $type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $type services')),
      );
    }
  }

  Widget _buildServiceCard(
      String title, Map<String, TextEditingController> controllers, String type) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '$title Services',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),
          ...controllers.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: _formatLabel(entry.key),
                  border: const OutlineInputBorder(),
                  labelStyle: const TextStyle(color: Colors.black),
                  prefixText: '₱ ', // show peso symbol for clarity
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: const Color(0xFF4B007D),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _saveData(type, controllers),
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                alignment: Alignment.center,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'washAndDry':
        return 'Wash & Dry';
      case 'washOnly':
        return 'Wash Only';
      case 'dryOnly':
        return 'Dry Only';
      case 'tubContainer':
        return 'Tub Container';
      case 'jugContainer':
        return 'Jug Container';
      case 'deliveryFee':
        return 'Delivery Fee';
      default:
        return key;
    }
  }

  @override
  void dispose() {
    for (var controller in _laundryControllers.values) {
      controller.dispose();
    }
    for (var controller in _waterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.white,
      child: ListView(
        children: [
          _buildServiceCard('Laundry', _laundryControllers, 'laundry'),
          _buildServiceCard('Water', _waterControllers, 'water'),
        ],
      ),
    );
  }
}
