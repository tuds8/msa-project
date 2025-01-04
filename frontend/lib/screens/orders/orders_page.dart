import 'package:flutter/material.dart';
import 'order_history_page.dart';
import 'ongoing_order_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _isOngoingOrderView = true; // Toggle between ongoing and history views

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        actions: [
          Row(
            children: [
              Text(
                _isOngoingOrderView ? "Ongoing Order" : "Order History",
                style: const TextStyle(fontSize: 16),
              ),
              Switch(
                value: _isOngoingOrderView,
                onChanged: (value) {
                  setState(() {
                    _isOngoingOrderView = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: _isOngoingOrderView
          ? const OngoingOrderPage() // Ongoing order content
          : const OrderHistoryPage(), // Order history content
    );
  }
}
