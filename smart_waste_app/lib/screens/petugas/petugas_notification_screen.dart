import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PetugasNotificationScreen extends StatefulWidget {
  const PetugasNotificationScreen({super.key});

  @override
  State<PetugasNotificationScreen> createState() =>
      _PetugasNotificationScreenState();
}

class _PetugasNotificationScreenState extends State<PetugasNotificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Tugas Baru Ditugaskan',
      'description':
          'Anda telah ditugaskan untuk Sampah Anorganik di Perumahan Griya Indah.',
      'icon': Icons.assignment_rounded,
      'time': '08:45 AM',
      'isRead': false,
      'type': 'task',
    },
    {
      'id': 2,
      'title': 'Tugas Berhasil Diselesaikan',
      'description':
          'Laporan tugas Sampah Organik telah diterima. Berat: 6.2 kg.',
      'icon': Icons.check_circle_rounded,
      'time': '10:15 AM',
      'isRead': false,
      'type': 'success',
    },
    {
      'id': 3,
      'title': 'Rating Positif Diterima',
      'description':
          'Bpk. Ahmad memberikan rating 5 bintang untuk layanan Anda.',
      'icon': Icons.star_rounded,
      'time': 'Kemarin',
      'isRead': true,
      'type': 'rating',
    },
    {
      'id': 4,
      'title': 'Update Aplikasi',
      'description':
          'SmartWaste versi 2.1 kini tersedia dengan fitur navigasi baru.',
      'icon': Icons.system_update_rounded,
      'time': '2 hari lalu',
      'isRead': true,
      'type': 'info',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.lg,
                  vertical: 12,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildAnimatedItem(_notifications[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.done_all_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem(Map<String, dynamic> notification, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          0.6 + (index * 0.1),
          curve: Curves.easeOut,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  0.6 + (index * 0.1),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
        child: _NotificationCard(notification: notification),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    bool isRead = notification['isRead'];
    Color iconColor = _getIconColor(notification['type']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? const Color(0xFFF1F5F9)
              : AppColors.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(notification['icon'], color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isRead
                              ? const Color(0xFF1E293B)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification['description'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  notification['time'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'task':
        return const Color(0xFF3B82F6);
      case 'success':
        return const Color(0xFF10B981);
      case 'rating':
        return const Color(0xFFF59E0B);
      case 'info':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}
