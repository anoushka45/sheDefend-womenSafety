import 'package:android_path_provider/android_path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:sheDefend/models/sos.dart';
import 'package:sheDefend/utils/colors.dart';
import 'package:sheDefend/widgets/cards.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart'; // Import the geocoding package

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _location = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = "Location services are disabled.";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = "Location permissions are denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = "Location permissions are permanently denied.";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    // Reverse geocoding to get place name
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first; // Get the first placemark
      setState(() {
        _location = placemark.locality ??
            placemark.name ??
            "Unknown location"; // Use locality or name
      });
    } else {
      setState(() {
        _location = "No location found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Display current location at the top of the screen
                Text(
                  _location,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                //... Existing code (Profile and Safe Location UI)

                const SizedBox(height: 64),
                Text(
                  "sheDefendk",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 30,
                      color: Color(ColorsValue().h1),
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  "Contact Emergency Help",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 30,
                      color: Color(ColorsValue().h1),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // SOS button code
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(400),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: InkWell(
                      splashColor: Colors.black54,
                      onTap: () async {
                        await _sendSosMessage();
                      },
                      child: Ink.image(
                        image: const AssetImage('assets/images/sos_button.png'),
                        height: 205,
                        width: 205,
                        fit: BoxFit.cover,
                        child: const Center(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Press the button to send SOS",
                  style: TextStyle(
                    color: Color(ColorsValue().h5),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),

                // Emergency contacts button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EmergencyContactsPage()),
                    );
                  },
                  child: Text("Set Emergency Contacts"),
                ),
                const SizedBox(height: 20),

                // Police and Women's Helpline buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                        onTap: () {
                          _callNumber("7666816225");
                        },
                        child: HelpLineCards(
                          title: "Police 100",
                          assetImg: "assets/images/police_badge.png",
                          number: "7666816225",
                        )),
                    InkWell(
                        onTap: () {
                          _callNumber("7666816225");
                        },
                        child: HelpLineCards(
                          title: "Women's Helpline",
                          assetImg: "assets/images/girl_badge.png",
                          number: "7666816225",
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendSosMessage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? contacts = prefs.getStringList('emergency_contacts');
    var downloadsPath = await AndroidPathProvider.downloadsPath;
    String message = "SOS! I am in danger and need immediate assistance.";

    if (contacts != null && contacts.isNotEmpty) {
      for (String contact in contacts) {
        SOS().sharePhotoToWhatsApp(contact, message);
      }
    } else {
      print("No emergency contacts set");
    }
  }

  _callNumber(String number) async {
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);
  }
}

class EmergencyContactsPage extends StatefulWidget {
  @override
  _EmergencyContactsPageState createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<String> contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      contacts = prefs.getStringList('emergency_contacts') ?? [];
    });
  }

  Future<void> _saveContacts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('emergency_contacts', contacts);
  }

  _addContact(String contact) {
    if (contacts.length < 3) {
      setState(() {
        contacts.add(contact);
      });
      _saveContacts();
    } else {
      print("Maximum of 3 contacts allowed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Emergency Contacts")),
      body: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(contacts[index]),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      contacts.removeAt(index);
                    });
                    _saveContacts();
                  },
                ),
              );
            },
          ),
          TextField(
            decoration: InputDecoration(hintText: "Add Contact Number"),
            keyboardType: TextInputType.phone,
            onSubmitted: (value) {
              _addContact(value);
            },
          ),
        ],
      ),
    );
  }
}
