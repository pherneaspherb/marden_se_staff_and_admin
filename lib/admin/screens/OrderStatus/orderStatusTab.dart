import 'package:flutter/material.dart';
import 'LaundryOrderStatusTab.dart';
import 'WaterOrderStatusTab.dart';

class OrderStatusPage extends StatelessWidget {
  const OrderStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF40025B),
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [Tab(text: 'Laundry Orders'), Tab(text: 'Water Orders')],
            ),
          ),

          const Expanded(
            child: TabBarView(
              children: [LaundryOrderStatusTab(), WaterOrderStatusTab()],
            ),
          ),
        ],
      ),
    );
  }
}
