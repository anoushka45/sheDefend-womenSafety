import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';  // Import geocoding package

class CrimeDashboard extends StatefulWidget {
  const CrimeDashboard({Key? key}) : super(key: key);

  @override
  State<CrimeDashboard> createState() => _CrimeDashboardState();
}

class _CrimeDashboardState extends State<CrimeDashboard> {
  Map<String, Map<String, int>> locationWiseCrimeCount = {};
  List<String> locations = [];
  Position? currentPosition;
  bool isDataLoaded = false;
  bool isLocationLoaded = false;

  // Radius for considering nearby locations (in meters)
  final double proximityRadius = 1000.0; // 1km radius

  @override
  void initState() {
    super.initState();
    _loadCrimeData(); // Load the crime data for analysis
    _getUserLocation(); // Get user's current location
  }

  // Load crime data from the local file asynchronously
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/crime_data.csv';
    final file = File(path);
    return file;
  }

  // Load and analyze crime data from the CSV in the background
  Future<void> _loadCrimeData() async {
    final file = await _getLocalFile();
    final content = await file.readAsString();
    final lines = content.split('\n');

    List<Map<String, dynamic>> crimes = [];

    // Analyze the data to collect crime information
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].isNotEmpty) {
        final values = lines[i].split(',');
        final latitude = double.tryParse(values[1]);
        final longitude = double.tryParse(values[2]);
        final type = values[3];

        if (latitude != null && longitude != null) {
          // Get the location name using geocoding
          String locationName = await _getLocationName(latitude, longitude);

          crimes.add({
            'location': locationName,
            'latitude': latitude,
            'longitude': longitude,
            'type': type,
          });
        }
      }
    }

    // Cluster crimes by proximity in the background
    List<List<Map<String, dynamic>>> clusters = _clusterCrimes(crimes);

    // Update the UI with the clustered data
    setState(() {
      locationWiseCrimeCount.clear();
      locations.clear();

      for (var cluster in clusters) {
        final String clusterLocation = _getClusterCenter(cluster)['location'];
        locationWiseCrimeCount[clusterLocation] = {};

        for (var crime in cluster) {
          final type = crime['type'];
          if (locationWiseCrimeCount[clusterLocation]!.containsKey(type)) {
            locationWiseCrimeCount[clusterLocation]![type] =
                locationWiseCrimeCount[clusterLocation]![type]! + 1;
          } else {
            locationWiseCrimeCount[clusterLocation]![type] = 1;
          }
        }

        locations.add(clusterLocation);
      }

      isDataLoaded = true;
    });
  }

  // Get location name from coordinates using geocoding
  Future<String> _getLocationName(double latitude, double longitude) async {
    try {
      // Get the placemark for the coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      Placemark placemark = placemarks.first;

      // Return the locality or a fallback string if not available
      return placemark.locality ?? 'Unknown Location';
    } catch (e) {
      print("Error in geocoding: $e");
      return 'Unknown Location'; // Default if geocoding fails
    }
  }

  // Get user's current location
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permission permanently denied.');
      return;
    }

    // Get the current position with high accuracy
    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      isLocationLoaded = true;
    });
  }

  // Optimized clustering: Group crimes by proximity
  List<List<Map<String, dynamic>>> _clusterCrimes(List<Map<String, dynamic>> crimes) {
    List<List<Map<String, dynamic>>> clusters = [];

    for (var crime in crimes) {
      bool addedToCluster = false;

      for (var cluster in clusters) {
        final clusterCenter = _getClusterCenter(cluster);
        final distance = _calculateDistance(
          crime['latitude'],
          crime['longitude'],
          clusterCenter['latitude']!,
          clusterCenter['longitude']!,
        );

        if (distance <= proximityRadius) {
          cluster.add(crime);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        clusters.add([crime]);
      }
    }

    return clusters;
  }

  // Calculate distance between two geographic points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Get the center point of a cluster
  Map<String, dynamic> _getClusterCenter(List<Map<String, dynamic>> cluster) {
    double totalLat = 0;
    double totalLon = 0;

    // Loop through the crimes in the cluster to calculate the average latitude and longitude
    for (var crime in cluster) {
      totalLat += crime['latitude'];
      totalLon += crime['longitude'];
    }

    // Calculate the average coordinates for the cluster center
    double avgLat = totalLat / cluster.length;
    double avgLon = totalLon / cluster.length;

    // Get the location name from the first crime (or any other crime in the cluster)
    String clusterLocation = cluster[0]['location'];

    return {
      'latitude': avgLat,
      'longitude': avgLon,
      'location': clusterLocation,  // Use the location name of the first crime
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crime Dashboard"),
      ),
      body: !isDataLoaded || !isLocationLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                final crimeTypes = locationWiseCrimeCount[location]!;

                // Prepare data for PieChart
                Map<String, double> pieChartData = {};
                crimeTypes.forEach((type, count) {
                  pieChartData[type] = count.toDouble();
                });

                // Color list for the pie chart
                List<Color> colorList = [
                  Colors.blue,
                  Colors.green,
                  Colors.red,
                  Colors.orange,
                  Colors.purple,
                ];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location: $location', // Display the location name here
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Pie chart for crime data at this location
                        PieChart(
                          dataMap: pieChartData,
                          animationDuration: Duration(milliseconds: 800),
                          chartLegendSpacing: 32,
                          chartRadius: MediaQuery.of(context).size.width / 3.2,
                          colorList: colorList,
                          initialAngleInDegree: 0,
                          chartType: ChartType.ring,
                          ringStrokeWidth: 32,
                          centerText: "Crimes",
                          legendOptions: LegendOptions(
                            showLegendsInRow: false,
                            legendPosition: LegendPosition.right,
                            showLegends: true,
                            legendTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValueBackground: true,
                            showChartValues: true,
                            showChartValuesInPercentage: false,
                            showChartValuesOutside: false,
                            decimalPlaces: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
