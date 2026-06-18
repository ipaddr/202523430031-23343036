import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../utils/constants.dart';
import '../../utils/auth_provider.dart';
import '../../services/petugas_task_service.dart';

class PetugasDashboardScreen extends StatefulWidget {
  const PetugasDashboardScreen({super.key});

  @override
  State<PetugasDashboardScreen> createState() => _PetugasDashboardScreenState();
}

class _PetugasDashboardScreenState extends State<PetugasDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _staggeredAnimations;
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

    _staggeredAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            (0.5 + ((index * 0.1).clamp(0.0, 1.0))).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
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
    final user = Provider.of<AuthProvider>(context).user;

    if (_isResolvingOfficer || _officerId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Gradient and Animation
              FadeTransition(
                opacity: _staggeredAnimations[0],
                child: SlideTransition(
                  position: _staggeredAnimations[0].drive(
                    Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.lg,
                      vertical: AppPadding.lg,
                    ),
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
                                  'Halo, ${user?.name ?? 'Petugas'}! 👷',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Semangat menjaga kebersihan hari ini!',
                                  style: TextStyle(
                                    color: Color(0xFFD0E8D8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            _buildNotificationIcon(),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _taskService.getAssignedTasks(_officerId!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppPadding.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppPadding.lg),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Gagal Memuat Tugas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final tasks = snapshot.data ?? [];
                  return Padding(
                    padding: const EdgeInsets.all(AppPadding.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Grid - Penanganan Hari Ini
                        _buildSectionHeader(
                          'Penanganan Hari Ini',
                          _staggeredAnimations[1],
                        ),
                        const SizedBox(height: AppPadding.lg),
                        _buildStatsGrid(tasks),

                        const SizedBox(height: AppPadding.xl),

                        // Progress Penyelesaian
                        _buildSectionHeader(
                          'Progress Penyelesaian',
                          _staggeredAnimations[3],
                        ),
                        const SizedBox(height: AppPadding.lg),
                        _buildProgressCard(tasks),

                        const SizedBox(height: AppPadding.xl),

                        // Tugas Berikutnya
                        _buildSectionHeader(
                          'Tugas Berikutnya',
                          _staggeredAnimations[5],
                        ),
                        const SizedBox(height: AppPadding.lg),
                        _buildNextTaskCard(tasks),

                        const SizedBox(height: AppPadding.xl),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.white,
            size: 26,
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<Map<String, dynamic>> tasks) {
    final accepted = tasks.where((t) => t['status'] == 'accepted').length;
    final inProgress = tasks
        .where((t) => t['status'] == 'in_progress' || t['status'] == 'arrived')
        .length;
    final completed = tasks.where((t) => t['status'] == 'completed').length;
    double totalWeight = 0;
    for (var task in tasks) {
      if (task['status'] == 'completed' && task['actual_weight'] != null) {
        totalWeight += (task['actual_weight'] as num).toDouble();
      }
    }
    final weightStr = totalWeight >= 1000
        ? '${(totalWeight / 1000).toStringAsFixed(1)}T'
        : '${totalWeight.toInt()}kg';

    return FadeTransition(
      opacity: _staggeredAnimations[2],
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _StatCard(
            icon: Icons.assignment_rounded,
            color: const Color(0xFF3B82F6),
            label: 'Tugas Masuk',
            value: '$accepted',
            delay: 0.1,
          ),
          _StatCard(
            icon: Icons.check_circle_rounded,
            color: AppColors.primary,
            label: 'Tugas Selesai',
            value: '$completed',
            delay: 0.2,
          ),
          _StatCard(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFF59E0B),
            label: 'Dalam Proses',
            value: '$inProgress',
            delay: 0.3,
          ),
          _StatCard(
            icon: Icons.auto_delete_rounded,
            color: const Color(0xFFEF4444),
            label: 'Total Sampah',
            value: weightStr,
            delay: 0.4,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(List<Map<String, dynamic>> tasks) {
    final total = tasks.length;
    final completed = tasks.where((t) => t['status'] == 'completed').length;
    final progress = total > 0 ? completed / total : 0.0;
    final percentStr = '${(progress * 100).toInt()}%';

    return FadeTransition(
      opacity: _staggeredAnimations[4],
      child: SlideTransition(
        position: _staggeredAnimations[4].drive(
          Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppPadding.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF114216)],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completed dari $total tugas selesai',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      percentStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                total == 0
                    ? 'Belum ada tugas yang ditugaskan.'
                    : progress >= 1.0
                    ? 'Semua tugas selesai! Kerja bagus! 🎉'
                    : 'Hampir mencapai target hari ini! Ayo tuntaskan sisanya. 💪',
                style: const TextStyle(
                  color: Color(0xFFD0E8D8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextTaskCard(List<Map<String, dynamic>> tasks) {
    final nextTask =
        tasks
            .where(
              (t) =>
                  t['status'] == 'accepted' ||
                  t['status'] == 'in_progress' ||
                  t['status'] == 'arrived',
            )
            .isNotEmpty
        ? tasks.firstWhere(
            (t) =>
                t['status'] == 'accepted' ||
                t['status'] == 'in_progress' ||
                t['status'] == 'arrived',
          )
        : null;

    if (nextTask == null) {
      return FadeTransition(
        opacity: _staggeredAnimations[5],
        child: Container(
          padding: const EdgeInsets.all(AppPadding.xl),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 12),
                Text(
                  'Tidak ada tugas aktif saat ini',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final wasteType =
        (nextTask['schedule_category'] ??
                nextTask['waste_type'] ??
                nextTask['wasteType'] ??
                'Sampah')
            .toString();
    final address = (nextTask['address'] ?? nextTask['location'] ?? '')
        .toString();
    final time = (nextTask['schedule_time'] ?? '').toString();

    return FadeTransition(
      opacity: _staggeredAnimations[5],
      child: SlideTransition(
        position: _staggeredAnimations[5].drive(
          Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppPadding.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: () =>
                Navigator.pushNamed(context, '/task_detail', arguments: nextTask),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: AppPadding.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wasteType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final double delay;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.delay = 0,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(AppPadding.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.06),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.2),
                      widget.color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
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
