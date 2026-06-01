import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../services/petugas_task_service.dart';

class PetugasTaskListScreen extends StatefulWidget {
  const PetugasTaskListScreen({super.key});

  @override
  State<PetugasTaskListScreen> createState() => _PetugasTaskListScreenState();
}

class _PetugasTaskListScreenState extends State<PetugasTaskListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedFilter = 'semua';
  String _currentOfficerId = '';
  bool _isResolvingOfficer = true;
  final PetugasTaskService _taskService = PetugasTaskService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
      _currentOfficerId = officerId;
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header with Gradient
              FadeTransition(
                opacity: CurvedAnimation(parent: _animationController, curve: const Interval(0, 0.4)),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderButton(
                        Icons.arrow_back_ios_new_rounded,
                        () => Navigator.pop(context),
                      ),
                      const Text(
                        'Daftar Tugas Anda',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      _buildHeaderButton(Icons.tune_rounded, () {}),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Chips
                    _buildFilters(),

                    const SizedBox(height: 24),

                    // Task List with Real-time Firestore
                    if (_isResolvingOfficer)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    else if (_currentOfficerId.isEmpty)
                      _buildEmptyState('Akun petugas belum terhubung')
                    else
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _selectedFilter == 'semua'
                            ? _taskService.getAssignedTasks(_currentOfficerId)
                            : _taskService.getTasksByStatus(
                                _currentOfficerId,
                                _selectedFilter,
                              ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState(
                              'Tidak ada tugas sesuai jadwal aktif',
                            );
                          }

                          final tasks = snapshot.data!;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final delay = (index * 0.1).clamp(0.0, 0.4);
                              final animation = CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  0.3 + delay > 1.0 ? 1.0 : 0.3 + delay,
                                  0.7 + delay > 1.0 ? 1.0 : 0.7 + delay,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(
                                    Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ),
                                  ),
                                  child: _TaskCard(task: tasks[index]),
                                ),
                              );
                            },
                          );
                        },
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

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
    );
  }

  Widget _buildFilters() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.6)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua',
              isSelected: _selectedFilter == 'semua',
              onTap: () => setState(() => _selectedFilter = 'semua'),
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'Disetujui',
              isSelected: _selectedFilter == 'accepted',
              onTap: () => setState(() => _selectedFilter = 'accepted'),
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'In Progress',
              isSelected: _selectedFilter == 'in_progress',
              onTap: () => setState(() => _selectedFilter = 'in_progress'),
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'Tiba di Lokasi',
              isSelected: _selectedFilter == 'arrived',
              onTap: () => setState(() => _selectedFilter = 'arrived'),
            ),
            const SizedBox(width: 12),
            _FilterChip(
              label: 'Selesai',
              isSelected: _selectedFilter == 'completed',
              onTap: () => setState(() => _selectedFilter = 'completed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final Map<String, dynamic> task;

  const _TaskCard({required this.task});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    final status = widget.task['status'] as String? ?? 'pending';
    switch (status) {
      case 'pending':
      case 'accepted':
        return const Color(0xFFF59E0B);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'arrived':
        return const Color(0xFF8B5CF6);
      case 'completed':
        return AppColors.primary;
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return AppColors.grey;
    }
  }

  String _getStatusLabel() {
    final status = widget.task['status'] as String? ?? 'pending';
    switch (status) {
      case 'pending':
      case 'accepted':
        return 'Disetujui';
      case 'in_progress':
        return 'In Progress';
      case 'arrived':
        return 'Tiba di Lokasi';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      onTap: () => Navigator.pushNamed(context, '/task_detail', arguments: widget.task),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 20,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusLabel(),
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    (widget.task['schedule_date_text'] ?? '').toString().isNotEmpty
                        ? widget.task['schedule_date_text']
                        : widget.task['distance'] ?? '-',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.task['waste_type'] ??
                    widget.task['wasteType'] ??
                    'Sampah',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              if ((widget.task['schedule_route'] ?? '').toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.task['schedule_route'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.task['address'] ??
                          widget.task['location'] ??
                          'Lokasi tidak tersedia',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.task['schedule_time'] ??
                            widget.task['estimated_arrival_time'] ??
                            '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/task_detail', arguments: widget.task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Detail',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
