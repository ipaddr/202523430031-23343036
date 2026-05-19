import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  bool get _showLegacyDashboard => false;

  Stream<_AdminDashboardData> _dashboardStream() {
    return FirebaseFirestore.instance
        .collection('pickup_requests')
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = snapshot.docs
              .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
              .toList();
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .get();
          final officersSnapshot = await FirebaseFirestore.instance
              .collection('officers')
              .get();

          final userCount = usersSnapshot.docs
              .where(
                (doc) =>
                    (doc.data()['role'] ?? 'user').toString().toLowerCase() ==
                    'user',
              )
              .length;
          final officerCount = officersSnapshot.docs.length;

          int pending = 0;
          int active = 0;
          int completed = 0;
          int rejected = 0;
          double totalWaste = 0;
          final dailyCounts = List<int>.filled(7, 0);
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);

          for (final request in requests) {
            final status = (request['status'] ?? '').toString().toLowerCase();
            switch (status) {
              case 'completed':
                completed++;
                totalWaste += _requestWeight(request);
                break;
              case 'rejected':
              case 'cancelled':
                rejected++;
                break;
              case 'accepted':
              case 'in_progress':
              case 'arrived':
                active++;
                break;
              default:
                pending++;
            }

            final createdAt = _requestDate(request);
            if (createdAt != null) {
              final dayStart = DateTime(
                createdAt.year,
                createdAt.month,
                createdAt.day,
              );
              final diff = startOfToday.difference(dayStart).inDays;
              if (diff >= 0 && diff < 7) {
                dailyCounts[6 - diff]++;
              }
            }
          }

          final total = requests.length;
          final successRate = total == 0 ? 0.0 : ((completed / total) * 100);

          return _AdminDashboardData(
            totalRequests: total,
            pendingRequests: pending,
            activeRequests: active,
            completedRequests: completed,
            rejectedRequests: rejected,
            totalWaste: totalWaste,
            userCount: userCount,
            officerCount: officerCount,
            successRate: successRate,
            dailyCounts: dailyCounts,
          );
        });
  }

  double _requestWeight(Map<String, dynamic> request) {
    final actualWeight = request['actual_weight'];
    if (actualWeight is num) return actualWeight.toDouble();

    final estimatedWeight = request['estimated_weight'];
    if (estimatedWeight is num) return estimatedWeight.toDouble();

    final rawWeight = request['weight']?.toString() ?? '';
    final match = RegExp(r'[\d]+([.,]\d+)?').firstMatch(rawWeight);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
  }

  DateTime? _requestDate(Map<String, dynamic> request) {
    final rawDate = request['created_at'] ?? request['createdAt'];
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is DateTime) return rawDate;
    return null;
  }

  Widget _buildLiveDashboard() {
    return StreamBuilder<_AdminDashboardData>(
      stream: _dashboardStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final data = snapshot.data ?? const _AdminDashboardData();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik Singkat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.lg),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  data.totalRequests.toString(),
                  'Total Request',
                  const Color(0xFF2196F3),
                ),
                _buildStatCard(
                  data.completedRequests.toString(),
                  'Selesai',
                  AppColors.primary,
                ),
                _buildStatCard(
                  data.pendingRequests.toString(),
                  'Menunggu',
                  AppColors.secondary,
                ),
                _buildStatCard(
                  data.rejectedRequests.toString(),
                  'Ditolak',
                  AppColors.red,
                ),
              ],
            ),
            const SizedBox(height: AppPadding.xl),
            const Text(
              'Penanganan Sampah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.lg),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMainStatCard(
                  '${data.totalWaste.toStringAsFixed(1)} kg',
                  'Total Sampah',
                  Icons.delete,
                  AppColors.primary,
                ),
                _buildMainStatCard(
                  data.officerCount.toString(),
                  'Petugas Aktif',
                  Icons.local_shipping,
                  const Color(0xFF2196F3),
                ),
                _buildMainStatCard(
                  data.userCount.toString(),
                  'Pengguna',
                  Icons.people,
                  const Color(0xFFE91E63),
                ),
                _buildMainStatCard(
                  '${data.successRate.toStringAsFixed(0)}%',
                  'Berhasil',
                  Icons.check_circle,
                  AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppPadding.xl),
            const Text(
              'Grafik Pengajuan Sampah (7 Hari)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppPadding.lg),
            _buildChartCard(data.dailyCounts),
            const SizedBox(height: AppPadding.xl),
          ],
        );
      },
    );
  }

  Widget _buildChartCard(List<int> dailyCounts) {
    final maxCount = dailyCounts.fold<int>(1, (maxValue, value) {
      return value > maxValue ? value : maxValue;
    });
    final labels = _lastSevenDayLabels();

    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(dailyCounts.length, (index) {
            final height = 24 + ((dailyCounts[index] / maxCount) * 120);
            return _buildChartBar(
              labels[index],
              height,
              index.isEven ? AppColors.primary : const Color(0xFF2196F3),
            );
          }),
        ),
      ),
    );
  }

  List<String> _lastSevenDayLabels() {
    const labels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return labels[date.weekday % 7];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
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
                  vertical: AppPadding.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Dashboard Admin 👮',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola sampah dengan efisien',
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
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
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

              // Content
              Padding(
                padding: const EdgeInsets.all(AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLiveDashboard(),
                    if (_showLegacyDashboard) ...[
                      // Statistik Singkat
                      const Text(
                        'Statistik Singkat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppPadding.lg),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            '12',
                            'Pelapor Baru',
                            const Color(0xFF2196F3),
                          ),
                          _buildStatCard('8', 'Dishujudkan', AppColors.primary),
                          _buildStatCard('15', 'Menunggu', AppColors.secondary),
                          _buildStatCard('1', 'Ditolak', AppColors.red),
                        ],
                      ),
                      const SizedBox(height: AppPadding.xl),

                      // Main Stats
                      const Text(
                        'Penanganan Sampah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppPadding.lg),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildMainStatCard(
                            '156.9 kg',
                            'Total Sampah',
                            Icons.delete,
                            AppColors.primary,
                          ),
                          _buildMainStatCard(
                            '23',
                            'Kendaraan',
                            Icons.local_shipping,
                            const Color(0xFF2196F3),
                          ),
                          _buildMainStatCard(
                            '186',
                            'Pengguna',
                            Icons.people,
                            const Color(0xFFE91E63),
                          ),
                          _buildMainStatCard(
                            '95%',
                            'Berhasil',
                            Icons.check_circle,
                            AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPadding.xl),

                      // Chart Title
                      const Text(
                        'Grafik Pengajuan Sampah (Harian)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppPadding.lg),

                      // Chart Card
                      Container(
                        padding: const EdgeInsets.all(AppPadding.lg),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Minggu Ini',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '↑ 12%',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppPadding.lg),
                            SizedBox(
                              height: 180,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildChartBar('Sen', 60, AppColors.primary),
                                  _buildChartBar(
                                    'Sel',
                                    45,
                                    const Color(0xFF2196F3),
                                  ),
                                  _buildChartBar(
                                    'Rab',
                                    75,
                                    AppColors.secondary,
                                  ),
                                  _buildChartBar(
                                    'Kam',
                                    55,
                                    const Color(0xFF9C27B0),
                                  ),
                                  _buildChartBar(
                                    'Jum',
                                    85,
                                    const Color(0xFFE91E63),
                                  ),
                                  _buildChartBar(
                                    'Sab',
                                    65,
                                    const Color(0xFF00BCD4),
                                  ),
                                  _buildChartBar('Min', 90, AppColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppPadding.xl),
                    ],

                    // Menu Manajemen
                    const Text(
                      'Menu Manajemen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppPadding.lg),
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMenuCard(
                          context,
                          'Requests',
                          Icons.assignment,
                          AppColors.primary,
                          '/admin_requests',
                        ),
                        _buildMenuCard(
                          context,
                          'Pengguna',
                          Icons.people,
                          const Color(0xFF2196F3),
                          '/admin_users',
                        ),
                        _buildMenuCard(
                          context,
                          'Petugas',
                          Icons.person_outline,
                          const Color(0xFFE91E63),
                          '/admin_officers',
                        ),
                        _buildMenuCard(
                          context,
                          'Jadwal',
                          Icons.calendar_today,
                          AppColors.secondary,
                          '/admin_schedule',
                        ),
                        _buildMenuCard(
                          context,
                          'Laporan',
                          Icons.bar_chart,
                          const Color(0xFF9C27B0),
                          '/admin_reports',
                        ),
                        _buildMenuCard(
                          context,
                          'Aktivitas',
                          Icons.history,
                          const Color(0xFF00BCD4),
                          '/admin_activity',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppPadding.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, route),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppPadding.md),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.white, size: 24),
          ),
          const SizedBox(height: AppPadding.md),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sm),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.sm),
        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}

class _AdminDashboardData {
  final int totalRequests;
  final int pendingRequests;
  final int activeRequests;
  final int completedRequests;
  final int rejectedRequests;
  final double totalWaste;
  final int userCount;
  final int officerCount;
  final double successRate;
  final List<int> dailyCounts;

  const _AdminDashboardData({
    this.totalRequests = 0,
    this.pendingRequests = 0,
    this.activeRequests = 0,
    this.completedRequests = 0,
    this.rejectedRequests = 0,
    this.totalWaste = 0,
    this.userCount = 0,
    this.officerCount = 0,
    this.successRate = 0,
    this.dailyCounts = const [0, 0, 0, 0, 0, 0, 0],
  });
}
