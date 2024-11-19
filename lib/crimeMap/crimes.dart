import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' as Math;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'crime_dashboard.dart';

class CrimeMap extends StatefulWidget {
  const CrimeMap({super.key});

  @override
  State<CrimeMap> createState() => _CrimeMapState();
}

class _CrimeMapState extends State<CrimeMap> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  bool _alertShown = false;
  String? _nearbyCrimeType;

  List<Marker> crimeMarkers = [];
  List<Circle> crimeHotspotCircles = [];
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};

  final String googleApiKey = 'AIzaSyCybfgkpxg0hz7NgoB1MDhc3dVGIYsPw4k';


  @override
  void initState() {
    super.initState();
    _loadCrimeData();
    _getCurrentLocation();
  }

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

void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }


  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/crime_data.csv';
    final file = File(path);

    if (!await file.exists()) {
      final assetData = await rootBundle.loadString('assets/crimes/crime_data.csv');
      await file.writeAsString(assetData);
    }

    return file;
  }

  Future<void> _loadCrimeData() async {
    final file = await _getLocalFile();
    final content = await file.readAsString();

    final lines = content.split('\n');
    final headers = lines[0].split(',');

    setState(() {
      crimeMarkers = [
        for (var i = 1; i < lines.length; i++)
          if (lines[i].isNotEmpty) _createMarkerFromCSV(headers, lines[i])
      ];
      crimeHotspotCircles = _detectHotspots(); // Detect hotspots after loading data
    });
  }

  Marker _createMarkerFromCSV(List<String> headers, String line) {
    final values = line.split(',');
    final id = values[0];
    final latitude = double.parse(values[1]);
    final longitude = double.parse(values[2]);
    final type = values[3];
    final description = values.length > 4 ? values[4] : '';

    return Marker(
      markerId: MarkerId(id),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(title: type, snippet: description),
    );
  }
List<Circle> _detectHotspots() {
  List<Circle> circles = [];
  const double hotspotRadius = 0.1; // Radius in kilometers (100 meters)
  
  // Define a map for crime type colors
  final Map<String, Color> crimeTypeColors = {
    'rape': Colors.red,
    'murder': Colors.red,
    'sexual assault': Colors.red,
    'Acid Attack': Colors.red,
    'theft': Colors.yellow,
    'robbery': Colors.yellow,
    'kidnapping': Colors.yellow,
    // Add more crime types here and their corresponding colors
  };

  List<bool> isProcessed = List.filled(crimeMarkers.length, false); // Track processed markers

  // Iterate through all markers to find clusters
  for (int i = 0; i < crimeMarkers.length; i++) {
    if (isProcessed[i]) continue; // Skip processed markers

    var currentMarker = crimeMarkers[i];
    List<Marker> nearbyCrimes = [];

    // Find nearby crimes within the hotspot radius
    for (int j = 0; j < crimeMarkers.length; j++) {
      var otherMarker = crimeMarkers[j];
      if (i != j && _calculateDistance(currentMarker.position, otherMarker.position) <= hotspotRadius) {
        nearbyCrimes.add(otherMarker);
        isProcessed[j] = true; // Mark as processed
      }
    }

    // Add the current marker to the list of nearby crimes
    nearbyCrimes.add(currentMarker);
    isProcessed[i] = true; // Mark the current marker as processed

    // Only create a circle if there are more than 3 crimes in proximity
    if (nearbyCrimes.length > 3) {
      // Get the most common crime type in the nearby cluster
      String clusterCrimeType = _getMostCommonCrimeType(nearbyCrimes);

      // Use the crime type to determine the color of the cluster
      Color clusterColor = crimeTypeColors[clusterCrimeType] ?? Colors.grey;

      // Create a circle for the cluster with the determined color
      circles.add(Circle(
        circleId: CircleId('hotspot_${circles.length}'),
        center: currentMarker.position,
        radius: 100, // Radius in meters
        fillColor: clusterColor.withOpacity(0.5),
        strokeColor: clusterColor,
        strokeWidth: 2,
      ));
    }
  }

  return circles;
}


// Helper function to get the most common crime type in a cluster
String _getMostCommonCrimeType(List<Marker> nearbyCrimes) {
  Map<String, int> crimeTypeCount = {};

  // Count occurrences of each crime type in the cluster
  for (var marker in nearbyCrimes) {
    String crimeType = marker.infoWindow.title ?? '';  // Assuming infoWindow.title holds crime type
    crimeTypeCount[crimeType] = (crimeTypeCount[crimeType] ?? 0) + 1;
  }

  // Find the crime type with the highest count (dominant crime type)
  String mostCommonCrimeType = crimeTypeCount.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

  return mostCommonCrimeType;
}


