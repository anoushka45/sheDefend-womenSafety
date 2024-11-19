import 'package:boxicons/boxicons.dart';
import 'package:flutter/material.dart';
import 'package:sheDefend/Home/home.dart';
import 'package:sheDefend/tools/tools.dart';
import 'package:sheDefend/utils/colors.dart';
import 'package:sheDefend/crimeMap/crimes.dart';
import 'package:sheDefend/crimeMap/bruh.dart';
import '../Map/map.dart';
import '../community/community.dart';

class sheDefend extends StatefulWidget {
  @override
  State<sheDefend> createState() => _sheDefendState();
}

class _sheDefendState extends State<sheDefend> {
  List pages = [
    const HomePage(),
    const CrimeMap(),
    const CrimeMapTest(),
    const MapPage(),
    const ToolsPage(),
    const CommunityPage(),
  ];

  var _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Center(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        iconSize: 28,
        selectedItemColor: Color(ColorsValue().secondary),
        items: [
          BottomNavigationBarItem(
            activeIcon: Icon(
              Boxicons.bxs_home,
              color: Color(ColorsValue().secondary),
            ),
            icon: const Icon(
              Boxicons.bx_home,
              color: Colors.grey,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Boxicons.bx_map,
              color: Color(ColorsValue().secondary),
            ),
            icon: const Icon(
              Boxicons.bx_map,
              color: Colors.grey,
            ),
            label: "CrimeMap",
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Boxicons.bx_map,
              color: Color(ColorsValue().secondary),
            ),
            icon: const Icon(
              Boxicons.bx_map,
              color: Colors.grey,
            ),
            label: "CrimeMapTest",
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Boxicons.bxs_map,
              color: Color(ColorsValue().secondary),
            ),
            icon: const Icon(
              Boxicons.bx_map,
              color: Colors.grey,
            ),
            label: "Map",
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Boxicons.bxs_shield,
              color: Color(ColorsValue().secondary),
            ),
            icon: const Icon(
              Boxicons.bx_shield,
              color: Colors.grey,
            ),
            label: "Tools",
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Boxicons.bxs_group,
              color: Color(ColorsValue().secondary),
            ),
            icon: const Icon(
              Boxicons.bx_group,
              color: Colors.grey,
            ),
            label: "Community",
          ),
        ],
        onTap: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
      ),
    ));
  }
}
