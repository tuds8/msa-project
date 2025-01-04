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
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController();
    final TextEditingController _unitController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();
    final TextEditingController _descriptionController =
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
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: "Name"),
                        ),
                        TextField(
                          controller: _unitController,
                          decoration: const InputDecoration(labelText: "Unit"),
                        ),
                        TextField(
                          controller: _quantityController,
                          decoration:
                              const InputDecoration(labelText: "Quantity"),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: _priceController,
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
                          controller: _descriptionController,
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
                          'name': _nameController.text,
                          'unit': _unitController.text,
                          'quantity': _quantityController.text,
                          'price_per_unit': _priceController.text,
                          'subcategory': _selectedSubcategory,
                          'description': _descriptionController.text,
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
    final TextEditingController _descriptionController =
        TextEditingController(text: item['description']);
    final TextEditingController _quantityController =
        TextEditingController(text: item['quantity'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item['name']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Price per Unit: ${item['price_per_unit']}"),
                Text("Subcategory: ${item['subcategory']}"),
                const SizedBox(height: 10),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _descriptionController,
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
                final updatedItem = {
                  'quantity': _quantityController.text,
                  'description': _descriptionController.text,
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
                        content:
                            Text("Failed to update item: ${response.body}")),
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
                        content:
                            Text("Failed to delete item: ${response.body}")),
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
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemCount: stockItems.length + 1,
            itemBuilder: (context, index) {
              if (index == stockItems.length) {
                return GestureDetector(
                  onTap: _addNewStockItem,
                  child: Card(
                    color: Colors.blueAccent,
                    child: const Center(
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
                  child: Center(
                    child: Text(
                      item['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
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