// Helper function to get the most common crime type in a cluster



  double _calculateDistance(LatLng start, LatLng end) {
    const double radiusOfEarth = 6371; // Radius of the Earth in kilometers
    double latDifference = _degreesToRadians(end.latitude - start.latitude);
    double lonDifference = _degreesToRadians(end.longitude - start.longitude);

    double a = Math.sin(latDifference / 2) * Math.sin(latDifference / 2) +
        Math.cos(_degreesToRadians(start.latitude)) * Math.cos(_degreesToRadians(end.latitude)) *
        Math.sin(lonDifference / 2) * Math.sin(lonDifference / 2);

    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return radiusOfEarth * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * Math.pi / 180;
  }

  Future<void> _getCurrentLocation() async {
loc.Location location = loc.Location();
loc.LocationData locationData;

    try {
      bool _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await location.requestService();
      }

loc.PermissionStatus _permissionGranted = await location.hasPermission();
      if (_permissionGranted == loc.PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
      }

      if (_permissionGranted == loc.PermissionStatus.granted) {
        locationData = await loc.Location().getLocation();

        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });

        _checkProximityToCrimeSpots();
      }
    } catch (e) {
      print(e);
    }
  }

  void _checkProximityToCrimeSpots() {
    if (_currentLocation == null || _alertShown) return;

    for (var marker in crimeMarkers) {
      double distance = _calculateDistance(_currentLocation!, marker.position);
      if (distance <= 0.2) {
        _nearbyCrimeType = marker.infoWindow.title;
        _showProximityAlert();
        break;
      }
    }
  }

  void _showProximityAlert() {
    setState(() {
      _alertShown = true;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Safety Alert"),
        content: Text(
          "You are within 200 meters of a recent crime location involving $_nearbyCrimeType. Please be cautious.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewCrime(double latitude, double longitude, String crimeType, String? description) async {
    final file = await _getLocalFile();
    final id = DateTime.now().millisecondsSinceEpoch; // Generate a unique ID
    final newRow = '$id,$latitude,$longitude,$crimeType,${description ?? ""}\n';

    await file.writeAsString(newRow, mode: FileMode.append); // Append new row
    _loadCrimeData(); // Reload data to include the new crime
  }

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Crime Map Test"),
      actions: [
        IconButton(
          icon: const Icon(Icons.dashboard),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CrimeDashboard(),
            ));
          },
        ),
      ],
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
          child: _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    mapController.moveCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 16));
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation!,
                    zoom: 16,
                  ),
                  polylines: _polylines,
                  markers: {
                    if (polylineCoordinates.isNotEmpty)
                      Marker(markerId: MarkerId('source'), position: polylineCoordinates.first),
                    if (polylineCoordinates.isNotEmpty)
                      Marker(markerId: MarkerId('destination'), position: polylineCoordinates.last),
                    ...crimeMarkers,
                    _createCurrentLocationMarker(),
                  },
                  circles: Set<Circle>.of(crimeHotspotCircles),
                  onTap: (LatLng tappedLocation) async {
                    await _showAddCrimeDialog(tappedLocation);
                  },
                ),
        ),
      ],
    ),
  );
}


  Marker _createCurrentLocationMarker() {
    return Marker(
      markerId: const MarkerId('current_location'),
      position: _currentLocation!,
      infoWindow: const InfoWindow(title: "Your Location"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }
Future<void> _showAddCrimeDialog(LatLng tappedLocation) async {
  String? crimeType;
  String? description;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Report Crime"),
      content: StatefulBuilder(
        builder: (BuildContext context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                hint: const Text("Select Crime Type"),
                value: crimeType,
                onChanged: (String? newValue) {
                  setState(() {
                    crimeType = newValue;
                  });
                },
                items: <String>[
                  'Rape',
                  'Kidnapping',
                  'Murder',
                  'Sexual Assault',
                  'Acid Attack',
                  'Theft',
                  'Robbery',
                  'Fraud',
                  // Add more crime types here
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              if (crimeType != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'You have selected: $crimeType',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              TextField(
                onChanged: (value) => description = value,
                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (crimeType != null) {
              _addNewCrime(tappedLocation.latitude, tappedLocation.longitude, crimeType!, description);
              Navigator.of(context).pop();
            }
          },
          child: const Text("Submit"),
        ),
      ],
    ),
  );
}


}
