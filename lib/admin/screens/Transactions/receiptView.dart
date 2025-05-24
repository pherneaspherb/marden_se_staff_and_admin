import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptView extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> customerData;

  const ReceiptView({
    required this.orderData,
    required this.customerData,
    super.key,
  });

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  Map<String, dynamic>? servicePrices;
  late final bool isLaundry;

  @override
  void initState() {
    super.initState();
    isLaundry = widget.orderData.containsKey('serviceType');

    // Fetch prices from Firestore based on order type
    FirebaseFirestore.instance
        .collection('services')
        .doc(isLaundry ? 'laundry' : 'water')
        .get()
        .then((doc) {
          if (doc.exists) {
            setState(() {
              servicePrices = doc.data();
            });
          }
        });
  }

  String _normalizeKey(String key) {
    return key.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and');
  }

  Widget _buildLaundryBreakdown() {
    final order = widget.orderData;
    final prices = servicePrices ?? {};
    final serviceType = order['serviceType'] ?? '';
    final extras = List<String>.from(order['extras'] ?? []);
    final weight = num.tryParse(order['weight']?.toString() ?? '0') ?? 0;
    final deliveryMode = order['deliveryMode'] ?? '';

    final baseKey = _normalizeKey(serviceType);
    final basePrice = prices[baseKey] ?? 0;
    final perKgPrice = prices['per_kilogram'] ?? 0;

    // Sum extras prices
    num extrasPrice = 0;
    for (var extra in extras) {
      final key = _normalizeKey(extra);
      extrasPrice += (prices[key] ?? 0);
    }

    final deliveryPrice =
        deliveryMode.toLowerCase() == 'deliver' ? (prices['deliver'] ?? 0) : 0;

    final total =
        basePrice + (perKgPrice * weight) + extrasPrice + deliveryPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Type: $serviceType - ₱${basePrice.toStringAsFixed(2)}'),
        Text(
          'Weight: $weight kg x ₱${perKgPrice.toStringAsFixed(2)} = ₱${(perKgPrice * weight).toStringAsFixed(2)}',
        ),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text('Extras:'),
          ...extras.map((extra) {
            final price = prices[_normalizeKey(extra)] ?? 0;
            return Text(' - $extra: ₱${price.toStringAsFixed(2)}');
          }),
        ] else
          const Text('Extras: None'),
        const SizedBox(height: 4),
        Text(
          'Delivery Mode: $deliveryMode - ₱${deliveryPrice.toStringAsFixed(2)}',
        ),
        const Divider(),
        Text(
          'Total: ₱${total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWaterBreakdown() {
    final order = widget.orderData;
    final prices = servicePrices ?? {};
    final containerType = order['containerType'] ?? '';
    final quantity = int.tryParse(order['quantity']?.toString() ?? '0') ?? 0;
    final deliveryMode = order['deliveryMode'] ?? '';

    final containerKey = "${_normalizeKey(containerType)}_container";
    final containerPrice = prices[containerKey] ?? 0;

    // Optional: Debug print if key is missing
    if (!prices.containsKey(containerKey)) {
      debugPrint('⚠️ Missing container price for "$containerKey"');
    }

    final deliveryPrice =
        deliveryMode.toLowerCase() == 'deliver' ? (prices['deliver'] ?? 0) : 0;

    final total = (containerPrice * quantity) + deliveryPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Container Type: $containerType - ₱${containerPrice.toStringAsFixed(2)}',
        ),
        Text(
          'Quantity: $quantity x ₱${containerPrice.toStringAsFixed(2)} = ₱${(containerPrice * quantity).toStringAsFixed(2)}',
        ),
        const SizedBox(height: 4),
        Text(
          'Delivery Mode: $deliveryMode - ₱${deliveryPrice.toStringAsFixed(2)}',
        ),
        const Divider(),
        Text(
          'Total: ₱${total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (servicePrices == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determine address to show: order address overrides customer default
    final orderAddress = widget.orderData['address'] as Map<String, dynamic>?;
    final customerDefaultAddress =
        widget.customerData['defaultAddress'] as Map<String, dynamic>?;

    String formattedAddress() {
      if (orderAddress != null && orderAddress.isNotEmpty) {
        return "${orderAddress['house'] ?? ''}, ${orderAddress['barangay'] ?? ''}, ${orderAddress['municipality'] ?? ''}, ${orderAddress['city'] ?? ''}";
      }
      if (customerDefaultAddress != null) {
        return "${customerDefaultAddress['street'] ?? ''}, ${customerDefaultAddress['barangay'] ?? ''}, ${customerDefaultAddress['municipality'] ?? ''}, ${customerDefaultAddress['city'] ?? ''}";
      }
      return "No address provided";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        backgroundColor: const Color(0xFF40025B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Order ID: ${widget.orderData['orderId'] ?? 'No ID'}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              "Customer: ${widget.customerData['lastName'] ?? ''}, ${widget.customerData['firstName'] ?? ''}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              "Address: ${formattedAddress()}",
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),

            // Show breakdown according to order type
            if (isLaundry) _buildLaundryBreakdown() else _buildWaterBreakdown(),
          ],
        ),
      ),
    );
  }
}
