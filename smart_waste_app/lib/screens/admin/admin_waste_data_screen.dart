import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../services/tflite_service.dart';
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
  static const List<Map<String, String>> _defaultCategories = [
    {
      'name': 'Organik',
      'description': 'Sampah mudah terurai seperti tanaman dan sisa makanan',
    },
    {
      'name': 'Anorganik',
      'description': 'Sampah sulit terurai seperti plastik, kaca, dan logam',
    },
  ];

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
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.white),
                      onSelected: (value) {
                        if (value == 'add') {
                          _showAddWasteDialog();
                        } else if (value == 'init') {
                          _showInitializeDataDialog();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'add',
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 20),
                              SizedBox(width: 8),
                              Text('Tambah Data'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'init',
                          child: Row(
                            children: [
                              Icon(Icons.cloud_download, size: 20),
                              SizedBox(width: 8),
                              Text('Inisialisasi Data Default'),
                            ],
                          ),
                        ),
                      ],
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

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppPadding.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat data:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
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
      'description': (data['description'] ?? '').toString(),
      'category': (data['category'] ?? '').toString(),
      'modelLabel': (data['model_label'] ?? '').toString(),
      'points': _asInt(data['points']),
      'isTfliteLabel': data['is_tflite_label'] == true,
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
    if (lowerName.contains('plastic') || lowerName.contains('plastik')) {
      return Icons.local_drink;
    }
    if (lowerName.contains('metal') || lowerName.contains('logam')) {
      return Icons.build_circle;
    }
    if (lowerName.contains('textile') || lowerName.contains('tekstil')) {
      return Icons.checkroom;
    }
    if (lowerName.contains('food') || lowerName.contains('vegetation')) {
      return Icons.eco;
    }
    if (lowerName.contains('organik') && !lowerName.contains('anorganik')) {
      return Icons.eco;
    }
    if (lowerName.contains('paper') ||
        lowerName.contains('cardboard') ||
        lowerName.contains('kertas')) {
      return Icons.description;
    }
    if (lowerName.contains('glass') || lowerName.contains('kaca')) {
      return Icons.wine_bar;
    }
    return Icons.recycling;
  }

  Color _colorForWaste(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('b3')) return Colors.red;
    if (lowerName.contains('plastic') || lowerName.contains('plastik')) {
      return Colors.blue;
    }
    if (lowerName.contains('metal') || lowerName.contains('logam')) {
      return Colors.blueGrey;
    }
    if (lowerName.contains('glass') || lowerName.contains('kaca')) {
      return Colors.cyan;
    }
    if (lowerName.contains('textile') || lowerName.contains('tekstil')) {
      return Colors.purple;
    }
    if (lowerName.contains('food') || lowerName.contains('vegetation')) {
      return Colors.green;
    }
    if (lowerName.contains('organik') && !lowerName.contains('anorganik')) {
      return Colors.green;
    }
    if (lowerName.contains('paper') ||
        lowerName.contains('cardboard') ||
        lowerName.contains('kertas')) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  Future<void> _showAddWasteDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    final kind = selectedTab == 'Kategori' ? 'kategori' : 'jenis';
    String selectedCategory = kind == 'kategori' ? '' : 'Anorganik';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text('Tambah $selectedTab'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama $selectedTab',
                          hintText: kind == 'kategori'
                              ? 'Contoh: Organic'
                              : 'Contoh: Tisu',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (kind == 'jenis') ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          items: const ['Organik', 'Anorganik']
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
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Poin',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                    onPressed: () {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      try {
                        final success = await _firestoreService
                            .createWasteCategory(
                              name: name,
                              kind: kind,
                              description: descriptionController.text.trim(),
                              category: kind == 'jenis' ? selectedCategory : '',
                              points: kind == 'jenis'
                                  ? _asInt(pointsController.text.trim())
                                  : 0,
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
                            backgroundColor: success
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      } catch (e) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      pointsController.dispose();
    }
  }

  Future<void> _showInitializeDataDialog() async {
    final tfliteWastes = await _loadTfliteWasteDefaults();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Inisialisasi Data Default'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tambahkan kategori dan jenis sampah sesuai assets/labels.txt dan model TFLite?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...tfliteWastes.map((waste) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '- ${waste['name']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                // Show progress dialog
                if (!mounted) return;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Menambahkan data...'),
                      ],
                    ),
                  ),
                );

                try {
                  int successCount = 0;
                  for (final category in _defaultCategories) {
                    final success = await _firestoreService.createWasteCategory(
                      name: category['name']!,
                      kind: 'kategori',
                      description: category['description']!,
                    );
                    if (success) successCount++;
                  }

                  for (final waste in tfliteWastes) {
                    final success = await _firestoreService.createWasteCategory(
                      name: waste['name']!,
                      kind: 'jenis',
                      description: waste['description']!,
                      category: waste['category']!,
                      modelLabel: waste['modelLabel']!,
                      points: int.tryParse(waste['points']!) ?? 0,
                      isTfliteLabel: true,
                    );
                    if (success) successCount++;
                  }

                  // Pop loading dialog
                  if (mounted) {
                    Navigator.pop(context);
                  }

                  // Show result
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Berhasil menyinkronkan $successCount data sampah',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Tambahkan'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing dialog: $e');
    }
  }

  Future<List<Map<String, String>>> _loadTfliteWasteDefaults() async {
    final labelsData = await rootBundle.loadString('assets/labels.txt');
    final labels = labelsData
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();

    return labels.map((label) {
      return {
        'name': label,
        'modelLabel': label,
        'category': _categoryForTfliteLabel(label),
        'points': _pointsForTfliteLabel(label).toString(),
        'description': _descriptionForTfliteLabel(label),
      };
    }).toList();
  }

  String _categoryForTfliteLabel(String label) {
    final key = label.toLowerCase().trim();
    return TFLiteService.wasteCategoryMap[key] ??
        TFLiteService.wasteCategoryMap[key.replaceAll(' ', '_')] ??
        'Anorganik';
  }

  int _pointsForTfliteLabel(String label) {
    final key = label.toLowerCase().trim();
    return TFLiteService.wastePointsMap[key] ??
        TFLiteService.wastePointsMap[key.replaceAll(' ', '_')] ??
        10;
  }

  String _descriptionForTfliteLabel(String label) {
    switch (label.toLowerCase().trim()) {
      case 'vegetation':
        return 'Sampah organik dari tanaman, daun, dan ranting.';
      case 'textile trash':
        return 'Sampah kain, pakaian, dan material tekstil.';
      case 'plastic':
        return 'Sampah plastik seperti botol, kemasan, dan kantong.';
      case 'paper':
        return 'Sampah kertas, termasuk tisu dan lembaran kertas.';
      case 'miscellaneous trash':
        return 'Sampah campuran yang tidak masuk kategori utama.';
      case 'metal':
        return 'Sampah logam seperti kaleng dan benda berbahan metal.';
      case 'glass':
        return 'Sampah kaca seperti botol atau pecahan kaca.';
      case 'cardboard':
        return 'Sampah kardus dan karton.';
      case 'food organics':
        return 'Sampah organik dari sisa makanan.';
      default:
        return 'Jenis sampah tambahan.';
    }
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
                const SizedBox(height: 4),
                Text(
                  [
                    if ((item['category'] ?? '').toString().isNotEmpty)
                      item['category'],
                    if ((item['points'] ?? 0) > 0) '${item['points']} poin',
                    if (item['isTfliteLabel'] == true) 'TFLite',
                  ].join(' - '),
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
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
