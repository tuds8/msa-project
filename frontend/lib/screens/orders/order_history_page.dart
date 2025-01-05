import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<Map<String, dynamic>>> _orderHistory;
  String? _userRole;
  bool _isLoadingRole = true;

  Future<List<Map<String, dynamic>>> _fetchOrderHistory() async {
    try {
      final response = await ApiService.authenticatedGetRequest('orders');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch order history.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      return [];
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      final response = await ApiService.authenticatedPatchRequest(
        'orders/$orderId/cancel',
        {},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order canceled successfully!")),
        );
        setState(() {
          _orderHistory = _fetchOrderHistory();
        });
      } else {
        final errorResponse = jsonDecode(response.body);
        final errorMessage =
            errorResponse['error'] ?? 'Failed to cancel order.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _confirmOrder(int orderId) async {
    try {
      final response = await ApiService.authenticatedPatchRequest(
        'orders/$orderId/confirm',
        {},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order confirmed successfully!")),
        );
        setState(() {
          _orderHistory = _fetchOrderHistory();
        });
      } else {
        final errorResponse = jsonDecode(response.body);
        final errorMessage =
            errorResponse['error'] ?? 'Failed to confirm order.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.authenticatedGetRequest('profile');
      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        setState(() {
          _userRole = profileData['role'];
          _isLoadingRole = false;
        });
      } else {
        throw Exception('Failed to fetch user role.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  Color _getCardColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.yellow.shade100; // Light yellow
      case 'cancelled':
        return Colors.red.shade100; // Light red
      case 'completed':
        return Colors.green.shade100; // Light green
      default:
        return Colors.grey.shade100; // Default color for unknown statuses
    }
  }

  @override
  void initState() {
    super.initState();
    _orderHistory = _fetchOrderHistory();
    _fetchUserRole();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _orderHistory,
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

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Text("No orders found."),
          );
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              color: _getCardColor(order['status']), // Set card color
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order #${order['id']} at ${order['shop']['name']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("Status: ${order['status']}"),
                        Text("Total: ${order['total_price']} lei"),
                      ],
                    ),
                    Row(
                      children: [
                        if (_userRole == 'seller' && order['status'] == 'pending')
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _confirmOrder(order['id']),
                            tooltip: "Confirm Order",
                          ),
                        if (order['status'] == 'pending')
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _cancelOrder(order['id']),
                            tooltip: "Cancel Order",
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
