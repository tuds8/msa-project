import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/utils/pick-up-point/pick_up_point_selector_page.dart';
import 'dart:convert';

class EditShopPage extends StatefulWidget {
  final Map<String, dynamic> shopDetails; // Current shop details

  const EditShopPage({super.key, required this.shopDetails});

  @override
  State<EditShopPage> createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage> {
  late TextEditingController _nameController;
  Map<String, dynamic>? _selectedPickUpPoint;
  List<Map<String, dynamic>> _availablePickUpPoints = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing shop details
    _nameController = TextEditingController(text: widget.shopDetails['name']);
    _selectedPickUpPoint = widget.shopDetails['pickup_point'];
    _fetchAvailablePickUpPoints();
  }

  Future<void> _fetchAvailablePickUpPoints() async {
    try {
      final response =
          await ApiService.authenticatedGetRequest('pickup-points');
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          _availablePickUpPoints = data.map((point) {
            return {
              'id': point['id'],
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
  }

  Future<void> _saveShopDetails() async {
    if (_nameController.text.isEmpty || _selectedPickUpPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare the payload for the update
      final shopPayload = {
        'name': _nameController.text,
        'pickup_point': _selectedPickUpPoint!['id'],
      };

      print("Updating shop with payload: $shopPayload");

      // Send the PATCH request to update the shop
      final response = await ApiService.authenticatedPatchRequest(
        'shop/manage',
        shopPayload,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop details updated successfully!")),
        );
        Navigator.pop(context); // Navigate back to the Shop page
      } else {
        throw Exception(
          "Failed to update shop details. Status: ${response.statusCode}, Body: ${response.body}",
        );
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
        try {
          final newPickUpPointPayload = {
            'lat': double.parse(newPoint.latitude.toStringAsFixed(6)),
            'long': double.parse(newPoint.longitude.toStringAsFixed(6)),
            'name': pointName,
            'address':
                "Auto-generated address", // Replace with reverse geocoding
          };

          print(
              "Creating new pick-up point with payload: $newPickUpPointPayload");

          final newPointResponse = await ApiService.authenticatedPostRequest(
            'pickup-points/create',
            newPickUpPointPayload,
          );

          if (newPointResponse.statusCode == 201) {
            final newPointData = jsonDecode(newPointResponse.body);
            final newPoint = {
              'id': newPointData['pickup_point']['id'],
              'name': pointName,
              'latitude': newPointData['pickup_point']['lat'],
              'longitude': newPointData['pickup_point']['long'],
            };

            setState(() {
              _availablePickUpPoints.add(newPoint); // Add to available points
              _selectedPickUpPoint = newPoint; // Set as selected
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Pick-up point created successfully!")),
            );
          } else {
            throw Exception(
              "Failed to create pick-up point. Status: ${newPointResponse.statusCode}, Body: ${newPointResponse.body}",
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error creating pick-up point: ${e.toString()}")),
          );
        }
      }
    }
  }

  Future<String?> _getPointNameFromUser() async {
    String? pointName;
    await showDialog(
      context: context,
      builder: (context) {
        final TextEditingController pointNameController =
            TextEditingController();
        return AlertDialog(
          title: const Text("Enter Pick-Up Point Name"),
          content: TextField(
            controller: pointNameController,
            decoration: const InputDecoration(hintText: "Pick-Up Point Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                pointName = pointNameController.text.trim();
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
        title: const Text("Edit Shop"),
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
                  DropdownButtonFormField<Map<String, dynamic>?>(
                    value: _availablePickUpPoints.firstWhere(
                      (item) => item['id'] == _selectedPickUpPoint?['id'],
                      orElse: () => {}, // Return null if no match is found
                    ),
                    onChanged: (Map<String, dynamic>? value) {
                      setState(() {
                        _selectedPickUpPoint = value;
                      });
                    },
                    items: _availablePickUpPoints.map((point) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: point,
                        child: Text(point['name']),
                      );
                    }).toList(),
                    decoration:
                        const InputDecoration(labelText: "Pick-Up Point"),
                  ),
                  const SizedBox(height: 10),

                  // Add New Pick-Up Point Button
                  ElevatedButton(
                    onPressed: _addNewPickUpPoint,
                    child: const Text("Add New Pick-Up Point"),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveShopDetails,
                    child: const Text("Save"),
                  ),
                ],
              ),
            ),
    );
  }
}
