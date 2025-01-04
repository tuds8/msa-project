import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';
import '../orders/ongoing_order_page.dart';

class ShopDetailsPage extends StatefulWidget {
  final int shopId;
  final Function(int) onOrderCreated;

  const ShopDetailsPage({super.key, required this.shopId, required this.onOrderCreated});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  late Future<List<Map<String, dynamic>>> _stockItems;

  Future<List<Map<String, dynamic>>> _fetchStockItems() async {
    try {
      final response = await ApiService.authenticatedGetRequest('stocks/${widget.shopId}');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch stock items.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      return [];
    }
  }

  Future<void> _addToOrder(int shopId, int stockItemId, int quantity) async {
    try {
      final response = await ApiService.authenticatedPostRequest(
        'orders/add-item',
        {
          'shop_id': shopId,
          'stock_id': stockItemId,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final orderId = responseData['order_id'];

        widget.onOrderCreated(orderId); // Pass the orderId back to the HomePage if needed

        // Navigate directly to OngoingOrderPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OngoingOrderPage(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added to order successfully!")),
        );
      } else {
        throw Exception("Failed to add item to order. Status: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _stockItems = _fetchStockItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop Stock")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _stockItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final stockItems = snapshot.data ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemCount: stockItems.length,
            itemBuilder: (context, index) {
              final item = stockItems[index];
              return GestureDetector(
                onTap: () => _showStockDetails(item),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Price: ${item['price_per_unit']} ${item['unit']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Qty: ${item['quantity']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showStockDetails(Map<String, dynamic> item) {
    final TextEditingController _quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Price: ${item['price_per_unit']} ${item['unit']}"),
              Text("Subcategory: ${item['subcategory']}"),
              Text("Available Quantity: ${item['quantity']}"),
              const SizedBox(height: 10),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: "Desired Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final availableQuantity = double.tryParse(item['quantity'].toString()) ?? 0;
                final enteredQuantity = double.tryParse(_quantityController.text) ?? 0;

                if (enteredQuantity > 0 && enteredQuantity <= availableQuantity) {
                  await _addToOrder(widget.shopId, item['id'], enteredQuantity.toInt());
                  Navigator.pop(context); // Close dialog after adding
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Please enter a valid quantity (1 to $availableQuantity).",
                      ),
                    ),
                  );
                }
              },
              child: const Text("Add to Order"),
            ),
          ],
        );
      },
    );
  }
}
