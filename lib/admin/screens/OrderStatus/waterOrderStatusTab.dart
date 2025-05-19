import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart'; // For StreamGroup.merge

enum OrderSubTab { pending, completed }

class WaterOrderStatusTab extends StatefulWidget {
  const WaterOrderStatusTab({super.key});

  @override
  State<WaterOrderStatusTab> createState() => _WaterOrderStatusTabState();
}

class _WaterOrderStatusTabState extends State<WaterOrderStatusTab> {
  OrderSubTab _selectedSubTab = OrderSubTab.pending;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get _customersStream =>
      _firestore.collection('customers').snapshots();

  Stream<List<QueryDocumentSnapshot>> _getFilteredOrdersStream(
    QuerySnapshot customerDocs,
    String status,
  ) {
    final customerIds = customerDocs.docs.map((doc) => doc.id).toList();
    if (customerIds.isEmpty) return Stream.value([]);

    final streams = customerIds.map((customerId) {
      return _firestore
          .collection('customers')
          .doc(customerId)
          .collection('waterOrders')
          .where('status', isEqualTo: status)
          .snapshots();
    });

    return StreamGroup.merge(streams).map((snapshot) => snapshot.docs);
  }

  Widget _buildStatusButton(
    String customerId,
    String orderId,
    String status,
    String label,
  ) {
    return OutlinedButton(
      onPressed: () {
        _firestore
            .collection('customers')
            .doc(customerId)
            .collection('waterOrders')
            .doc(orderId)
            .update({'status': status});
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.deepPurple),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }

  Widget _buildOrderItem(BuildContext context, QueryDocumentSnapshot order) {
    final data = order.data() as Map<String, dynamic>;
    print('Order data for ${order.id}: $data');
    final customerId = order.reference.parent.parent?.id ?? '';
    final orderId = order.id;
    final orderIdFormatted = data['orderId'] ?? 'ORD-';
    final deliveryMode = data['deliveryMode'] ?? 'N/A';

    final rawAmount = data['totalPrice'];
    print('totalAmount for order ${order.id}: ${data['totalPrice']}');
    double amount = 0;
    if (rawAmount is int) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is double) {
      amount = rawAmount;
    } else if (rawAmount is String) {
      amount = double.tryParse(rawAmount) ?? 0;
    }

    final timestamp = data['timestamp']?.toDate() ?? DateTime.now();
    final formattedDate = '${timestamp.day}/${timestamp.month}/${timestamp.year}';

    return Card(
      color: const Color(0xFF40025B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ($orderIdFormatted)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Text(
              'Water Service',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
            ),
            Text(
              'Delivery Mode: $deliveryMode',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₱${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                if (_selectedSubTab == OrderSubTab.pending)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusButton(
                        customerId,
                        orderId,
                        'cancelled',
                        'Cancel',
                      ),
                      const SizedBox(width: 8),
                      _buildStatusButton(
                        customerId,
                        orderId,
                        'completed',
                        'Complete',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(OrderSubTab subTab) {
    final status = subTab == OrderSubTab.pending ? 'pending' : 'completed';

    return StreamBuilder<QuerySnapshot>(
      stream: _customersStream,
      builder: (context, customerSnapshot) {
        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!customerSnapshot.hasData || customerSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No customers found."));
        }

        return StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: _getFilteredOrdersStream(customerSnapshot.data!, status),
          builder: (context, orderSnapshot) {
            if (orderSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!orderSnapshot.hasData || orderSnapshot.data!.isEmpty) {
              return Center(child: Text("No $status orders found."));
            }

            final orders = orderSnapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderItem(context, orders[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildSubTabSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFF40025B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: OrderSubTab.values.map((tab) {
          final label = tab == OrderSubTab.pending ? "Pending" : "Completed";
          final isSelected = _selectedSubTab == tab;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedSubTab = tab),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFF6A2F90) : Colors.transparent,
                foregroundColor: isSelected ? Colors.white : Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(label),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildSubTabSelector(),
          Expanded(child: _buildOrdersList(_selectedSubTab)),
        ],
      ),
    );
  }
}
