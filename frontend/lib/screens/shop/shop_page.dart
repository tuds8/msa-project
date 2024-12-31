import 'package:flutter/material.dart';
import 'package:frontend/screens/shop/shop_edit.dart';
import 'package:frontend/screens/shop/shop_register.dart';

class ShopPage extends StatelessWidget {
  final bool isSeller;
  final Map<String, dynamic>? shopDetails;

  const ShopPage({super.key, required this.isSeller, this.shopDetails});

  @override
  Widget build(BuildContext context) {
    if (!isSeller) {
      return Scaffold(
        appBar: AppBar(title: const Text("Shop")),
        body: const Center(
          child: Text("This page is only available for sellers."),
        ),
      );
    }

    if (shopDetails == null) {
      // Redirect to RegisterShopPage if no shop exists
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RegisterShopPage()),
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Shop")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Shop Name: ${shopDetails!['name']}", style: const TextStyle(fontSize: 18)),
            Text("Location: ${shopDetails!['location']}", style: const TextStyle(fontSize: 18)),
            Text("Category: ${shopDetails!['category']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditShopPage(shopDetails: shopDetails!),
                  ),
                );
              },
              child: const Text("Edit Shop"),
            ),
          ],
        ),
      ),
    );
  }
}
