import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';

class StockPage extends StatefulWidget {
  final int shopId;

  const StockPage({super.key, required this.shopId});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  late Future<List<Map<String, dynamic>>> _stockItems;
  late Future<List<Map<String, dynamic>>> _categories;

  List<Map<String, dynamic>> _subcategories = [];
  String? _selectedCategory;
  String? _selectedSubcategory;

  // Map linking subcategories to specific images
  final Map<String, String> subcategoryImages = {
    // Vegetables
    "Potatoes": "assets/images/potatoes.png",
    "Onions": "assets/images/onions2.png",
    "Carrots": "assets/images/carrots.png",
    "Cabbage": "assets/images/cabbage.png",
    "Tomatoes": "assets/images/tomatoes.png",
    "Peppers": "assets/images/peppers.png",
    "Cucumbers": "assets/images/cucumbers.png",
    "Garlic": "assets/images/garlic.png",
    "Eggplant": "assets/images/eggplant.png",
    "Zucchini": "assets/images/zucchini.png",
    // Fruit
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
    // Homemade products
    "Honey": "assets/images/honey.png",
    "Wine": "assets/images/wine.png",
    "Jam": "assets/images/jam.png",
    "Pie": "assets/images/pie.png",
    "Pickles": "assets/images/pickles.png",
    "Zacusca": "assets/images/zacusca.png",
    // Animal based products
    "Eggs": "assets/images/eggs.png",
    "Milk": "assets/images/milk.png",
    "Sausage": "assets/images/sausage.png",
    "Meat": "assets/images/meat.png",
    "Cured Meats": "assets/images/cured_meats.png",
  };

  Future<List<Map<String, dynamic>>> _fetchStockItems() async {
    try {
      final response = await ApiService.authenticatedGetRequest(
          'stocks/${widget.shopId}');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch stock items');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      final response =
          await ApiService.authenticatedGetRequest('categories');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch categories');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return [];
    }
  }

  void _updateSubcategories(String categoryId) async {
    try {
      final resolvedCategories = await _categories;

      // Find the selected category and update the subcategories
      final selectedCategory = resolvedCategories
          .firstWhere((category) => category['id'].toString() == categoryId);

      setState(() {
        _subcategories =
            List<Map<String, dynamic>>.from(selectedCategory['subcategories']);
        _selectedSubcategory = null; // Reset selected subcategory
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _addNewStockItem() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _categories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];

                return AlertDialog(
                  title: const Text("Add New Stock Item"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: "Name"),
                        ),
                        TextField(
                          controller: unitController,
                          decoration: const InputDecoration(labelText: "Unit"),
                        ),
                        TextField(
                          controller: quantityController,
                          decoration:
                              const InputDecoration(labelText: "Quantity"),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(
                              labelText: "Price per Unit"),
                          keyboardType: TextInputType.number,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedCategory = value;
                              _updateSubcategories(value!);
                            });
                          },
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['id'].toString(),
                              child: Text(category['name']),
                            );
                          }).toList(),
                          decoration: const InputDecoration(labelText: "Category"),
                        ),
                        if (_subcategories.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedSubcategory,
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedSubcategory = value;
                              });
                            },
                            items: _subcategories.map((subcategory) {
                              return DropdownMenuItem<String>(
                                value: subcategory['id'].toString(),
                                child: Text(subcategory['name']),
                              );
                            }).toList(),
                            decoration: const InputDecoration(labelText: "Subcategory"),
                          ),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(labelText: "Description"),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final newItem = {
                          'name': nameController.text,
                          'unit': unitController.text,
                          'quantity': quantityController.text,
                          'price_per_unit': priceController.text,
                          'subcategory': _selectedSubcategory,
                          'description': descriptionController.text,
                        };

                        final response = await ApiService.authenticatedPostRequest(
                          'stocks/add',
                          newItem,
                        );

                        if (response.statusCode == 201) {
                          setState(() {
                            _stockItems = _fetchStockItems();
                          });
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Failed to add stock item: ${response.body}")),
                          );
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showStockItemDetails(Map<String, dynamic> item) async {
    final TextEditingController descriptionController =
        TextEditingController(text: item['description']);
    final TextEditingController quantityController =
        TextEditingController(text: item['quantity'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item['name']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.price_check, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text("Price: ${item['price_per_unit']} lei / unit"),
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
                    Text("Available Quantity: ${item['quantity']}"),
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
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: "Update Quantity"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Update Description"),
                  // maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final updatedItem = {
                  'quantity': quantityController.text,
                  'description': descriptionController.text,
                };

                final response = await ApiService.authenticatedPatchRequest(
                  'stocks/edit/${item['id']}',
                  updatedItem,
                );

                if (response.statusCode == 200) {
                  setState(() {
                    _stockItems = _fetchStockItems();
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to update item: ${response.body}"),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () async {
                final response = await ApiService.authenticatedDeleteRequest(
                  'stocks/remove/${item['id']}',
                );

                if (response.statusCode == 200) {
                  setState(() {
                    _stockItems = _fetchStockItems();
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to delete item: ${response.body}"),
                    ),
                  );
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _stockItems = _fetchStockItems();
    _categories = _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock")),
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
            padding: const EdgeInsets.all(15.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemCount: stockItems.length + 1,
            itemBuilder: (context, index) {
              if (index == stockItems.length) {
                return GestureDetector(
                  onTap: _addNewStockItem,
                  child: const Card(
                    color: Colors.blueAccent,
                    child: Center(
                      child: Text(
                        "Add New Item",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                );
              }

              final item = stockItems[index];
              return GestureDetector(
                onTap: () => _showStockItemDetails(item),
                child: Card(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      // color: subcategoryImages.containsKey(item['subcategory'])
                      //     ? const Color.fromARGB(0, 255, 255, 255) // If an image exists, no need for solid color
                      //     : const Color.fromARGB(0, 255, 255, 255), // Fallback to black background
                      image: subcategoryImages.containsKey(item['subcategory'])
                          ? DecorationImage(
                              image: AssetImage(subcategoryImages[item['subcategory']]!),
                              fit: BoxFit.cover, // Cover the entire card
                            )
                          : null, // No image if fallback
                      borderRadius: BorderRadius.circular(10.0), // Optional for rounded corners
                    ),
                    child: Center(
                      child: Container(
                        color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
                        child: Text(
                          item['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Text color for visibility
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
}
