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

  @override
  void initState() {
    super.initState();
    _orderHistory = _fetchOrderHistory();
  }

  @override
  Widget build(BuildContext context) {
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

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text("Order ID: ${order['id']}"),
                subtitle: Text("Total Items: ${order['total_items']}"),
                trailing: Text("Total: ${order['total_price']}"),
              ),
            );
          },
        );
      },
    );
  }
}
