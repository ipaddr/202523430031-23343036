import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../utils/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingItem> onboardingItems = [
    OnboardingItem(
      title: 'Selamat Datang di Smart Waste',
      description:
          'Aplikasi pengelolaan sampah yang memudahkan Anda untuk berkontribusi pada lingkungan yang lebih bersih',
      icon: Icons.eco_rounded,
      color: const Color(0xFF1B7A3E),
      backgroundColor: const Color(0xFFE8F5E9),
    ),
    OnboardingItem(
      title: 'Kelola Sampah Anda',
      description:
          'Sebagai pengguna, Anda dapat melaporkan sampah, menjadwalkan pengambilan, dan mendapatkan poin reward',
      icon: Icons.delete_sweep_rounded,
      color: const Color(0xFF0D5A2F),
      backgroundColor: const Color(0xFFC8E6C9),
    ),
    OnboardingItem(
      title: 'Pantau dan Kelola',
      description:
          'Petugas dapat mengelola tugas pengambilan sampah dan melacak progres real-time di lapangan',
      icon: Icons.local_shipping_rounded,
      color: const Color(0xFF1B7A3E),
      backgroundColor: const Color(0xFFA5D6A7),
    ),
    OnboardingItem(
      title: 'Kelola Operasional',
      description:
          'Admin dapat mengelola jadwal, petugas, melihat laporan, dan menganalisis data pengelolaan sampah',
      icon: Icons.admin_panel_settings_rounded,
      color: const Color(0xFF0D5A2F),
      backgroundColor: const Color(0xFF81C784),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSkip() {
    Navigator.of(context).pushReplacementNamed('/login');
    _markOnboardingComplete();
  }

  void _handleNext() {
    if (_currentPage < onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
      _markOnboardingComplete();
    }
  }

  void _markOnboardingComplete() {
    final authProvider = context.read<AuthProvider>();
    authProvider.setOnboardingCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: onboardingItems.length,
            itemBuilder: (context, index) {
              return OnboardingPage(item: onboardingItems[index]);
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppPadding.lg),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Progress Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingItems.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.lightGrey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppPadding.lg),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleSkip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Center(
                              child: Text(
                                'Lewati',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppPadding.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleNext,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(77),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentPage == onboardingItems.length - 1
                                    ? 'Mulai'
                                    : 'Lanjut',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.lg,
          vertical: AppPadding.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: item.backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: item.color.withAlpha(77),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(item.icon, size: 140, color: item.color),
            ),
            const SizedBox(height: 40),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}
