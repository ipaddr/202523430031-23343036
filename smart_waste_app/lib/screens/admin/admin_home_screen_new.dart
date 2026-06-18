import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'admin_dashboard_screen.dart';
import 'admin_request_list_screen_new.dart';
import 'admin_users_screen.dart';
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
    const AdminUsersScreen(),
    const AdminWasteDataScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _tabs[_selectedTabIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: BottomNavigationBar(
              currentIndex: _selectedTabIndex,
              onTap: (index) => setState(() => _selectedTabIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: const Color(0xFF94A3B8),
              iconSize: 22,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              items: [
                _buildNavItem(
                  Icons.dashboard_rounded,
                  Icons.dashboard_outlined,
                  'Dashboard',
                  0,
                ),
                _buildNavItem(
                  Icons.assignment_rounded,
                  Icons.assignment_outlined,
                  'Request',
                  1,
                ),
                _buildNavItem(
                  Icons.people_rounded,
                  Icons.people_outlined,
                  'Pengguna',
                  2,
                ),
                _buildNavItem(
                  Icons.delete_rounded,
                  Icons.delete_outline,
                  'Sampah',
                  3,
                ),
                _buildNavItem(
                  Icons.more_horiz_rounded,
                  Icons.more_horiz_outlined,
                  'Lainnya',
                  4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    int index,
  ) {
    bool isSelected = _selectedTabIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(isSelected ? selectedIcon : unselectedIcon, size: 22),
      ),
      label: label,
    );
  }
}
