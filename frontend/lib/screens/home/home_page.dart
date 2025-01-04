import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:convert';
import '../shop/shop_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _isMapView = true;
  late Future<List<Map<String, dynamic>>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _requestAndSetLocation();
    _shopsFuture = _fetchShops();
  }

  Future<void> _requestAndSetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are denied.")),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions are permanently denied."),
          ),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchShops() async {
    try {
      final response = await ApiService.authenticatedGetRequest('shops');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch shops.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      return [];
    }
  }

  void _moveToCurrentLocation() {
    if (_mapController == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Map is not ready or location is unavailable.")),
      );
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, 14.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.toggle_off),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
        ],
      ),
      body: _isMapView
          ? _buildMapView()
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _shopsFuture,
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

                final shops = snapshot.data ?? [];
                return _buildTileView(shops);
              },
            ),
    );
  }

  Widget _buildMapView() {
    return _currentPosition == null
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          );
  }

  Widget _buildTileView(List<Map<String, dynamic>> shops) {
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.0,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return GestureDetector(
          onTap: () => _showShopDetails(context, shop),
          child: Card(
            child: Center(
              child: Text(
                shop['name'] ?? 'Shop',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showShopDetails(BuildContext context, Map<String, dynamic> shop) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(shop['name']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Pickup Point: ${shop['pickup_point']['name']}"),
              Text("Address: ${shop['pickup_point']['address']}"),
              Text("Seller Email: ${shop['seller']['email']}"),
              Text(
                  "Seller Name: ${shop['seller']['first_name']} ${shop['seller']['last_name']}"),
              Text("Seller Phone: ${shop['seller']['phone']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopDetailsPage(
                      shopId: shop['id'],
                      onOrderCreated: (orderId) {
                        // This callback is no longer responsible for navigation
                        print("Order ID created or modified: $orderId");
                      },
                    ),
                  ),
                );
              },
              child: const Text("Go to Shop"),
            ),
          ],
        );
      },
    );
  }
}
