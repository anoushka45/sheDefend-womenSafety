import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Make sure to import this package

import '../widgets/cards.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  void _showSafetyTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Safety Tips for Women'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('1. Always be aware of your surroundings.'),
                Text('2. Trust your instincts; if something feels wrong, it probably is.'),
                Text('3. Use your phone for emergency calls and alerts.'),
                Text('4. Share your location with a trusted friend or family member.'),
                Text('5. Take self-defense classes to empower yourself.'),
                Text('6. Always keep your belongings close and secure.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSelfDefenseTechniquesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Self Defense Techniques for Women'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Learn essential self-defense techniques to empower yourself and stay safe.'),
                SizedBox(height: 10),
                TextButton(
                  child: Text('Basic Self Defense Moves'),
                  onPressed: () {
                    _launchURL('https://youtube.com/shorts/z8T29GYPlVM?si=UHYx-gJqScz65_Iy'); // Replace with actual URL
                  },
                ),
                TextButton(
                  child: Text('Advanced Techniques'),
                  onPressed: () {
                    _launchURL('https://youtube.com/shorts/z8T29GYPlVM?si=UHYx-gJqScz65_Iy'); // Replace with actual URL
                  },
                ),
                TextButton(
                  child: Text('Self Defense in Real Situations'),
                  onPressed: () {
                    _launchURL('https://youtube.com/shorts/z8T29GYPlVM?si=UHYx-gJqScz65_Iy'); // Replace with actual URL
                  },
                ),
                TextButton(
                  child: Text('Using Everyday Items as Defense'),
                  onPressed: () {
                    _launchURL('https://youtube.com/shorts/z8T29GYPlVM?si=UHYx-gJqScz65_Iy'); // Replace with actual URL
                  },
                ),
                TextButton(
                  child: Text('Self Defense for Women'),
                  onPressed: () {
                    _launchURL('https://youtube.com/shorts/z8T29GYPlVM?si=UHYx-gJqScz65_Iy'); // Replace with actual URL
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: CardWithBackgroundImage(
                description: "safe women",
                imagePath: "assets/images/banner.png",
                title: 'Safety Tips',
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 50,
                    width: 50,
                    child: ToolsCard(
                      imageurl: 'assets/images/Group 70.png',
                      title: "Report Crime",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => _showSafetyTipsDialog(context), // Trigger the safety tips dialog
                    child: Container(
                      height: 50,
                      width: 50,
                      child: ToolsCard(
                        imageurl: 'assets/images/Pin.png',
                        title: "Safety Tips",
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 50,
                    width: 50,
                    child: ToolsCard(
                      imageurl: 'assets/images/Group 75.png',
                      title: "Defense Tools",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => _showSelfDefenseTechniquesDialog(context), // Trigger the self-defense dialog
                    child: Container(
                      height: 50,
                      width: 50,
                      child: ToolsCard(
                        imageurl: 'assets/images/Courage.png',
                        title: "Self Defense Techniques",
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 50,
                    width: 50,
                    child: ToolsCard(
                      imageurl: 'assets/images/Siren.png',
                      title: "Emergency",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 50,
                    width: 50,
                    child: ToolsCard(
                      imageurl: 'assets/images/Wearable Technology.png',
                      title: "Link Watch",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget getWidget(Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 50,
        width: 50,
        color: Colors.white,
        child: Icon(
          icon,
          size: 80,
        ),
      ),
    );
  }
}
