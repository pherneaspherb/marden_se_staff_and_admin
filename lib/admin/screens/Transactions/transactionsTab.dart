import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marden_se_staff_and_admin/admin/screens/Transactions/downloadReceipt.dart'
    show generateAndDownloadPdf;

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab>
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
                Tab(text: 'Laundry Transactions'),
                Tab(text: 'Water Transactions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: const [
                TransactionListView(
                  orderType: 'laundryOrders',
                  totalKey: 'totalAmount',
                  serviceKey: 'serviceType',
                  isLaundry: true,
                ),
                TransactionListView(
                  orderType: 'waterOrders',
                  totalKey: 'totalPrice',
                  serviceKey: 'containerType',
                  isLaundry: false,
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

  const TransactionListView({
    required this.orderType,
    required this.totalKey,
    required this.serviceKey,
    required this.isLaundry,
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
          children:
              customerDocs.expand((customerDoc) {
                final customerData =
                    customerDoc.data() as Map<String, dynamic>?;
                if (customerData == null) return <Widget>[];

                final defaultAddress =
                    customerData['defaultAddress'] as Map<String, dynamic>?;
                final customerId = customerDoc.id;

                return [
                  FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('customers')
                            .doc(customerId)
                            .collection(orderType)
                            .where('status', isEqualTo: 'completed')
                            .get(),
                    builder: (context, orderSnapshot) {
                      if (!orderSnapshot.hasData ||
                          orderSnapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children:
                            orderSnapshot.data!.docs.map((orderDoc) {
                              final orderData =
                                  orderDoc.data() as Map<String, dynamic>?;
                              if (orderData == null)
                                return const SizedBox.shrink();

                              final addressMap =
                                  orderData['address'] as Map<String, dynamic>?;

                              final formattedAddress =
                                  (addressMap != null && addressMap.isNotEmpty)
                                      ? "${addressMap['house'] ?? ''}, ${addressMap['barangay'] ?? ''}, ${addressMap['municipality'] ?? ''}, ${addressMap['city'] ?? ''}"
                                      : defaultAddress != null
                                      ? "${defaultAddress['street'] ?? ''}, ${defaultAddress['barangay'] ?? ''}, ${defaultAddress['municipality'] ?? ''}, ${defaultAddress['city'] ?? ''}"
                                      : "No address provided";

                              final priceDouble =
                                  (orderData[totalKey] as num?)?.toDouble() ??
                                  0.0;
                              final price = priceDouble.toStringAsFixed(2);
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        Text(
                                          serviceInfo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "₱$price",
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
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => ReceiptView(
                                                              orderData:
                                                                  orderData,
                                                              customerData:
                                                                  customerData,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.white,
                                                        foregroundColor:
                                                            const Color(
                                                              0xFF40025B,
                                                            ),
                                                      ),
                                                  child: const Text(
                                                    "View Receipt",
                                                  ),
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
                                                            'Failed to generate PDF: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.white,
                                                        side: const BorderSide(
                                                          color: Colors.white,
                                                        ),
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
                  ),
                ];
              }).toList(),
        );
      },
    );
  }
}

class ReceiptView extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> customerData;

  const ReceiptView({
    required this.orderData,
    required this.customerData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = orderData['orderId'] ?? 'No ID';
    final totalValue =
        (orderData['totalAmount'] ?? orderData['totalPrice']) as num? ?? 0.0;
    final total = totalValue.toStringAsFixed(2);

    // Detect if laundry or water based on presence of keys
    final isLaundry = orderData.containsKey('serviceType');

    final serviceType =
        isLaundry
            ? (orderData['serviceType'] ?? 'N/A')
            : (orderData['containerType'] ?? 'N/A');

    final addressMap = orderData['address'] as Map<String, dynamic>?;
    final defaultAddress =
        customerData['defaultAddress'] as Map<String, dynamic>?;

    final formattedAddress =
        (addressMap != null && addressMap.isNotEmpty)
            ? "${addressMap['house'] ?? ''}, ${addressMap['barangay'] ?? ''}, ${addressMap['municipality'] ?? ''}, ${addressMap['city'] ?? ''}"
            : defaultAddress != null
            ? "${defaultAddress['street'] ?? ''}, ${defaultAddress['barangay'] ?? ''}, ${defaultAddress['municipality'] ?? ''}, ${defaultAddress['city'] ?? ''}"
            : "No address provided";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Receipt - Order $orderId'),
        backgroundColor: const Color(0xFF40025B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: const Color(0xFF40025B),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipt Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Order ID', orderId),
                const Divider(),
                _buildInfoRow(
                  'Customer',
                  '${customerData['firstName'] ?? '-'} ${customerData['lastName'] ?? '-'}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Address', formattedAddress),
                const Divider(),
                // Show laundry or water specific fields here
                if (isLaundry) ...[
                  _buildInfoRow(
                    'Service Type',
                    orderData['serviceType'] ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Extras',
                    orderData['extras'] is List
                        ? (orderData['extras'] as List).join(', ')
                        : (orderData['extras']?.toString() ?? 'None'),
                  ),

                  _buildInfoRow(
                    'Weight',
                    orderData['weight']?.toString() ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Delivery Mode',
                    orderData['deliveryMode'] ?? 'N/A',
                  ),
                ] else ...[
                  _buildInfoRow(
                    'Container Type',
                    orderData['containerType'] ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Quantity',
                    orderData['quantity']?.toString() ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Delivery Mode',
                    orderData['deliveryMode'] ?? 'N/A',
                  ),
                ],
                const Divider(),
                _buildInfoRow(
                  'Total Amount',
                  '₱$total',
                  valueStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
