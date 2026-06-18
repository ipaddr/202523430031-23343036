import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../utils/constants.dart';
import '../../services/petugas_task_service.dart';

class PetugasStatisticsScreen extends StatefulWidget {
  const PetugasStatisticsScreen({super.key});

  @override
  State<PetugasStatisticsScreen> createState() =>
      _PetugasStatisticsScreenState();
}

class _PetugasStatisticsScreenState extends State<PetugasStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _taskService = PetugasTaskService();
  String? _officerId;
  bool _isResolvingOfficer = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _resolveCurrentOfficerId();
  }

  Future<void> _resolveCurrentOfficerId() async {
    final user = FirebaseAuth.instance.currentUser;
    final officerId = await _taskService.resolveOfficerId(
      authUid: user?.uid ?? '',
      email: user?.email,
    );
    if (!mounted) return;
    setState(() {
      _officerId = officerId;
      _isResolvingOfficer = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolvingOfficer || _officerId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _taskService.getAssignedTasks(_officerId!),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppPadding.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(tasks),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Distribusi Sampah'),
                        const SizedBox(height: 16),
                        _buildWasteBreakdown(tasks),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Kepuasan Pelanggan'),
                        const SizedBox(height: 16),
                        _buildRatingCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
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
            'Statistik Petugas',
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
              Icons.analytics_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Map<String, dynamic>> tasks) {
    final completed = tasks.where((t) => t['status'] == 'completed').length;
    double totalWeight = 0;
    for (var task in tasks) {
      if (task['status'] == 'completed' && task['actual_weight'] != null) {
        totalWeight += (task['actual_weight'] as num).toDouble();
      }
    }
    final weightStr = totalWeight.toStringAsFixed(1);
    final points = totalWeight.toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0D5A2F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Keseluruhan',
            style: TextStyle(
              color: Color(0xFFD0E8D8),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed Tugas Selesai',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryItem(
                'Total Berat',
                '$weightStr kg',
                Icons.fitness_center_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildSummaryItem(
                'Poin Diraih',
                '$points pts',
                Icons.stars_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFD0E8D8), size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Color(0xFFD0E8D8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildWasteBreakdown(List<Map<String, dynamic>> tasks) {
    final completedTasks = tasks
        .where((t) => t['status'] == 'completed')
        .toList();
    final Map<String, double> wasteMap = {};
    double totalWeight = 0;

    for (var task in completedTasks) {
      final type = (task['waste_type'] ?? task['wasteType'] ?? 'Lainnya')
          .toString();
      final weight = task['actual_weight'] != null
          ? (task['actual_weight'] as num).toDouble()
          : 0.0;
      wasteMap[type] = (wasteMap[type] ?? 0) + weight;
      totalWeight += weight;
    }

    if (wasteMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        child: const Center(
          child: Text(
            'Belum ada data distribusi sampah',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];

    final entries = wasteMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          final pct = totalWeight > 0 ? (entry.value / totalWeight) * 100 : 0.0;
          final color = colors[index % colors.length];
          return Padding(
            padding: EdgeInsets.only(top: index > 0 ? 20 : 0),
            child: _buildBreakdownItem(
              entry.key,
              '${entry.value.toStringAsFixed(1)} kg',
              pct,
              color,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String type,
    String weight,
    double percentage,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              type,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              weight,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              height: 8,
              width:
                  (MediaQuery.of(context).size.width - 80) * (percentage / 100),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _taskService.getOfficerRating(_officerId!),
      builder: (context, snapshot) {
        final ratingData =
            snapshot.data ?? {'average_rating': 0.0, 'total_ratings': 0};
        final avgRating =
            (ratingData['average_rating'] as num?)?.toDouble() ?? 0.0;
        final totalRatings = ratingData['total_ratings'] as int? ?? 0;

        if (totalRatings == 0) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 40,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada rating dari pengguna',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Big rating display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '/ 5.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Star display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < avgRating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 28,
                    color: const Color(0xFFF59E0B),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Dari $totalRatings rating pengguna',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        );
      },
    );
  }
}
