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

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return null;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng?>(
      future: _getCurrentLocation(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Select Pick-Up Point"),
          ),
          body: GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: snapshot.data!,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a location")),
                );
              }
            },
            child: const Icon(Icons.check),
          ),
        );
      },
    );
  }
}
