import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marden_se_staff_and_admin/admin/screens/Transactions/downloadReceipt.dart'
    show generateAndDownloadPdf;
import 'package:marden_se_staff_and_admin/admin/screens/Transactions/receiptView.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  Map<String, dynamic>? laundryPrices;
  Map<String, dynamic>? waterPrices;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    fetchServicePrices();
  }

  Future<void> fetchServicePrices() async {
    final laundrySnap =
        await FirebaseFirestore.instance
            .collection('services')
            .doc('laundry')
            .get();
    final waterSnap =
        await FirebaseFirestore.instance
            .collection('services')
            .doc('water')
            .get();

    setState(() {
      laundryPrices = laundrySnap.data();
      waterPrices = waterSnap.data();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (laundryPrices == null || waterPrices == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: const Color(0xFF40025B),
            child: TabBar(
              controller: _mainTabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Laundry Transactions'),
                Tab(text: 'Water Transactions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                TransactionListView(
                  orderType: 'laundryOrders',
                  totalKey: 'totalAmount',
                  serviceKey: 'serviceType',
                  isLaundry: true,
                  priceMap: laundryPrices!,
                ),
                TransactionListView(
                  orderType: 'waterOrders',
                  totalKey: 'totalPrice',
                  serviceKey: 'containerType',
                  isLaundry: false,
                  priceMap: waterPrices!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionListView extends StatelessWidget {
  final String orderType;
  final String totalKey;
  final String serviceKey;
  final bool isLaundry;
  final Map<String, dynamic> priceMap;

  const TransactionListView({
    required this.orderType,
    required this.totalKey,
    required this.serviceKey,
    required this.isLaundry,
    required this.priceMap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Stream of all customers
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, customersSnapshot) {
        if (customersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!customersSnapshot.hasData ||
            customersSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No customers found.'));
        }

        final customers = customersSnapshot.data!.docs;

        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customerDoc = customers[index];
            final customerId = customerDoc.id;
            final customerData = customerDoc.data();

            return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future:
                  FirebaseFirestore.instance
                      .collection('customers')
                      .doc(customerId)
                      .collection(orderType)
                      .where('status', isEqualTo: 'completed')
                      .get(),
              builder: (context, ordersSnapshot) {
                if (ordersSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Can be loading indicator if you want
                }
                if (!ordersSnapshot.hasData ||
                    ordersSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink(); // No orders for this customer and type
                }

                final orders = ordersSnapshot.data!.docs;

                return Column(
                  children:
                      orders.map((orderDoc) {
                        final orderData = orderDoc.data();

                        // Prepare address
                        final defaultAddress =
                            customerData['defaultAddress']
                                as Map<String, dynamic>?;
                        final addressMap =
                            orderData['address'] as Map<String, dynamic>?;

                        final formattedAddress =
                            (addressMap != null && addressMap.isNotEmpty)
                                ? "${addressMap['house'] ?? ''}, ${addressMap['barangay'] ?? ''}, ${addressMap['municipality'] ?? ''}, ${addressMap['city'] ?? ''}"
                                : defaultAddress != null
                                ? "${defaultAddress['street'] ?? ''}, ${defaultAddress['barangay'] ?? ''}, ${defaultAddress['municipality'] ?? ''}, ${defaultAddress['city'] ?? ''}"
                                : "No address provided";

                        // Parse price
                        final rawTotal = orderData[totalKey];
                        final totalPrice =
                            num.tryParse(rawTotal?.toString() ?? '') ?? 0;
                        final priceString = totalPrice.toStringAsFixed(2);

                        // Breakdown string
                        final breakdown =
                            isLaundry
                                ? _getLaundryBreakdown(orderData, priceMap)
                                : _getWaterBreakdown(orderData, priceMap);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Card(
                            color: const Color(0xFF40025B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ORDER ${orderData['orderId'] ?? 'No ID'}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${customerData['lastName']}, ${customerData['firstName']}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedAddress,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    breakdown,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "₱$priceString",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => ReceiptView(
                                                        orderData: orderData,
                                                        customerData: {
                                                          ...customerData,
                                                          'id': customerId,
                                                        },
                                                      ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(
                                                0xFF40025B,
                                              ),
                                            ),
                                            child: const Text("View Receipt"),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: () async {
                                              try {
                                                await generateAndDownloadPdf(
                                                  orderData,
                                                  customerData,
                                                  isLaundry,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'PDF generated and downloaded!',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error generating PDF: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Colors.white,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text(
                                              "Download Receipt",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  String _getLaundryBreakdown(
    Map<String, dynamic> order,
    Map<String, dynamic> prices,
  ) {
    const serviceKeyMap = {
      'Wash & Dry': 'wash_and_dry',
      'Wash Only': 'wash_only',
      'Dry Only': 'dry_only',
      'Fabric Softener': 'fabric_softener',
      'Fold': 'fold',
      'Pickup': 'pickup',
      'Deliver': 'deliver',
    };

    final service = order['serviceType'] ?? '';
    final mappedKey =
        serviceKeyMap[service] ?? service.toLowerCase().replaceAll(' ', '_');

    final weight = num.tryParse(order['weight']?.toString() ?? '') ?? 0;
    final extras = (order['extras'] as List?)?.cast<String>() ?? [];
    final deliveryMode = order['deliveryMode'] ?? '';

    final basePrice = (prices[mappedKey] ?? 0) as num;
    final perKg = (prices['per_kilogram'] ?? 0) as num;
    final extrasTotal = extras.fold<num>(0, (sum, e) {
      final key = e.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and');
      return sum + (prices[key] ?? 0);
    });

    final deliveryFee =
        deliveryMode.toLowerCase() == 'deliver' ? (prices['deliver'] ?? 0) : 0;

    return "$service (₱${basePrice.toStringAsFixed(2)})\n"
        "Weight: $weight kg × ₱${perKg.toStringAsFixed(2)} = ₱${(weight * perKg).toStringAsFixed(2)}\n"
        "Extras: ${extras.isNotEmpty ? extras.join(', ') : 'None'} (₱${extrasTotal.toStringAsFixed(2)})\n"
        "Delivery: $deliveryMode (₱${deliveryFee.toStringAsFixed(2)})";
  }

  String _getWaterBreakdown(
    Map<String, dynamic> order,
    Map<String, dynamic> prices,
  ) {
    final containerType = order['containerType'] ?? 'Unknown';
    final deliveryMode = order['deliveryMode'] ?? '';

    // Map container label to Firestore pricing key
    final containerKeyMap = {'Jug': 'jug_container', 'Tube': 'tube_container'};

    // Safely get container price using the map
    final containerKey = containerKeyMap[containerType] ?? '';
    final containerPrice = prices[containerKey] ?? 0;

    // Get container quantities
    final jugQty = num.tryParse(order['jug_container']?.toString() ?? '') ?? 0;
    final tubeQty =
        num.tryParse(order['tube_container']?.toString() ?? '') ?? 0;

    // Individual container prices
    final jugPrice = (prices['jug_container'] ?? 0) as num;
    final tubePrice = (prices['tube_container'] ?? 0) as num;

    // Delivery fee logic
    final deliveryFee =
        deliveryMode.toLowerCase() == 'deliver' ? (prices['deliver'] ?? 0) : 0;

    // Construct readable breakdown
    String breakdown =
        "Container Type: $containerType (₱${(containerPrice as num).toStringAsFixed(2)})\n";

    if (jugQty > 0) {
      breakdown +=
          "Jug Container x $jugQty (₱${jugPrice.toStringAsFixed(2)} each)\n";
    }
    if (tubeQty > 0) {
      breakdown +=
          "Tube Container x $tubeQty (₱${tubePrice.toStringAsFixed(2)} each)\n";
    }

    breakdown += "Delivery: $deliveryMode (₱${deliveryFee.toStringAsFixed(2)})";

    return breakdown;
  }
}
