import 'package:flutter/material.dart';
import 'package:frontend/screens/shop/shop_edit.dart';
import 'package:frontend/screens/shop/shop_register.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

class ShopPage extends StatefulWidget {
  final bool isSeller;
  final int sellerId; // Seller ID

  const ShopPage({super.key, required this.isSeller, required this.sellerId});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Future<Map<String, dynamic>?> _fetchShopDetails() async {
    try {
      final response = await ApiService.authenticatedGetRequest('shop/manage');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null; // No shop associated
      } else {
        throw Exception('Failed to fetch shop details');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSeller) {
      return Scaffold(
        appBar: AppBar(title: const Text("Shop")),
        body: const Center(
          child: Text("This page is only available for sellers."),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchShopDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Shop")),
            body: Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final shopDetails = snapshot.data;

        if (shopDetails == null) {
          // Redirect to RegisterShopPage if no shop exists
          Future.microtask(() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterShopPage(sellerId: widget.sellerId),
              ),
            );
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Parse shop details
        final shopName = shopDetails['name'];
        final pickupPoint = shopDetails['pickup_point'];
        final seller = shopDetails['seller'];

        return Scaffold(
          appBar: AppBar(title: const Text("Shop")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Details
                Text("Shop Name: $shopName", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),

                // Pickup Point Details
                if (pickupPoint != null) ...[
                  const Text("Pickup Point:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Name: ${pickupPoint['name']}", style: const TextStyle(fontSize: 16)),
                  Text("Address: ${pickupPoint['address']}", style: const TextStyle(fontSize: 16)),
                  Text("Coordinates: ${pickupPoint['lat']}, ${pickupPoint['long']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                ],

                // Seller Details
                if (seller != null) ...[
                  const Text("Seller Information:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Name: ${seller['first_name']} ${seller['last_name']}", style: const TextStyle(fontSize: 16)),
                  Text("Email: ${seller['email']}", style: const TextStyle(fontSize: 16)),
                  Text("Phone: ${seller['phone']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                ],

                // Edit Shop Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditShopPage(shopDetails: shopDetails),
                      ),
                    );
                  },
                  child: const Text("Edit Shop"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
