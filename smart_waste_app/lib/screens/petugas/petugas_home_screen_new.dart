import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'petugas_dashboard_screen.dart';
import 'petugas_task_list_screen.dart';
import 'petugas_statistics_screen.dart';
import 'petugas_profile_screen.dart';

class PetugasHomeScreenNew extends StatefulWidget {
  const PetugasHomeScreenNew({super.key});

  @override
  State<PetugasHomeScreenNew> createState() => _PetugasHomeScreenNewState();
}

class _PetugasHomeScreenNewState extends State<PetugasHomeScreenNew> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PetugasDashboardScreen(),
    const PetugasTaskListScreen(),
    const PetugasStatisticsScreen(),
    const PetugasProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: const Color(0xFF94A3B8),
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: [
                _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Beranda', 0),
                _buildNavItem(Icons.assignment_rounded, Icons.assignment_outlined, 'Tugas', 1),
                _buildNavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Statistik', 2),
                _buildNavItem(Icons.person_rounded, Icons.person_outlined, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData selectedIcon, IconData unselectedIcon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(isSelected ? selectedIcon : unselectedIcon, size: 24),
      ),
      label: label,
    );
  }
}

