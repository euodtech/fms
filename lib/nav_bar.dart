import 'package:flutter/material.dart';
import 'package:fms/page/home/presentation/home_page.dart';
import 'package:fms/page/vehicles/presentation/vehicles_page.dart';
import 'package:fms/page/jobs/presentation/jobs_gate_tab.dart';
import 'package:fms/page/profile/presentation/profile_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _index = 0;

  final _tabs = const [
    HomeTab(),
    VehiclesPage(),
    JobsGateTab(),
    ProfilePage(),
  ];

  final _titles = const [
    'Dashboard',
    'Vehicles',
    'Jobs',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'Vehicles'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}