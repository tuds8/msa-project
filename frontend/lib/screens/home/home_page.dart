import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart'; // Assuming ApiService is already implemented

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _requestAndSetLocation();
  }

  Future<void> _requestAndSetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location permissions are permanently denied."),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14.0),
      );
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  Future<void> _savePickUpPoint() async {
    if (_selectedPosition != null) {
      try {
        await ApiService.postRequest(
          'save-pickup-point',
          {
            'latitude': _selectedPosition!.latitude,
            'longitude': _selectedPosition!.longitude,
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location saved: ${_selectedPosition!.latitude}, ${_selectedPosition!.longitude}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save location: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No location selected!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePickUpPoint, // Save the selected point
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation, // Move camera to current location
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 14.0,
              ),
              markers: _selectedPosition != null
                  ? {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: _selectedPosition!,
                      ),
                    }
                  : {},
              onTap: _onMapTapped, // Handle map taps
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            ),
    );
  }
}
