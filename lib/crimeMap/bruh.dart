import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' as Math;

class CrimeMapTest extends StatefulWidget {
  const CrimeMapTest({super.key});

  @override
  State<CrimeMapTest> createState() => _CrimeMapStateTest();
}

class _CrimeMapStateTest extends State<CrimeMapTest> {
  loc.Location location = loc.Location(); // Declare Location object

  late GoogleMapController mapController;
  LatLng _initialPosition = const LatLng(19.0760, 72.8777); // Initial position (e.g., Mumbai)
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};

  final String googleApiKey = 'AIzaSyCybfgkpxg0hz7NgoB1MDhc3dVGIYsPw4k'; // Replace with your API key

  // Function to get coordinates from address
  Future<LatLng> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      return LatLng(locations[0].latitude, locations[0].longitude);
    } catch (e) {
      print("Error getting lat/lng from address: $e");
      throw e;
    }
  }

  // Function to create polylines using Directions API
  Future<void> _createPolylines(String source, String destination) async {
    try {
      // Get the coordinates for source and destination
      LatLng sourceLatLng = await _getLatLngFromAddress(source);
      LatLng destinationLatLng = await _getLatLngFromAddress(destination);

      // Make a request to the Directions API using http package
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=${sourceLatLng.latitude},${sourceLatLng.longitude}&destination=${destinationLatLng.latitude},${destinationLatLng.longitude}&key=$googleApiKey',
        ),
      );

      // Log the response for debugging
      print("Response data: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          var route = data['routes'][0];
          var points = PolylinePoints().decodePolyline(route['overview_polyline']['points']);

          setState(() {
            polylineCoordinates = points.map((point) => LatLng(point.latitude, point.longitude)).toList();
            _polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ));

            // Adjust the camera to show both source and destination locations
            mapController.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    Math.min(sourceLatLng.latitude, destinationLatLng.latitude),
                    Math.min(sourceLatLng.longitude, destinationLatLng.longitude),
                  ),
                  northeast: LatLng(
                    Math.max(sourceLatLng.latitude, destinationLatLng.latitude),
                    Math.max(sourceLatLng.longitude, destinationLatLng.longitude),
                  ),
                ),
                50,
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No routes found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error creating polyline: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating polyline: $e')),
      );
    }
  }

  // Function to initialize the map controller
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Function to get current location and update the initial position
  Future<void> _getCurrentLocation() async {
    try {
      final userLocation = await location.getLocation();
      setState(() {
        _initialPosition = LatLng(userLocation.latitude!, userLocation.longitude!); // Update initial position with user's location
      });
      mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition)); // Move camera to user's location
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Fetch the current location when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Map Test'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              String source = _sourceController.text.trim();
              String destination = _destinationController.text.trim();
              if (source.isNotEmpty && destination.isNotEmpty) {
                _createPolylines(source, destination);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter both source and destination')),
                );
              }
            },
            child: const Text('Show Route'),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,  // Updated dynamically by current location
                zoom: 10,
              ),
              polylines: _polylines,
              markers: {
                if (polylineCoordinates.isNotEmpty)
                  Marker(markerId: MarkerId('source'), position: polylineCoordinates.first),
                if (polylineCoordinates.isNotEmpty)
                  Marker(markerId: MarkerId('destination'), position: polylineCoordinates.last),
              },
            ),
          ),
        ],
      ),
    );
  }
}
