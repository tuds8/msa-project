import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

class OngoingOrderPage extends StatefulWidget {
  const OngoingOrderPage({super.key});

  @override
  State<OngoingOrderPage> createState() => _OngoingOrderPageState();
}

class _OngoingOrderPageState extends State<OngoingOrderPage> {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;

  Future<void> _fetchActiveOrder() async {
    try {
      final response = await ApiService.authenticatedGetRequest('orders/active');
      if (response.statusCode == 200) {
        setState(() {
          _orderDetails = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _orderDetails = null; // No active order
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch active order.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editOrderItem(int orderItemId, int quantity) async {
    try {
      final response = await ApiService.authenticatedPatchRequest(
        'orders/item/edit/$orderItemId',
        {'quantity': quantity},
      );
      if (response.statusCode == 200) {
        await _fetchActiveOrder();
      } else {
        throw Exception("Failed to edit item.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _removeOrderItem(int orderItemId) async {
    try {
      final response = await ApiService.authenticatedDeleteRequest(
          'orders/item/delete/$orderItemId');
      if (response.statusCode == 200) {
        await _fetchActiveOrder();
      } else {
        throw Exception("Failed to remove item from order.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _placeOrder() async {
    if (_orderDetails == null) return;

    try {
      final response = await ApiService.authenticatedPatchRequest(
        'orders/${_orderDetails!['id']}/submit',
        {},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully.")),
        );
        setState(() {
          _orderDetails = null; // Clear active order
        });
      } else {
        throw Exception("Failed to place order.");
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
    _fetchActiveOrder(); // Fetch the active order on initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ongoing Order")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderDetails == null
              ? const Center(child: Text("No active order."))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _orderDetails!['items'].length,
                        itemBuilder: (context, index) {
                          final item = _orderDetails!['items'][index];
                          return ListTile(
                            title: Text("Stock ID: ${item['stock']}"),
                            subtitle: Text(
                              "Quantity: ${item['quantity']} | Price at Purchase: ${item['price_at_purchase']}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeOrderItem(item['id']),
                            ),
                            onTap: () => _editOrderItemDialog(item),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _placeOrder,
                            child: const Text("Place Order"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("Cancel"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  void _editOrderItemDialog(Map<String, dynamic> item) {
    final TextEditingController _quantityController =
        TextEditingController(text: item['quantity'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Item"),
          content: TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: "Quantity"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newQuantity = int.tryParse(_quantityController.text) ?? 0;
                if (newQuantity > 0) {
                  await _editOrderItem(item['id'], newQuantity);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid quantity.")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
