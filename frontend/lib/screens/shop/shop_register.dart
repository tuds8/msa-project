import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/utils/pick-up-point/pick_up_point_selector_page.dart';
import 'dart:convert';

class RegisterShopPage extends StatefulWidget {
  final int sellerId; // Accept seller ID

  const RegisterShopPage({super.key, required this.sellerId});

  @override
  State<RegisterShopPage> createState() => _RegisterShopPageState();
}

class _RegisterShopPageState extends State<RegisterShopPage> {
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _selectedPickUpPoint;
  List<Map<String, dynamic>> _availablePickUpPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailablePickUpPoints();
  }

  Future<void> _fetchAvailablePickUpPoints() async {
    try {
      final response = await ApiService.authenticatedGetRequest('pickup-points');
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          _availablePickUpPoints = data.map((point) {
            return {
              'id': point['id'], // Ensure ID is retrieved
              'name': point['name'],
              'latitude': point['latitude'],
              'longitude': point['longitude'],
            };
          }).toList();
        });
      } else {
        throw Exception("Failed to fetch pick-up points");
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

  Future<void> _createNewPickUpPoint(Map<String, dynamic> newPickUpPoint) async {
    try {
      final newPickUpPointPayload = {
        'lat': double.parse(newPickUpPoint['latitude'].toStringAsFixed(6)),
        'long': double.parse(newPickUpPoint['longitude'].toStringAsFixed(6)),
        'name': newPickUpPoint['name'],
        'address': "Auto-generated address", // Replace with reverse geocoding
      };

      print("Creating new pick-up point with payload: $newPickUpPointPayload");

      final newPointResponse = await ApiService.authenticatedPostRequest(
        'pickup-points/create',
        newPickUpPointPayload,
      );

      if (newPointResponse.statusCode == 201) {
        final newPointData = jsonDecode(newPointResponse.body);
        setState(() {
          newPickUpPoint['id'] = newPointData['pickup_point']['id']; // Update with new ID
          _availablePickUpPoints.add(newPickUpPoint); // Add to available points
          _selectedPickUpPoint = newPickUpPoint; // Set as selected
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pick-up point created successfully!")),
        );
      } else {
        throw Exception(
          "Failed to create pick-up point. Status: ${newPointResponse.statusCode}, Body: ${newPointResponse.body}",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating pick-up point: ${e.toString()}")),
      );
    }
  }

  Future<void> _saveShop() async {
    if (_nameController.text.isEmpty || _selectedPickUpPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    try {
      final shopPayload = {
        'name': _nameController.text,
        'pickup_point': _selectedPickUpPoint!['id'],
      };

      print("Creating shop with payload: $shopPayload");

      final response = await ApiService.authenticatedPostRequest(
        'shops',
        shopPayload,
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop registered successfully!")),
        );
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        throw Exception(
          "Failed to register shop. Status: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _addNewPickUpPoint() async {
    LatLng? newPoint = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PickUpPointSelectorPage(),
      ),
    );

    if (newPoint != null) {
      String? pointName = await _getPointNameFromUser();
      if (pointName != null) {
        final newPickUpPoint = {
          'id': null, // New pick-up point has no ID initially
          'name': pointName,
          'latitude': newPoint.latitude,
          'longitude': newPoint.longitude,
        };

        await _createNewPickUpPoint(newPickUpPoint);
      }
    }
  }

  Future<String?> _getPointNameFromUser() async {
    String? pointName;
    await showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _pointNameController = TextEditingController();
        return AlertDialog(
          title: const Text("Enter Pick-Up Point Name"),
          content: TextField(
            controller: _pointNameController,
            decoration: const InputDecoration(hintText: "Pick-Up Point Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                pointName = _pointNameController.text.trim();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
    return pointName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Shop"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Shop Name Field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Shop Name"),
                  ),
                  const SizedBox(height: 20),

                  // Pick-Up Point Dropdown
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedPickUpPoint,
                    onChanged: (Map<String, dynamic>? value) {
                      setState(() {
                        _selectedPickUpPoint = value;
                      });
                    },
                    items: _availablePickUpPoints.map((point) {
                      return DropdownMenuItem(
                        value: point,
                        child: Text(point['name']),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: "Pick-Up Point"),
                  ),
                  const SizedBox(height: 10),

                  // Add New Pick-Up Point Button
                  ElevatedButton(
                    onPressed: _addNewPickUpPoint,
                    child: const Text("Add New Pick-Up Point"),
                  ),
                  const SizedBox(height: 20),

                  // Register Shop Button
                  ElevatedButton(
                    onPressed: _saveShop,
                    child: const Text("Register Shop"),
                  ),
                ],
              ),
            ),
    );
  }
}
