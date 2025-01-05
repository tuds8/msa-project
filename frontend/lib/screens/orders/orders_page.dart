import 'package:flutter/material.dart';
import 'order_history_page.dart';
import 'ongoing_order_page.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _isOngoingOrderView = true; // Toggle between ongoing and history views
  String? _userRole;
  bool _isLoading = true;

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.authenticatedGetRequest('profile');
      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        setState(() {
          _userRole = profileData['role']; // Assume "role" field indicates user type
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch user profile.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user role: ${e.toString()}")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If the user is a seller, directly show the OrderHistoryPage
    if (_userRole == 'seller') {
      return Scaffold(
        appBar: AppBar(title: const Text("Orders")),
        body: const OrderHistoryPage(),
      );
    }

    // Default layout for buyers (with toggle)
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
