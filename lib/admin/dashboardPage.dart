import 'package:flutter/material.dart';
import 'screens/OrderStatus/orderStatusTab.dart';
import 'screens/OrderTracking/orderTrackingTab.dart';
import 'package:marden_se_staff_and_admin/admin/screens/Inventory/inventoryTab.dart';
import 'package:marden_se_staff_and_admin/admin/screens/Transactions/transactionsTab.dart';
import 'package:marden_se_staff_and_admin/admin/screens/Update Services/updateServicesTab.dart';
import 'package:marden_se_staff_and_admin/admin/screens/ManageAccount/manageAccountTab.dart';

class DashboardPage extends StatefulWidget {
  final String role; // 'admin' or 'staff'
  const DashboardPage({Key? key, required this.role}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Tab> tabs;
  late List<Widget> tabViews;

  @override
  void initState() {
    super.initState();

    if (widget.role == 'admin') {
      tabs = const [
        Tab(text: "Order Status"),
        Tab(text: "Order Tracking"),
        Tab(text: "Inventory"),
        Tab(text: "Transactions"),
        Tab(text: "Update Services"),
        Tab(text: "Manage Accounts"),
      ];

      tabViews = [
        OrderStatusPage(),
        OrderTrackingTab(),
        InventoryWidget(),
        TransactionsTab(),
        UpdateServicesTab(),
        ManageAccountTab(),
      ];
    } else {
      tabs = const [
        Tab(text: "Order Status"),
        Tab(text: "Order Tracking"),
        Tab(text: "Inventory"),
        Tab(text: "Transactions"),
      ];

      tabViews = const [
        OrderStatusPage(),
        OrderTrackingTab(),
        InventoryWidget(),
        TransactionsTab(),
      ];
    }

    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MARDEN HUB - Laundry Hub"),
        backgroundColor: const Color(0xFF40025B),
        actions: const [
          Icon(Icons.account_circle, color: Colors.white),
          SizedBox(width: 16),
          Icon(Icons.water_drop, color: Colors.white),
          SizedBox(width: 16),
          Icon(Icons.menu, color: Colors.white),
          SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }
}
