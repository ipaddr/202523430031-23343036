import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'admin_dashboard_screen.dart';
import 'admin_request_list_screen_new.dart';
import 'admin_officers_screen.dart';
import 'admin_waste_data_screen.dart';
import 'admin_settings_screen.dart';

class AdminHomeScreenNew extends StatefulWidget {
  const AdminHomeScreenNew({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreenNew> createState() => _AdminHomeScreenNewState();
}

class _AdminHomeScreenNewState extends State<AdminHomeScreenNew> {
  int _selectedTabIndex = 0;

  final List<Widget> _tabs = [
    const AdminDashboardScreen(),
    const AdminRequestListScreen(),
    const AdminOfficersScreen(),
    const AdminWasteDataScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dasbhord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Request',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pengguna'),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Sampah'),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}
