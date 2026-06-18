import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme_colors.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'tracking_screen.dart';
import 'scan_waste_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';

class RequestPickupScreen extends StatefulWidget {
  final String? initialWasteType;

  const RequestPickupScreen({super.key, this.initialWasteType});

  @override
  State<RequestPickupScreen> createState() => _RequestPickupScreenState();
}

class _RequestPickupScreenState extends State<RequestPickupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _selectedWaste;
  String _volume = '5 kg';
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _firestoreService = FirestoreService();

  final List<_WasteOption> _wasteOptions = [
    _WasteOption('Anorganik', Icons.delete_outline, const Color(0xFF2196F3)),
    _WasteOption('Organik', Icons.eco, const Color(0xFF4CAF50)),
    _WasteOption('B3', Icons.warning_outlined, Colors.red),
    _WasteOption('Kertas', Icons.description, const Color(0xFFFF9800)),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();

    // Pre-select waste type from scan result
    if (widget.initialWasteType != null) {
      _selectedWaste = _matchWasteType(widget.initialWasteType!);
    }
  }

  /// Match AI scan category to available waste options
  String _matchWasteType(String category) {
    final cat = category.toLowerCase();
    if (cat == 'organik') return 'Organik';
    if (cat == 'anorganik') return 'Anorganik';
    // Map specific labels to closest option
    if (cat.contains('kertas') || cat == 'paper') return 'Kertas';
    return 'Anorganik'; // default fallback
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi belum aktif'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi diperlukan untuk mengambil koordinat'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_locationController.text.trim().isEmpty) {
          _locationController.text =
              'Lat ${position.latitude.toStringAsFixed(5)}, '
              'Lng ${position.longitude.toStringAsFixed(5)}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submitRequest() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    final authUser = context.read<AuthProvider>().user;
    final location = _locationController.text.trim();
    final notes = _notesController.text.trim();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login ulang sebelum mengirim request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWaste == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis sampah terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi lokasi penjemputan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _firestoreService.createPickupRequest(
      uid: user.uid,
      wasteType: _selectedWaste!,
      weight: _volume,
      location: location,
      address: location,
      latitude: _latitude ?? 0,
      longitude: _longitude ?? 0,
      notes: notes,
      userName: authUser?.name ?? user.displayName,
      userPhone: authUser?.phone,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request penjemputan berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim request. Coba lagi sebentar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      'Request Penjemputan',
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
                        Icons.check_circle_outline,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waste Type Selection
                    const Text(
                      'Pilih Jenis Sampah',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: List.generate(
                        _wasteOptions.length,
                        (index) => ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                (index / _wasteOptions.length) * 0.3,
                                ((index + 1) / _wasteOptions.length) * 0.3 +
                                    0.5,
                                curve: Curves.elasticOut,
                              ),
                            ),
                          ),
                          child: _WasteChip(
                            option: _wasteOptions[index],
                            selected:
                                _selectedWaste == _wasteOptions[index].label,
                            onTap: () {
                              setState(
                                () =>
                                    _selectedWaste = _wasteOptions[index].label,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Volume Selection
                    const Text(
                      'Berat / Volume',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.lg,
                      ),
                      child: DropdownButton<String>(
                        value: _volume,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: ['5 kg', '10 kg', '15 kg', '20 kg', '25+ kg']
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _volume = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Location
                    const Text(
                      'Lokasi Penjemputan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Jl. Ahmad Yani No. 45',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          suffixIcon: IconButton(
                            tooltip: 'Gunakan lokasi saat ini',
                            onPressed: _isGettingLocation
                                ? null
                                : _useCurrentLocation,
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(AppPadding.lg),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Additional Notes
                    const Text(
                      'Catatan Tambahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tambahkan catatan (opsional)',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(AppPadding.lg),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Navigation Menu
                    const Text(
                      'Menu Lainnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: [
                        _QuickMenuCard(
                          icon: Icons.calendar_today,
                          label: 'Jadwal',
                          color: ThemeColors.getStatusInProgressColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScheduleScreen(),
                            ),
                          ),
                        ),
                        _QuickMenuCard(
                          icon: Icons.local_shipping,
                          label: 'Tracking',
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrackingScreen(),
                            ),
                          ),
                        ),
                        _QuickMenuCard(
                          icon: Icons.qr_code_2,
                          label: 'Scan',
                          color: ThemeColors.getStatusPendingColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanWasteScreen(),
                            ),
                          ),
                        ),
                        _QuickMenuCard(
                          icon: Icons.history,
                          label: 'Riwayat',
                          color: ThemeColors.getStatusCompletedColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          ),
                        ),
                        _QuickMenuCard(
                          icon: Icons.bar_chart,
                          label: 'Statistik',
                          color: ThemeColors.getStatusRejectedColor(context),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatisticsScreen(),
                            ),
                          ),
                        ),
                        _QuickMenuCard(
                          icon: Icons.home,
                          label: 'Beranda',
                          color: AppColors.primary,
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserHomeScreen(),
                            ),
                            (route) => false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSubmitting ? 'Mengirim...' : 'Kirim Request',
                          style: AppText.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickMenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickMenuCard> createState() => _QuickMenuCardState();
}

class _QuickMenuCardState extends State<_QuickMenuCard>
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
      end: 0.92,
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
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.1),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 28),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
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

class _WasteOption {
  final String label;
  final IconData icon;
  final Color color;

  _WasteOption(this.label, this.icon, this.color);
}

class _WasteChip extends StatefulWidget {
  final _WasteOption option;
  final bool selected;
  final VoidCallback onTap;

  const _WasteChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_WasteChip> createState() => _WasteChipState();
}

class _WasteChipState extends State<_WasteChip>
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
      end: 0.95,
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
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.option.color,
                      widget.option.color.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: widget.selected ? null : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: widget.selected
                ? null
                : Border.all(
                    color: widget.option.color.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.option.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.option.icon,
                color: widget.selected ? AppColors.white : widget.option.color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                widget.option.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.selected ? AppColors.white : AppColors.black,
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
