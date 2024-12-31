import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class EditShopPage extends StatefulWidget {
  final Map<String, dynamic> shopDetails; // Current shop details

  const EditShopPage({super.key, required this.shopDetails});

  @override
  State<EditShopPage> createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _categoryController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shopDetails['name']);
    _locationController = TextEditingController(text: widget.shopDetails['location']);
    _categoryController = TextEditingController(text: widget.shopDetails['category']);
  }

  Future<void> _saveShopDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.postRequest(
        'shop/${widget.shopDetails['id']}/edit',
        {
          'name': _nameController.text,
          'location': _locationController.text,
          'category': _categoryController.text,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop details updated successfully!")),
        );
        Navigator.pop(context); // Navigate back to the Shop page
      } else {
        throw Exception('Failed to update shop details');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Shop"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Shop Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: "Location"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveShopDetails,
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
