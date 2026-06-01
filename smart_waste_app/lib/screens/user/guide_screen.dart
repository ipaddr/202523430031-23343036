import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

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
                      'Panduan Pemilahan',
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
                        Icons.info,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Hero Section
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          'Cara Memilah Sampah',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pelajari cara yang benar untuk memilah sampah sesuai jenisnya',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Guide Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  children: [
                    _ExpandableGuideCard(
                      icon: '♻️',
                      category: 'Anorganik',
                      description: 'Plastik, logam, gelas, dan kemasan plastik',
                      examples:
                          'Botol plastik, kaleng, gelas, wadah makanan, styrofoam',
                      color: const Color(0xFF2196F3),
                      delay: 100,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _ExpandableGuideCard(
                      icon: '🌱',
                      category: 'Organik',
                      description: 'Sisa makanan, daun, dan ranting',
                      examples:
                          'Sisa nasi, sayuran, kulit buah, daun kering, rumput',
                      color: const Color(0xFF4CAF50),
                      delay: 200,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _ExpandableGuideCard(
                      icon: '⚠️',
                      category: 'B3 (Berbahaya)',
                      description: 'Batu baterai, elektronik, dan cat',
                      examples:
                          'Batu baterai, lampu, oli bekas, obat kadaluarsa, syringe',
                      color: Colors.red,
                      delay: 300,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _ExpandableGuideCard(
                      icon: '📄',
                      category: 'Kertas',
                      description: 'Kertas, kardus, dan buku',
                      examples:
                          'Kertas putih, kardus bekas, majalah bekas, koran lama',
                      color: const Color(0xFFFF9800),
                      delay: 400,
                      animationController: _animationController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Tips Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Tips Pemilahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _TipItem(
                      icon: Icons.check_circle,
                      title: 'Pisahkan dengan benar',
                      description:
                          'Pastikan setiap sampah terpisah sesuai jenis',
                      delay: 0,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _TipItem(
                      icon: Icons.check_circle,
                      title: 'Bersihkan terlebih dahulu',
                      description: 'Bersihkan sisa makanan sebelum membuang',
                      delay: 100,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _TipItem(
                      icon: Icons.check_circle,
                      title: 'Gunakan tas terpisah',
                      description:
                          'Gunakan tas/tempat berbeda untuk setiap jenis',
                      delay: 200,
                      animationController: _animationController,
                    ),
                    const SizedBox(height: 12),
                    _TipItem(
                      icon: Icons.check_circle,
                      title: 'Tanya jika ragu',
                      description:
                          'Hubungi kami jika ada sampah yang sulit diklasifikasi',
                      delay: 300,
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

class _ExpandableGuideCard extends StatefulWidget {
  final String icon;
  final String category;
  final String description;
  final String examples;
  final Color color;
  final int delay;
  final AnimationController animationController;

  const _ExpandableGuideCard({
    required this.icon,
    required this.category,
    required this.description,
    required this.examples,
    required this.color,
    required this.delay,
    required this.animationController,
  });

  @override
  State<_ExpandableGuideCard> createState() => _ExpandableGuideCardState();
}

class _ExpandableGuideCardState extends State<_ExpandableGuideCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: widget.animationController,
              curve: Interval(
                0.4 + (widget.delay / 1000),
                0.8 + (widget.delay / 1000),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            widget.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: widget.color,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppPadding.lg,
                    0,
                    AppPadding.lg,
                    AppPadding.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 1,
                        color: widget.color.withValues(alpha: 0.2),
                        margin: const EdgeInsets.only(bottom: AppPadding.lg),
                      ),
                      Text(
                        'Contoh Barang:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.examples,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.black,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;
  final AnimationController animationController;

  const _TipItem({
    required this.icon,
    required this.title,
    required this.description,
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
                0.5 + (delay / 1000),
                0.9 + (delay / 1000),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
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
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
