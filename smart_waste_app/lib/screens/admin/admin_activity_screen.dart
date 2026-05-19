import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminActivityScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const AdminActivityScreen({Key? key}) : super(key: key);

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

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

  Stream<List<Map<String, dynamic>>> _activityStream() {
    return FirebaseFirestore.instance
        .collection('pickup_requests')
        .orderBy('updated_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            return _activityFromRequest(doc.id, data);
          }).toList();
        });
  }

  Map<String, dynamic> _activityFromRequest(
    String requestId,
    Map<String, dynamic> data,
  ) {
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final userName = (data['user_name'] ?? data['name'] ?? 'User').toString();
    final wasteType = (data['waste_type'] ?? data['wasteType'] ?? 'Sampah')
        .toString();

    switch (status) {
      case 'completed':
        return {
          'icon': Icons.assignment_turned_in,
          'title': 'Pengambilan berhasil',
          'detail': '$userName - $wasteType selesai',
          'time': _formatTime(data['completed_at'] ?? data['updated_at']),
          'color': Colors.green,
        };
      case 'accepted':
      case 'in_progress':
      case 'arrived':
        return {
          'icon': Icons.person_add,
          'title': 'Request ditugaskan',
          'detail': '$userName - ${data['officer_name'] ?? 'Petugas'}',
          'time': _formatTime(data['assigned_at'] ?? data['updated_at']),
          'color': Colors.blue,
        };
      case 'rejected':
        return {
          'icon': Icons.cancel,
          'title': 'Request ditolak',
          'detail': '$userName - $wasteType',
          'time': _formatTime(data['rejected_at'] ?? data['updated_at']),
          'color': Colors.red,
        };
      default:
        return {
          'icon': Icons.add,
          'title': 'Request baru masuk',
          'detail': '$userName - $wasteType ($requestId)',
          'time': _formatTime(data['created_at'] ?? data['createdAt']),
          'color': Colors.orange,
        };
    }
  }

  String _formatTime(dynamic rawDate) {
    DateTime? date;
    if (rawDate is Timestamp) date = rawDate.toDate();
    if (rawDate is DateTime) date = rawDate;
    if (date == null) return '-';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dayLabel = dateOnly == today
        ? 'Hari ini'
        : dateOnly == today.subtract(const Duration(days: 1))
        ? 'Kemarin'
        : '${date.day}/${date.month}/${date.year}';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dayLabel, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
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
                  vertical: AppPadding.xl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Text(
                      'Riwayat Aktivitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Activities List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _activityStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(AppPadding.lg),
                        child: Text(
                          'Belum ada aktivitas request.',
                          style: TextStyle(color: AppColors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return Column(
                      children: List.generate(
                        activities.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(-0.5, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(
                                      0.4,
                                      1.0,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                ),
                            child: _ActivityCard(activity: activities[index]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: activity['color'].withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: activity['color'].withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppPadding.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: activity['color'].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(activity['icon'], color: activity['color'], size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['detail'],
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'],
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.grey.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
