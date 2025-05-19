import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryWidget extends StatefulWidget {
  const InventoryWidget({Key? key}) : super(key: key);

  @override
  _InventoryWidgetState createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  String? errorMessage;
  List<InventoryItem> items = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        changeCategory(_tabController.index == 0 ? 'laundry' : 'water');
      }
    });
    loadInventory('laundry');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadInventory(String category) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('inventory')
              .where('category', isEqualTo: category)
              .get();

      if (snapshot.docs.isEmpty) {
        await createDefaultItemsForCategory(category);
        return loadInventory(category);
      }

      items =
          snapshot.docs.map((doc) => InventoryItem.fromFirestore(doc)).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load inventory: $e';
      });
    }
  }

  Future<void> createDefaultItemsForCategory(String category) async {
    final batch = FirebaseFirestore.instance.batch();

    final defaultItems =
        (category == 'laundry')
            ? [
              {'name': 'Detergent (Powder)', 'stock': 0},
              {'name': 'Fabric Softener', 'stock': 0},
              {'name': 'Bleach', 'stock': 0},
            ]
            : [
              {'name': 'Empty Tube Water Containers', 'stock': 0},
              {'name': 'Empty Jug Water Containers', 'stock': 0},
              {'name': 'Purification Chemicals', 'stock': 0},
            ];

    for (var item in defaultItems) {
      var docRef = FirebaseFirestore.instance.collection('inventory').doc();
      batch.set(docRef, {
        'category': category,
        'name': item['name'],
        'stock': item['stock'],
      });
    }

    await batch.commit();
  }

  Future<void> updateStock(String docId, int newStock) async {
    try {
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(docId)
          .update({'stock': newStock});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating stock: $e')));
    }
  }

  void changeCategory(String category) {
    loadInventory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Set the background to white
      child: Column(
        children: [
          Container(
            color: const Color(0xFF40025B),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [Tab(text: 'Laundry'), Tab(text: 'Water')],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                      : items.isEmpty
                      ? Center(
                        child: Text(
                          'No items found in ${_tabController.index == 0 ? "laundry" : "water"} inventory.',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                      : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          var item = items[index];
                          return Card(
                            color: const Color(0xFF40025B),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.white,
                                    ),
                                    onPressed:
                                        item.stock > 0
                                            ? () {
                                              setState(() {
                                                item.stock--;
                                              });
                                              updateStock(item.id, item.stock);
                                            }
                                            : null,
                                  ),
                                  Text(
                                    '${item.stock}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        item.stock++;
                                      });
                                      updateStock(item.id, item.stock);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryItem {
  final String id;
  final String name;
  int stock;

  InventoryItem({required this.id, required this.name, required this.stock});

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      stock: data['stock'] ?? 0,
    );
  }
}
