import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class PickUpPointSelectorPage extends StatefulWidget {
  const PickUpPointSelectorPage({super.key});

  @override
  State<PickUpPointSelectorPage> createState() =>
      _PickUpPointSelectorPageState();
}

class _PickUpPointSelectorPageState extends State<PickUpPointSelectorPage> {
  late GoogleMapController _mapController;
  LatLng? _selectedPoint;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
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

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Pick-Up Point"),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 14.0,
              ),
              markers: _selectedPoint != null
                  ? {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: _selectedPoint!,
                      ),
                    }
                  : {},
              onTap: (LatLng point) {
                setState(() {
                  _selectedPoint = point;
                });
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedPoint != null) {
            Navigator.pop(context, _selectedPoint);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select a location")),
              );
            }
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
