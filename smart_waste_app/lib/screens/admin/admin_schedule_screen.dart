import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late DateTime selectedDate;
  String selectedStatus = 'Semua Status';
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
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

  Widget _buildSchedulesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final scheduleDocs = snapshot.data ?? [];

        if (scheduleDocs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppPadding.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Text(
              'Belum ada jadwal. Tekan tombol + untuk menambahkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
          );
        }

        return Column(
          children: List.generate(scheduleDocs.length, (index) {
            final schedule = _normalizeSchedule(scheduleDocs[index]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.5, 0),
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
                child: _ScheduleCard(schedule: schedule),
              ),
            );
          }),
        );
      },
    );
  }

  Map<String, dynamic> _normalizeSchedule(Map<String, dynamic> data) {
    final category = (data['category'] ?? data['area'] ?? 'Sampah').toString();
    final status = (data['status'] ?? 'Aktif').toString();
    final startTime = (data['start_time'] ?? '').toString();
    final endTime = (data['end_time'] ?? '').toString();
    final time = (data['time'] ?? '$startTime - $endTime').toString();

    return {
      'area': category,
      'zone': (data['route'] ?? data['zone'] ?? '-').toString(),
      'time': time,
      'date': _formatDate(data['date']),
      'status': status,
      'color': _colorForSchedule(category, status),
    };
  }

  Color _colorForSchedule(String category, String status) {
    if (status.toLowerCase().contains('tunda')) return Colors.orange;
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('b3')) return Colors.red;
    if (lowerCategory.contains('organik') &&
        !lowerCategory.contains('anorganik')) {
      return Colors.green;
    }
    return Colors.blue;
  }

  String _formatDate(dynamic rawDate) {
    DateTime? date;
    if (rawDate is Timestamp) date = rawDate.toDate();
    if (rawDate is DateTime) date = rawDate;
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddScheduleDialog() async {
    final routeController = TextEditingController();
    final startController = TextEditingController(text: '07:00');
    final endController = TextEditingController(text: '09:00');
    String selectedCategory = 'Organik';
    String selectedStatus = 'Aktif';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Jadwal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Sampah',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['Organik', 'Anorganik', 'B3', 'Kertas']
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: routeController,
                      decoration: const InputDecoration(
                        labelText: 'Rute / Zona',
                        hintText: 'Contoh: Rute A - Subang',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            decoration: const InputDecoration(
                              labelText: 'Mulai',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            decoration: const InputDecoration(
                              labelText: 'Selesai',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['Aktif', 'Tunda']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final route = routeController.text.trim();
                    if (route.isEmpty) return;

                    final success = await _firestoreService.createSchedule(
                      category: selectedCategory,
                      route: route,
                      startTime: startController.text.trim(),
                      endTime: endController.text.trim(),
                      date: selectedDate,
                      status: selectedStatus,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Jadwal berhasil ditambahkan'
                              : 'Gagal menambahkan jadwal',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    routeController.dispose();
    startController.dispose();
    endController.dispose();
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
                      'Kelola Jadwal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAddScheduleDialog,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add,
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
                    // Calendar
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
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 300,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_left,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => setState(
                                      () => selectedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month - 1,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${selectedDate.month}/${selectedDate.year}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_right,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => setState(
                                      () => selectedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month + 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                      ),
                                  itemCount: 42,
                                  itemBuilder: (context, index) {
                                    int day = index - 5;
                                    if (day < 1 || day > 31) {
                                      return const SizedBox();
                                    }
                                    bool isSelected = day == selectedDate.day;
                                    return GestureDetector(
                                      onTap: () => setState(
                                        () => selectedDate = DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          day,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$day',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.white
                                                  : AppColors.black,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Daftar Jadwal
                    const Text(
                      'Daftar Jadwal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSchedulesList(),
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

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: schedule['color'].withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: schedule['color'].withValues(alpha: 0.08),
            blurRadius: 12,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule['area'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule['zone'],
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: schedule['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  schedule['status'],
                  style: TextStyle(
                    fontSize: 11,
                    color: schedule['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: schedule['color']),
              const SizedBox(width: 8),
              Text(
                schedule['time'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((schedule['date'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.event, size: 16, color: schedule['color']),
                const SizedBox(width: 6),
                Text(
                  schedule['date'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
