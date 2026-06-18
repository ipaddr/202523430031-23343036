import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _ReportSummary {
  final int completedRequests;
  final double totalWaste;
  final int weeklyCompleted;
  final int monthlyCompleted;
  final int yearlyCompleted;

  const _ReportSummary({
    this.completedRequests = 0,
    this.totalWaste = 0,
    this.weeklyCompleted = 0,
    this.monthlyCompleted = 0,
    this.yearlyCompleted = 0,
  });
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool get _showLegacyReports => false;

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

  Stream<_ReportSummary> _reportStream() {
    return FirebaseFirestore.instance
        .collection('pickup_requests')
        .snapshots()
        .map((snapshot) {
          int completed = 0;
          int weeklyCompleted = 0;
          int monthlyCompleted = 0;
          int yearlyCompleted = 0;
          double totalWaste = 0;
          final now = DateTime.now();
          final weekStart = now.subtract(const Duration(days: 7));
          final monthStart = DateTime(now.year, now.month, 1);
          final yearStart = DateTime(now.year, 1, 1);

          for (final doc in snapshot.docs) {
            final data = Map<String, dynamic>.from(doc.data() as Map);
            if ((data['status'] ?? '').toString() != 'completed') continue;

            completed++;
            totalWaste += _requestWeight(data);
            final completedAt =
                _requestDate(data['completed_at']) ??
                _requestDate(data['updated_at']) ??
                _requestDate(data['created_at']);

            if (completedAt != null && completedAt.isAfter(weekStart)) {
              weeklyCompleted++;
            }
            if (completedAt != null && completedAt.isAfter(monthStart)) {
              monthlyCompleted++;
            }
            if (completedAt != null && completedAt.isAfter(yearStart)) {
              yearlyCompleted++;
            }
          }

          return _ReportSummary(
            completedRequests: completed,
            totalWaste: totalWaste,
            weeklyCompleted: weeklyCompleted,
            monthlyCompleted: monthlyCompleted,
            yearlyCompleted: yearlyCompleted,
          );
        });
  }

  double _requestWeight(Map<String, dynamic> data) {
    final actualWeight = data['actual_weight'];
    if (actualWeight is num) return actualWeight.toDouble();

    final estimatedWeight = data['estimated_weight'];
    if (estimatedWeight is num) return estimatedWeight.toDouble();

    final match = RegExp(
      r'[\d]+([.,]\d+)?',
    ).firstMatch(data['weight']?.toString() ?? '');
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
  }

  DateTime? _requestDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Widget _buildLiveReports() {
    return StreamBuilder<_ReportSummary>(
      stream: _reportStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final data = snapshot.data ?? const _ReportSummary();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(AppPadding.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0D5A2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Sampah',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data.totalWaste.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.completedRequests} Request Selesai',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Laporan Terbaru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              'Laporan Mingguan',
              '${data.weeklyCompleted} request selesai',
              Icons.document_scanner,
              'LIVE',
              0,
              _animationController,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'Laporan Bulanan',
              '${data.monthlyCompleted} request selesai',
              Icons.file_present,
              'LIVE',
              100,
              _animationController,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'Laporan Tahunan',
              '${data.yearlyCompleted} request selesai',
              Icons.calendar_today,
              'LIVE',
              200,
              _animationController,
            ),
          ],
        );
      },
    );
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
                      'Laporan & Statistik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Laporan saat ini ditampilkan langsung dari database',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.download,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLiveReports(),
                    if (_showLegacyReports) ...[
                      // Total Stats Card
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.0,
                              0.4,
                              curve: Curves.elasticOut,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppPadding.lg),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF0D5A2F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Total Sampah',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '156.8 kg',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '23 Request Selesai',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: AppColors.white,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Reports Title
                      const Text(
                        'Laporan Terbaru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reports List
                      Column(
                        children: [
                          _buildReportCard(
                            'Laporan Mingguan',
                            '12-19 Mei 2024',
                            Icons.document_scanner,
                            'PDF',
                            0,
                            _animationController,
                          ),
                          const SizedBox(height: 12),
                          _buildReportCard(
                            'Laporan Bulanan',
                            '1-31 Mei 2024',
                            Icons.file_present,
                            'PDF',
                            100,
                            _animationController,
                          ),
                          const SizedBox(height: 12),
                          _buildReportCard(
                            'Laporan Tahunan',
                            'Tahun 2024',
                            Icons.calendar_today,
                            'PDF',
                            200,
                            _animationController,
                          ),
                        ],
                      ),
                    ],
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

  Widget _buildReportCard(
    String title,
    String date,
    IconData icon,
    String type,
    int delay,
    AnimationController animationController,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animationController,
              curve: Interval(
                (0.4 + (delay / 1000)).clamp(0.0, 1.0),
                (0.8 + (delay / 1000)).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(AppPadding.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                type,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
