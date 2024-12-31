import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/profile/profile_page.dart';
import 'package:frontend/utils/pick-up-point/pick_up_point_selector_page.dart';
import 'dart:convert';

class RegisterShopPage extends StatefulWidget {
  const RegisterShopPage({super.key});

  @override
  State<RegisterShopPage> createState() => _RegisterShopPageState();
}

class _RegisterShopPageState extends State<RegisterShopPage> {
  final TextEditingController _nameController = TextEditingController();
  Map<String, dynamic>? _selectedPickUpPoint;
  List<Map<String, dynamic>> _availablePickUpPoints = []; // Store name and coordinates
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

  Future<void> _saveShop() async {
    if (_nameController.text.isEmpty || _selectedPickUpPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    try {
      final response = await ApiService.postRequest(
        'shop/register',
        {
          'name': _nameController.text,
          'pickup_point': {
            'name': _selectedPickUpPoint!['name'],
            'latitude': _selectedPickUpPoint!['latitude'],
            'longitude': _selectedPickUpPoint!['longitude'],
          },
        },
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Shop registered successfully!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        ); // Navigate to ProfilePage
      } else {
        throw Exception('Failed to register shop');
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
      // Allow user to input a name for the new pick-up point
      String? pointName = await _getPointNameFromUser();
      if (pointName != null) {
        setState(() {
          final newPickUpPoint = {
            'name': pointName,
            'latitude': newPoint.latitude,
            'longitude': newPoint.longitude,
          };
          _availablePickUpPoints.add(newPickUpPoint);
          _selectedPickUpPoint = newPickUpPoint;
        });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ); // Navigate to ProfilePage
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: Text(point['name']), // Display pick-up point name
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
