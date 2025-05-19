import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingTab extends StatefulWidget {
  const OrderTrackingTab({super.key});

  @override
  State<OrderTrackingTab> createState() => _OrderTrackingTabState();
}

class _OrderTrackingTabState extends State<OrderTrackingTab>
    with TickerProviderStateMixin {
  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Tab(text: 'Laundry Orders'),
                Tab(text: 'Water Orders'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: const [
                LaundryOrderListView(),
                WaterOrderListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaundryOrderListView extends StatelessWidget {
  const LaundryOrderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return OrderListView(
      orderType: 'laundryOrders',
      totalKey: 'totalAmount',
      serviceKey: 'serviceType',
    );
  }
}

class WaterOrderListView extends StatelessWidget {
  const WaterOrderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return OrderListView(
      orderType: 'waterOrders',
      totalKey: 'totalPrice',
      serviceKey: 'containerType',
    );
  }
}

class OrderListView extends StatelessWidget {
  final String orderType;
  final String totalKey;
  final String serviceKey;

  const OrderListView({
    required this.orderType,
    required this.totalKey,
    required this.serviceKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, customerSnapshot) {
        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!customerSnapshot.hasData || customerSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No customers found."));
        }

        final customerDocs = customerSnapshot.data!.docs;

        return ListView(
          children: customerDocs.expand((customerDoc) {
            final customerData = customerDoc.data() as Map<String, dynamic>?;
            if (customerData == null) return <Widget>[];

            final defaultAddress =
                customerData['defaultAddress'] as Map<String, dynamic>?;

            final customerId = customerDoc.id;

            return [
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('customers')
                    .doc(customerId)
                    .collection(orderType)
                    .get(),
                builder: (context, orderSnapshot) {
                  if (!orderSnapshot.hasData ||
                      orderSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: orderSnapshot.data!.docs.map((orderDoc) {
                      final orderData =
                          orderDoc.data() as Map<String, dynamic>?;

                      if (orderData == null) return const SizedBox.shrink();

                      final addressMap =
                          orderData['address'] as Map<String, dynamic>?;

                      final formattedAddress = (addressMap != null &&
                              addressMap.isNotEmpty)
                          ? "${addressMap['house'] ?? ''}, ${addressMap['barangay'] ?? ''}, ${addressMap['municipality'] ?? ''}, ${addressMap['city'] ?? ''}"
                          : defaultAddress != null
                              ? "${defaultAddress['street'] ?? ''}, ${defaultAddress['barangay'] ?? ''}, ${defaultAddress['municipality'] ?? ''}, ${defaultAddress['city'] ?? ''}"
                              : "No address provided";

                      final status = orderData['status'] ?? 'Unknown';
                      final price = orderData[totalKey]?.toString() ?? '0.00';
                      final serviceInfo =
                          orderData[serviceKey]?.toString() ?? 'N/A';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Card(
                          color: const Color(0xFF40025B),
                          elevation: 2,
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
                                  "${customerData['firstName']} ${customerData['lastName']}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Email: ${customerData['email'] ?? 'N/A'}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "Phone: ${customerData['phoneNumber'] ?? 'N/A'}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "Address: $formattedAddress",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "Service: $serviceInfo",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₱$price",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 42, 214, 108),
                                        ),
                                      ),
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
              ),
            ];
          }).toList(),
        );
      },
    );
  }
}
