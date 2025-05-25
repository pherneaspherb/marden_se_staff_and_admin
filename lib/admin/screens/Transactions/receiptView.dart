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

    num extrasPrice = 0;
    for (var extra in extras) {
      final key = _normalizeKey(extra);
      extrasPrice += (prices[key] ?? 0);
    }

    final deliveryPrice =
        deliveryMode.toLowerCase() == 'deliver' ? (prices['deliver'] ?? 0) : 0;

    final total =
        basePrice + (perKgPrice * weight) + extrasPrice + deliveryPrice;

    return Card(
      color: const Color(0xFF40025B),
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_laundry_service, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Laundry Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Colors.white54),
              Text(
                'Service Type: $serviceType - ₱${basePrice.toStringAsFixed(2)}',
              ),
              Text(
                'Weight: $weight kg x ₱${perKgPrice.toStringAsFixed(2)} = ₱${(perKgPrice * weight).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              const Text(
                'Extras:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (extras.isNotEmpty)
                ...extras.map((extra) {
                  final price = prices[_normalizeKey(extra)] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text('• $extra: ₱${price.toStringAsFixed(2)}'),
                  );
                })
              else
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4),
                  child: Text('None'),
                ),
              const SizedBox(height: 8),
              Text(
                'Delivery Mode: $deliveryMode - ₱${deliveryPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF40025B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ₱${total.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

    if (!prices.containsKey(containerKey)) {
      debugPrint('⚠️ Missing container price for "$containerKey"');
    }

    final deliveryPrice =
        deliveryMode.toLowerCase() == 'deliver' ? (prices['deliver'] ?? 0) : 0;

    final total = (containerPrice * quantity) + deliveryPrice;

    return Card(
      color: const Color(0xFF40025B),
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.water_drop, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Water Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Colors.white54),
              Text(
                'Container Type: $containerType - ₱${containerPrice.toStringAsFixed(2)}',
              ),
              Text(
                'Quantity: $quantity x ₱${containerPrice.toStringAsFixed(2)} = ₱${(containerPrice * quantity).toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              Text(
                'Delivery Mode: $deliveryMode - ₱${deliveryPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF40025B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ₱${total.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (servicePrices == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Receipt Details'),
        backgroundColor: const Color(0xFF40025B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Order ID: ${widget.orderData['orderId'] ?? 'No ID'}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF40025B),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF40025B),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Customer Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: Colors.white54,
                      ),
                      Text(
                        "${widget.customerData['lastName'] ?? ''}, ${widget.customerData['firstName'] ?? ''}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedAddress(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isLaundry) _buildLaundryBreakdown() else _buildWaterBreakdown(),
          ],
        ),
      ),
    );
  }
}
