import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

class ShopDetailsPage extends StatefulWidget {
  final int shopId;
  final Function(int) onOrderCreated;

  const ShopDetailsPage(
      {super.key, required this.shopId, required this.onOrderCreated});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  late Future<List<Map<String, dynamic>>> _stockItems;

  // Map linking subcategories to specific images
  final Map<String, String> subcategoryImages = {
    "Potatoes": "assets/images/potatoes.png",
    "Onions": "assets/images/onions.png",
    "Carrots": "assets/images/carrots.png",
    "Cabbage": "assets/images/cabbage.png",
    "Tomatoes": "assets/images/tomatoes.png",
    "Peppers": "assets/images/peppers.png",
    "Cucumbers": "assets/images/cucumbers.png",
    "Garlic": "assets/images/garlic.png",
    "Eggplant": "assets/images/eggplant.png",
    "Zucchini": "assets/images/zucchini.png",
    "Apples": "assets/images/apples.png",
    "Pears": "assets/images/pears.png",
    "Plums": "assets/images/plums.png",
    "Cherries": "assets/images/cherries.png",
    "Grapes": "assets/images/grapes.png",
    "Peaches": "assets/images/peaches.png",
    "Apricots": "assets/images/apricots.png",
    "Strawberries": "assets/images/strawberries.png",
    "Raspberries": "assets/images/raspberries.png",
    "Blueberries": "assets/images/blueberries.png",
    "Honey": "assets/images/honey.png",
    "Wine": "assets/images/wine.png",
    "Jam": "assets/images/jam.png",
    "Pie": "assets/images/pie.png",
    "Pickles": "assets/images/pickles.png",
    "Zacusca": "assets/images/zacusca.png",
    "Eggs": "assets/images/eggs.png",
    "Milk": "assets/images/milk.png",
    "Sausage": "assets/images/sausage.png",
    "Meat": "assets/images/meat.png",
    "Cured Meats": "assets/images/cured_meats.png",
  };

  Future<List<Map<String, dynamic>>> _fetchStockItems() async {
    try {
      final response =
          await ApiService.authenticatedGetRequest('stocks/${widget.shopId}');
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

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final orderId = responseData['order_id'];

        widget.onOrderCreated(
            orderId); // Pass the orderId back to the HomePage if needed

        if (mounted) {
          Navigator.pop(context); // Close the dialog
          setState(() {
            _stockItems = _fetchStockItems();
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added to order successfully!")),
        );
      } else {
        // Parse the response body
        final errorResponse = jsonDecode(response.body);

        // Access the "error" field
        final errorMessage = errorResponse['error'] ?? 'An unknown error occurred';

        if (mounted) {
          Navigator.pop(context); // Close the dialog
        }

        // Throw an exception with the error message
        throw Exception("Failed to add item to order: $errorMessage");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
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

          if (stockItems.isEmpty) {
            return const Center(
              child: Text(
                "No stock items available.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: subcategoryImages.containsKey(item['subcategory'])
                          ? null // Use image if available
                          : Colors.white, // Fallback to white background
                      image: subcategoryImages.containsKey(item['subcategory'])
                          ? DecorationImage(
                              image: AssetImage(
                                  subcategoryImages[item['subcategory']]!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Center(
                      child: Container(
                        color: Colors.black.withOpacity(0.5), // Overlay for text visibility
                        child: Text(
                          item['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item['name']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.price_check, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text("Price: ${item['price_per_unit']} lei / ${item['unit']}"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.category, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text("Subcategory: ${item['subcategory']}"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text("Available: ${item['quantity']} ${item['unit']}"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Description: ${item['description']}",
                      style: const TextStyle(height: 1.4), // Line height for readability
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
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
                final availableQuantity =
                    double.tryParse(item['quantity'].toString()) ?? 0;
                final enteredQuantity =
                    double.tryParse(quantityController.text) ?? 0;

                if (enteredQuantity > 0 &&
                    enteredQuantity <= availableQuantity) {
                  await _addToOrder(
                      widget.shopId, item['id'], enteredQuantity.toInt());
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please enter a valid quantity (1 to $availableQuantity).",
                        ),
                      ),
                    );
                  }
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
