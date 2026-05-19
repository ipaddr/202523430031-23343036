import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';

class AdminWasteDataScreen extends StatefulWidget {
  const AdminWasteDataScreen({super.key});

  @override
  State<AdminWasteDataScreen> createState() => _AdminWasteDataScreenState();
}

class _AdminWasteDataScreenState extends State<AdminWasteDataScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String selectedTab = 'Kategori';
  final _firestoreService = FirestoreService();

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
                      'Kelola Data Sampah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAddWasteDialog,
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
                    // Tabs
                    Row(
                      children: [
                        _buildTab('Kategori'),
                        const SizedBox(width: AppPadding.md),
                        _buildTab('Jenis'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Content
                    _buildWasteList(),
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

  Widget _buildWasteList() {
    final kind = selectedTab == 'Kategori' ? 'kategori' : 'jenis';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getWasteCategoriesStream(kind: kind),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppPadding.lg),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final items = (snapshot.data ?? []).map(_normalizeWasteItem).toList();

        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppPadding.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'Belum ada data ${selectedTab.toLowerCase()}. Tekan tombol + untuk menambahkan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey),
            ),
          );
        }

        return Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final slideBegin = selectedTab == 'Kategori'
                ? const Offset(0.5, 0)
                : const Offset(-0.5, 0);
            final card = selectedTab == 'Kategori'
                ? _WasteCard(waste: item)
                : _WasteItemCard(item: item);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SlideTransition(
                position: Tween<Offset>(begin: slideBegin, end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(
                          0.4,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                child: card,
              ),
            );
          }),
        );
      },
    );
  }

  Map<String, dynamic> _normalizeWasteItem(Map<String, dynamic> data) {
    final name = (data['name'] ?? 'Sampah').toString();
    final totalWeight = _asDouble(data['total_weight']);
    final percentage = _asInt(data['percentage']);

    return {
      'id': data['id'],
      'name': name,
      'icon': _iconForWaste(name),
      'total': '${totalWeight.toStringAsFixed(1)} kg',
      'percentage': '${percentage.clamp(0, 100)}%',
      'color': _colorForWaste(name),
    };
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  IconData _iconForWaste(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('b3')) return Icons.warning;
    if (lowerName.contains('organik') && !lowerName.contains('anorganik')) {
      return Icons.eco;
    }
    if (lowerName.contains('kertas')) return Icons.description;
    if (lowerName.contains('kaca')) return Icons.local_drink;
    return Icons.recycling;
  }

  Color _colorForWaste(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('b3')) return Colors.red;
    if (lowerName.contains('organik') && !lowerName.contains('anorganik')) {
      return Colors.green;
    }
    if (lowerName.contains('kertas')) return Colors.orange;
    return Colors.blue;
  }

  Future<void> _showAddWasteDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final kind = selectedTab == 'Kategori' ? 'kategori' : 'jenis';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tambah $selectedTab'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama $selectedTab',
                  hintText: 'Contoh: Sampah Organik',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final success = await _firestoreService.createWasteCategory(
                name: name,
                kind: kind,
                description: descriptionController.text.trim(),
              );

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? '$selectedTab berhasil ditambahkan'
                        : 'Gagal menambahkan $selectedTab',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Widget _buildTab(String label) {
    final isActive = selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = label),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (isActive)
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _WasteCard extends StatelessWidget {
  final Map<String, dynamic> waste;

  const _WasteCard({required this.waste});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: waste['color'].withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: waste['color'].withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppPadding.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: waste['color'].withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(waste['icon'], color: waste['color'], size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      waste['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      waste['total'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: waste['color'].withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  waste['percentage'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: waste['color'],
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
              value:
                  double.parse(waste['percentage'].replaceAll('%', '')) / 100,
              minHeight: 8,
              backgroundColor: waste['color'].withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(waste['color']),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _WasteItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppPadding.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item['icon'], color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item['total'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
