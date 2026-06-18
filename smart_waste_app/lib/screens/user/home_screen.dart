import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/tflite_service.dart';
import '../../utils/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme_colors.dart';
import 'schedule_screen.dart';
import 'tracking_screen.dart';
import 'scan_waste_screen.dart';
import 'request_pickup_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'guide_screen.dart';
import 'profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _BerandaScreen(),
    const ScheduleScreen(),
    const TrackingScreen(),
    const ScanWasteScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: _screens),
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
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
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
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Beranda',
                  0,
                ),
                _buildNavItem(
                  Icons.calendar_today,
                  Icons.calendar_today_outlined,
                  'Jadwal',
                  1,
                ),
                _buildNavItem(
                  Icons.location_on_rounded,
                  Icons.location_on_outlined,
                  'Truk',
                  2,
                ),
                _buildNavItem(
                  Icons.qr_code_rounded,
                  Icons.qr_code_2_outlined,
                  'Scan',
                  3,
                ),
                _buildNavItem(
                  Icons.person_rounded,
                  Icons.person_outlined,
                  'Profil',
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
    bool isSelected = _currentIndex == index;
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

class _BerandaScreen extends StatefulWidget {
  const _BerandaScreen();

  @override
  State<_BerandaScreen> createState() => __BerandaScreenState();
}

class __BerandaScreenState extends State<_BerandaScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'User';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF0D5A2F)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.lg,
                  vertical: AppPadding.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hai, $userName! 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Kelola sampah rumah Anda',
                              style: TextStyle(
                                color: Color(0xFFD0E8D8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Next Pickup Card with real data from Firestore
              Padding(
                padding: const EdgeInsets.all(AppPadding.lg),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getSchedulesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final schedules = snapshot.data ?? [];
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    // Find the next upcoming schedule
                    Map<String, dynamic>? nextSchedule;
                    DateTime? nextDate;
                    for (final schedule in schedules) {
                      final status = (schedule['status'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (status != 'aktif' &&
                          status != 'active' &&
                          status.isNotEmpty) {
                        continue;
                      }

                      final rawDate = schedule['date'];
                      DateTime? scheduleDate;
                      if (rawDate is Timestamp) {
                        scheduleDate = rawDate.toDate();
                      } else if (rawDate is DateTime) {
                        scheduleDate = rawDate;
                      }
                      if (scheduleDate == null) continue;

                      final dateOnly = DateTime(
                        scheduleDate.year,
                        scheduleDate.month,
                        scheduleDate.day,
                      );
                      if (dateOnly.isBefore(today)) continue;

                      if (nextDate == null || dateOnly.isBefore(nextDate)) {
                        nextDate = dateOnly;
                        nextSchedule = schedule;
                      }
                    }

                    if (nextSchedule == null) {
                      return Container(
                        padding: const EdgeInsets.all(AppPadding.lg),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.event_busy,
                              color: Color(0xFF222222),
                              size: 40,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jadwal Terdekat',
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Belum ada jadwal',
                                    style: TextStyle(
                                      color: Color(0xFF222222),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final category =
                        (nextSchedule['category'] ??
                                nextSchedule['area'] ??
                                'Sampah')
                            .toString();
                    final time =
                        (nextSchedule['time'] ??
                                '${nextSchedule['start_time'] ?? ''} - ${nextSchedule['end_time'] ?? ''}')
                            .toString();
                    final route =
                        (nextSchedule['route'] ?? nextSchedule['zone'] ?? '')
                            .toString();

                    // Calculate days until schedule
                    final daysUntil = nextDate!.difference(today).inDays;
                    String dateText;
                    if (daysUntil == 0) {
                      dateText = 'Hari ini, ${_formatDateIndo(nextDate)}';
                    } else if (daysUntil == 1) {
                      dateText = 'Besok, ${_formatDateIndo(nextDate)}';
                    } else {
                      dateText = _formatDateIndo(nextDate);
                    }

                    // Progress based on days until
                    final progress = daysUntil == 0
                        ? 0.9
                        : (1.0 - (daysUntil / 7).clamp(0.0, 1.0));

                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppPadding.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jadwal Terdekat',
                                      style: TextStyle(
                                        color: Color(0xFF333333),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Sampah $category',
                                      style: const TextStyle(
                                        color: Color(0xFF222222),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dateText,
                                      style: TextStyle(
                                        color: const Color(
                                          0xFF333333,
                                        ).withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        time,
                                        style: TextStyle(
                                          color: const Color(
                                            0xFF333333,
                                          ).withValues(alpha: 0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    if (route.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        route,
                                        style: TextStyle(
                                          color: const Color(
                                            0xFF333333,
                                          ).withValues(alpha: 0.6),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.recycling,
                                  color: Color(0xFF222222),
                                  size: 50,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.8),
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Features Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fitur Utama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      children: [
                        _MenuCard(
                          icon: Icons.calendar_today,
                          label: 'Jadwal',
                          color: ThemeColors.getStatusInProgressColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScheduleScreen(),
                            ),
                          ),
                        ),
                        _MenuCard(
                          icon: Icons.local_shipping,
                          label: 'Tracking Truk',
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrackingScreen(),
                            ),
                          ),
                        ),
                        _MenuCard(
                          icon: Icons.qr_code_2,
                          label: 'Scan Sampah',
                          color: ThemeColors.getStatusPendingColor(context),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ScanWasteScreen(),
                              ),
                            );
                            // If user confirmed a scan result, navigate to request pickup
                            if (result != null && context.mounted) {
                              final tflite = TFLiteService();
                              final category = tflite.getWasteCategory(
                                result.label?.toString() ?? '',
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RequestPickupScreen(
                                    initialWasteType: category,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        _MenuCard(
                          icon: Icons.shopping_cart,
                          label: 'Request',
                          color: ThemeColors.getStatusArrivedColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RequestPickupScreen(),
                            ),
                          ),
                        ),
                        _MenuCard(
                          icon: Icons.history,
                          label: 'Riwayat',
                          color: ThemeColors.getStatusCompletedColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          ),
                        ),
                        _MenuCard(
                          icon: Icons.bar_chart,
                          label: 'Statistik',
                          color: ThemeColors.getStatusRejectedColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatisticsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Educational Card with enhanced design
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.9),
                        Color(0xFF0D5A2F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppPadding.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Yuk Pilah Sampah! 🌱',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Pelajari cara memilah sampah dengan benar',
                                  style: TextStyle(
                                    color: Color(0xFFD0E8D8),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: 130,
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const GuideScreen(),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                    ),
                                    label: const Text('Pelajari'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.white,
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 40,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateIndo(DateTime date) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hariStr = hari[date.weekday - 1];
    final bulanStr = bulan[date.month - 1];
    return '$hariStr, ${date.day} $bulanStr ${date.year}';
  }
}

class _MenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _animationController.forward();
  }

  void _onTapUp(_) {
    _animationController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.3),
                      widget.color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
