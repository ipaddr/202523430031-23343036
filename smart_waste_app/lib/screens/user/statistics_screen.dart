import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/auth_provider.dart';
import '../../utils/constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _firestoreService = FirestoreService();
  bool get _showLegacyStatistics => false;

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

  Future<_UserStatisticsData> _loadStatistics(String userId) async {
    final userStats = await _firestoreService.getUserStatistics(userId) ?? {};
    final requests = await _firestoreService.getUserPickupRequests(userId);
    final completedRequests = requests.where(
      (request) => (request['status'] ?? '').toString() == 'completed',
    );

    final weightsByType = <String, double>{};
    for (final request in completedRequests) {
      final type = (request['waste_type'] ?? request['wasteType'] ?? 'Lainnya')
          .toString();
      final weight = _requestWeight(request);
      weightsByType[type] = (weightsByType[type] ?? 0) + weight;
    }

    final totalFromRequests = weightsByType.values.fold<double>(
      0,
      (sum, weight) => sum + weight,
    );
    final storedWaste = _asDouble(userStats['wasteCollected']);
    final totalWaste = storedWaste > 0 ? storedWaste : totalFromRequests;

    final points = _asInt(userStats['points']);
    final breakdown = weightsByType.entries.map((entry) {
      final percentage = totalFromRequests <= 0
          ? 0
          : ((entry.value / totalFromRequests) * 100).round();
      return _WasteStatistic(
        name: entry.key,
        weight: entry.value,
        percentage: percentage.clamp(0, 100).toInt(),
        color: _colorForWasteType(entry.key),
        icon: _iconForWasteType(entry.key),
      );
    }).toList()..sort((a, b) => b.weight.compareTo(a.weight));

    return _UserStatisticsData(
      points: points,
      totalWaste: totalWaste,
      breakdown: breakdown,
    );
  }

  double _requestWeight(Map<String, dynamic> request) {
    final actualWeight = request['actual_weight'];
    if (actualWeight is num) return actualWeight.toDouble();

    final estimatedWeight = request['estimated_weight'];
    if (estimatedWeight is num) return estimatedWeight.toDouble();

    return _parseWeight(request['weight']?.toString() ?? '');
  }

  double _parseWeight(String value) {
    final match = RegExp(r'[\d]+([.,]\d+)?').firstMatch(value);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Color _colorForWasteType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('organik') && !lowerType.contains('anorganik')) {
      return const Color(0xFF4CAF50);
    }
    if (lowerType.contains('b3')) return Colors.red;
    if (lowerType.contains('kertas')) return const Color(0xFFFF9800);
    return const Color(0xFF2196F3);
  }

  String _iconForWasteType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('organik') && !lowerType.contains('anorganik')) {
      return 'O';
    }
    if (lowerType.contains('b3')) return 'B3';
    if (lowerType.contains('kertas')) return 'K';
    return 'A';
  }

  Widget _buildStatisticsFuture() {
    final userId = context.watch<AuthProvider>().user?.id;

    if (userId == null || userId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppPadding.lg),
        child: Text(
          'Silakan login untuk melihat statistik Anda',
          style: TextStyle(color: AppColors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return FutureBuilder<_UserStatisticsData>(
      future: _loadStatistics(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final data = snapshot.data ?? const _UserStatisticsData();
        return _buildStatisticsContent(data);
      },
    );
  }

  Widget _buildStatisticsContent(_UserStatisticsData data) {
    final breakdown = data.breakdown;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
              ),
            ),
            child: Container(
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
              padding: const EdgeInsets.all(AppPadding.xl),
              child: Column(
                children: [
                  const Text(
                    'Total Poin Anda',
                    style: TextStyle(color: AppColors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.points.toString(),
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    padding: const EdgeInsets.all(AppPadding.lg),
                    child: Column(
                      children: [
                        const Text(
                          'Sampah Terkumpul',
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistik Sampah',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (breakdown.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppPadding.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Text(
                    'Belum ada data sampah selesai.',
                    style: TextStyle(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...List.generate(breakdown.length, (index) {
                  final item = breakdown[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < breakdown.length - 1 ? 12 : 0,
                    ),
                    child: _StatisticItem(
                      icon: item.icon,
                      name: item.name,
                      weight: '${item.weight.toStringAsFixed(1)} kg',
                      percentage: item.percentage,
                      color: item.color,
                      delay: 100 + (index * 100),
                      animationController: _animationController,
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
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
                      'Statistik & Poin',
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
                        Icons.bar_chart,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildStatisticsFuture(),
              if (_showLegacyStatistics) ...[
                // Total Points Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.lg,
                  ),
                  child: ScaleTransition(
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
                      padding: const EdgeInsets.all(AppPadding.xl),
                      child: Column(
                        children: [
                          const Text(
                            'Total Poin Anda',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: '1.250',
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: ' 🏆',
                                  style: TextStyle(fontSize: 44),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            padding: const EdgeInsets.all(AppPadding.lg),
                            child: Column(
                              children: [
                                const Text(
                                  'Sampah Terkumpul',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '15.6 Kgs',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Statistics
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistik Sampah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatisticItem(
                        icon: '♻️',
                        name: 'Anorganik',
                        weight: '8 Kgs',
                        percentage: 51,
                        color: const Color(0xFF2196F3),
                        delay: 100,
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 12),
                      _StatisticItem(
                        icon: '🌱',
                        name: 'Organik',
                        weight: '5 Kgs',
                        percentage: 32,
                        color: const Color(0xFF4CAF50),
                        delay: 200,
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 12),
                      _StatisticItem(
                        icon: '⚠️',
                        name: 'B3',
                        weight: '1.6 Kgs',
                        percentage: 10,
                        color: Colors.red,
                        delay: 300,
                        animationController: _animationController,
                      ),
                      const SizedBox(height: 12),
                      _StatisticItem(
                        icon: '📄',
                        name: 'Kertas',
                        weight: '1 Kg',
                        percentage: 7,
                        color: const Color(0xFFFF9800),
                        delay: 400,
                        animationController: _animationController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
              // Reward Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reward Tersedia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RewardItem(
                      icon: Icons.local_offer,
                      name: 'Voucher Belanja',
                      points: 500,
                      available: true,
                      delay: 0,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _RewardItem(
                      icon: Icons.card_giftcard,
                      name: 'Hadiah Langsung',
                      points: 1000,
                      available: false,
                      delay: 100,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _RewardItem(
                      icon: Icons.shopping_bag,
                      name: 'Discount Produk',
                      points: 750,
                      available: true,
                      delay: 200,
                      animationController: _animationController,
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

class _UserStatisticsData {
  final int points;
  final double totalWaste;
  final List<_WasteStatistic> breakdown;

  const _UserStatisticsData({
    this.points = 0,
    this.totalWaste = 0,
    this.breakdown = const [],
  });
}

class _WasteStatistic {
  final String name;
  final double weight;
  final int percentage;
  final Color color;
  final String icon;

  const _WasteStatistic({
    required this.name,
    required this.weight,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class _StatisticItem extends StatelessWidget {
  final String icon;
  final String name;
  final String weight;
  final int percentage;
  final Color color;
  final int delay;
  final AnimationController animationController;

  const _StatisticItem({
    required this.icon,
    required this.name,
    required this.weight,
    required this.percentage,
    required this.color,
    required this.delay,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.5, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animationController,
              curve: Interval(
                0.4 + (delay / 1000),
                0.8 + (delay / 1000),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12),
          ],
        ),
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          weight,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardItem extends StatefulWidget {
  final IconData icon;
  final String name;
  final int points;
  final bool available;
  final int delay;
  final AnimationController animationController;

  const _RewardItem({
    required this.icon,
    required this.name,
    required this.points,
    required this.available,
    required this.delay,
    required this.animationController,
  });

  @override
  State<_RewardItem> createState() => _RewardItemState();
}

class _RewardItemState extends State<_RewardItem>
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
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        widget.icon,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${widget.points} poin',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md,
                  vertical: AppPadding.sm,
                ),
                decoration: BoxDecoration(
                  color: widget.available
                      ? Colors.green.withValues(alpha: 0.15)
                      : AppColors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  widget.available ? 'Klaim' : 'Terkunci',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.available ? Colors.green : AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
