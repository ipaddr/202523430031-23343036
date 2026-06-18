import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class PetugasScheduleScreen extends StatefulWidget {
  const PetugasScheduleScreen({super.key});

  @override
  State<PetugasScheduleScreen> createState() => _PetugasScheduleScreenState();
}

class _PetugasScheduleScreenState extends State<PetugasScheduleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getSchedulesStream() {
    return _firestore.collection('schedules').orderBy('date').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final category = (data['category'] ?? data['area'] ?? 'Sampah')
            .toString();
        final startTime = (data['start_time'] ?? '').toString();
        final endTime = (data['end_time'] ?? '').toString();
        final time =
            (data['time'] ??
                    (startTime.isNotEmpty ? '$startTime - $endTime' : '-'))
                .toString();
        final status = (data['status'] ?? 'Aktif').toString();
        final route = (data['route'] ?? data['zone'] ?? '-').toString();

        DateTime? date;
        final rawDate = data['date'];
        if (rawDate is Timestamp) date = rawDate.toDate();

        return {
          'id': doc.id,
          'category': category,
          'route': route,
          'time': time,
          'date': date,
          'status': status,
        };
      }).toList();
    });
  }

  Color _colorForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('b3')) return const Color(0xFFEF4444);
    if (lower.contains('organik') && !lower.contains('anorganik')) {
      return const Color(0xFF22C55E);
    }
    if (lower.contains('anorganik')) return const Color(0xFF3B82F6);
    if (lower.contains('kertas')) return const Color(0xFFF59E0B);
    return AppColors.primary;
  }

  IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('b3')) return Icons.warning_amber_rounded;
    if (lower.contains('organik') && !lower.contains('anorganik')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('anorganik')) return Icons.recycling_rounded;
    if (lower.contains('kertas')) return Icons.article_rounded;
    return Icons.delete_outline_rounded;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _dayName(DateTime? date) {
    if (date == null) return '';
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isUpcoming(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.4),
              ),
              child: Container(
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
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x331B5E20),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.lg,
                  vertical: 24,
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 44),
                    Expanded(
                      child: Text(
                        'Jadwal Penjemputan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 44),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Schedule List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getSchedulesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat jadwal:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final schedules = snapshot.data ?? [];

                  if (schedules.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada jadwal dari admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Jadwal akan muncul di sini setelah admin menambahkannya',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.lg,
                    ),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      final delay = (index * 0.08).clamp(0.0, 0.6);
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.2 + delay,
                            (0.6 + delay).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    0.2 + delay,
                                    (0.6 + delay).clamp(0.0, 1.0),
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ScheduleCard(
                              schedule: schedule,
                              color: _colorForCategory(
                                schedule['category'] as String,
                              ),
                              icon: _iconForCategory(
                                schedule['category'] as String,
                              ),
                              formattedDate: _formatDate(
                                schedule['date'] as DateTime?,
                              ),
                              dayName: _dayName(schedule['date'] as DateTime?),
                              isToday: _isToday(schedule['date'] as DateTime?),
                              isUpcoming: _isUpcoming(
                                schedule['date'] as DateTime?,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final Color color;
  final IconData icon;
  final String formattedDate;
  final String dayName;
  final bool isToday;
  final bool isUpcoming;

  const _ScheduleCard({
    required this.schedule,
    required this.color,
    required this.icon,
    required this.formattedDate,
    required this.dayName,
    required this.isToday,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final status = schedule['status']?.toString() ?? 'Aktif';
    final isActive =
        status.toLowerCase() == 'aktif' || status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date indicator
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isToday ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                if (dayName.isNotEmpty)
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white70 : color,
                    ),
                  ),
                Icon(icon, color: isToday ? Colors.white : color, size: 26),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule['category']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.primary : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if ((schedule['route']?.toString() ?? '-') != '-')
                  Row(
                    children: [
                      Icon(
                        Icons.route_rounded,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          schedule['route']?.toString() ?? '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(
                      schedule['time']?.toString() ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (formattedDate != '-') ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Today / Upcoming indicator
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Hari ini',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          else if (isUpcoming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Akan datang',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
