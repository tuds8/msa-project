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
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _orderDetails = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _orderDetails = null;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch active order.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
        setState(() {
          _isLoading = false;
        });
      }
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
          _orderDetails = null;
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

  Future<void> _cancelOrder() async {
    if (_orderDetails == null) return;

    try {
      final response = await ApiService.authenticatedPatchRequest(
        'orders/${_orderDetails!['id']}/cancel',
        {},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order cancelled successfully.")),
        );
        setState(() {
          _orderDetails = null;
        });
      } else {
        throw Exception("Failed to cancel order.");
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
    _fetchActiveOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderDetails == null
              ? const Center(child: Text("No active order."))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _orderDetails!['items'].length,
                        itemBuilder: (context, index) {
                          final item = _orderDetails!['items'][index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              onTap: () => _editOrderItemDialog(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.shopping_basket,
                                                color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${item['stock']['name']}",
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _removeOrderItem(item['id']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.format_list_numbered,
                                            color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Quantity: ${item['quantity']} ${item['stock']['unit']}",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_money,
                                            color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Price: ${(double.parse(item['price_at_purchase']) * double.parse(item['quantity'])).toStringAsFixed(2)} lei",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Price:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${_orderDetails!['total_price']} lei",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
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
                            onPressed: _cancelOrder, // Call _cancelOrder method here
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
    final TextEditingController quantityController =
        TextEditingController(text: item['quantity'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Item"),
          content: TextField(
            controller: quantityController,
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
                final newQuantity = int.tryParse(quantityController.text) ?? 0;
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
