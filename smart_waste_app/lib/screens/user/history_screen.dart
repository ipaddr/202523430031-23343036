import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme_colors.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'tracking_screen.dart';
import 'scan_waste_screen.dart';
import 'request_pickup_screen.dart';
import 'statistics_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedFilter = 'Semua';
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildHistoryList() {
    final userId = context.watch<AuthProvider>().user?.id;

    if (userId == null || userId.isEmpty) {
      return _buildEmptyState('Silakan login untuk melihat riwayat request');
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.streamUserPickupRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final requests = (snapshot.data ?? [])
            .where((request) => _matchesSelectedFilter(request['status']))
            .toList();

        if (requests.isEmpty) {
          return _buildEmptyState('Belum ada riwayat untuk filter ini');
        }

        return Column(
          children: List.generate(requests.length, (index) {
            final request = requests[index];
            final status = (request['status'] ?? 'pending').toString();

            return _HistoryItem(
              date: _formatDate(request['createdAt'] ?? request['created_at']),
              type: (request['waste_type'] ?? request['wasteType'] ?? '-')
                  .toString(),
              volume: _weightText(request),
              status: _statusLabel(status),
              points: _pointsEarned(request),
              statusColor: _statusColor(status),
              delay: index * 100,
              animationController: _animationController,
            );
          }),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.lg),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  bool _matchesSelectedFilter(dynamic rawStatus) {
    final status = (rawStatus ?? '').toString().toLowerCase();
    switch (_selectedFilter) {
      case 'Selesai':
        return status == 'completed';
      case 'Pending':
        return status == 'pending' ||
            status == 'accepted' ||
            status == 'in_progress' ||
            status == 'arrived';
      case 'Dibatalkan':
        return status == 'rejected' || status == 'cancelled';
      default:
        return true;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Selesai';
      case 'accepted':
        return 'Disetujui';
      case 'in_progress':
        return 'Diproses';
      case 'arrived':
        return 'Tiba';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'accepted':
      case 'in_progress':
      case 'arrived':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(dynamic rawTimestamp) {
    DateTime? date;
    if (rawTimestamp is Timestamp) {
      date = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      date = rawTimestamp;
    }

    if (date == null) return '-';

    const monthNames = [
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

    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _weightText(Map<String, dynamic> request) {
    final actualWeight = request['actual_weight'];
    if (actualWeight is num && actualWeight > 0) {
      return '${actualWeight.toStringAsFixed(1)} kg';
    }

    final weight = request['weight'];
    if (weight != null && weight.toString().trim().isNotEmpty) {
      return weight.toString();
    }

    final estimatedWeight = request['estimated_weight'];
    if (estimatedWeight is num && estimatedWeight > 0) {
      return '${estimatedWeight.toStringAsFixed(1)} kg';
    }

    return '-';
  }

  int _pointsEarned(Map<String, dynamic> request) {
    final explicitPoints = request['points_earned'] ?? request['pointsEarned'];
    if (explicitPoints is int) return explicitPoints;
    if (explicitPoints is num) return explicitPoints.toInt();

    if ((request['status'] ?? '').toString().toLowerCase() != 'completed') {
      return 0;
    }

    final actualWeight = request['actual_weight'];
    if (actualWeight is num) return actualWeight.toInt();

    return 0;
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
                      'Riwayat Request',
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
              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Semua', 'Selesai', 'Pending', 'Dibatalkan']
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedFilter = filter);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppPadding.md,
                                  vertical: AppPadding.sm,
                                ),
                                decoration: BoxDecoration(
                                  gradient: _selectedFilter == filter
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary,
                                            Color(0xFF0D5A2F),
                                          ],
                                        )
                                      : null,
                                  color: _selectedFilter == filter
                                      ? null
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                  border: _selectedFilter == filter
                                      ? null
                                      : Border.all(
                                          color: AppColors.lightGrey,
                                          width: 1.5,
                                        ),
                                  boxShadow: _selectedFilter == filter
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: _selectedFilter == filter
                                        ? AppColors.white
                                        : AppColors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // History Items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: _buildHistoryList(),
              ),
              const SizedBox(height: 24),

              // Quick Navigation Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menu Lainnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: [
                        _QuickMenuCard(
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
                        _QuickMenuCard(
                          icon: Icons.local_shipping,
                          label: 'Tracking',
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrackingScreen(),
                            ),
                          ),
                        ),
                        _QuickMenuCard(
                          icon: Icons.qr_code_2,
                          label: 'Scan',
                          color: ThemeColors.getStatusPendingColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanWasteScreen(),
                            ),
                          ),
                        ),
                        _QuickMenuCard(
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
                        _QuickMenuCard(
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
                        _QuickMenuCard(
                          icon: Icons.home,
                          label: 'Beranda',
                          color: AppColors.primary,
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserHomeScreen(),
                            ),
                            (route) => false,
                          ),
                        ),
                      ],
                    ),
                  ],
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

class _QuickMenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickMenuCard> createState() => _QuickMenuCardState();
}

class _QuickMenuCardState extends State<_QuickMenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.1),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 28),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatefulWidget {
  final String date;
  final String type;
  final String volume;
  final String status;
  final int points;
  final Color statusColor;
  final int delay;
  final AnimationController animationController;

  const _HistoryItem({
    required this.date,
    required this.type,
    required this.volume,
    required this.status,
    required this.points,
    required this.statusColor,
    required this.delay,
    required this.animationController,
  });

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
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
                  Text(
                    widget.date,
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.md,
                      vertical: AppPadding.sm,
                    ),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      widget.status,
                      style: TextStyle(
                        color: widget.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.type,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.monitor_weight_outlined,
                        size: 16,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.volume,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (widget.points > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${widget.points}',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
