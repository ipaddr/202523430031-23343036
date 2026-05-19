import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/constants.dart';
import '../../utils/theme_colors.dart';
import '../../utils/auth_provider.dart';
import '../../services/tracking_service.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'scan_waste_screen.dart';
import 'request_pickup_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late GoogleMapController _mapController;
  final TrackingService _trackingService = TrackingService();

  Position? _userLocation;
  Map<String, dynamic>? _truckData;
  bool _isLoading = true;
  String? _selectedRequestId;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Default location (Jakarta)
  static const LatLng _defaultLocation = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      // Get user current location
      _userLocation = await _trackingService.getCurrentLocation();

      // Get active requests
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        final requests = await _trackingService.getActiveRequests(userId);
        if (requests.isNotEmpty && mounted) {
          _selectedRequestId = requests.first['id'];
          _loadTruckData();
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Listen to real-time truck location updates
      if (_selectedRequestId != null) {
        _trackingService.getTruckLocationStream(_selectedRequestId!).listen((
          truckData,
        ) {
          if (mounted && truckData.isNotEmpty) {
            setState(() => _truckData = truckData);
            _updateMapMarkers();
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing tracking: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTruckData() async {
    if (_selectedRequestId == null) return;

    try {
      final data = await _trackingService.getTruckLocation(_selectedRequestId!);
      if (mounted && data != null) {
        setState(() => _truckData = data);
        _updateMapMarkers();
      }
    } catch (e) {
      debugPrint('Error loading truck data: $e');
    }
  }

  void _updateMapMarkers() {
    if (_userLocation == null || _truckData == null) return;

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
      infoWindow: const InfoWindow(title: 'Lokasi Anda'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    final truckLat = _truckData!['latitude'] as double?;
    final truckLng = _truckData!['longitude'] as double?;

    if (truckLat != null && truckLng != null) {
      final truckMarker = Marker(
        markerId: const MarkerId('truck_location'),
        position: LatLng(truckLat, truckLng),
        infoWindow: InfoWindow(
          title: _truckData!['driver_name'] ?? 'Truk Sampah',
          snippet: 'ETA: ${_truckData!['estimated_time'] ?? "Menghitung..."}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );

      setState(() {
        _markers = {userMarker, truckMarker};
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(truckLat, truckLng),
              LatLng(_userLocation!.latitude, _userLocation!.longitude),
            ],
            color: AppColors.primary,
            width: 3,
            geodesic: true,
          ),
        };
      });

      // Animate camera to show both markers
      _animateCameraToBounds();
    }
  }

  void _animateCameraToBounds() async {
    if (_userLocation == null || _truckData == null) return;

    final truckLat = _truckData!['latitude'] as double?;
    final truckLng = _truckData!['longitude'] as double?;

    if (truckLat != null && truckLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          (_userLocation!.latitude < truckLat
              ? _userLocation!.latitude
              : truckLat),
          (_userLocation!.longitude < truckLng
              ? _userLocation!.longitude
              : truckLng),
        ),
        northeast: LatLng(
          (_userLocation!.latitude > truckLat
              ? _userLocation!.latitude
              : truckLat),
          (_userLocation!.longitude > truckLng
              ? _userLocation!.longitude
              : truckLng),
        ),
      );

      _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  void _centerOnUser() {
    if (_userLocation == null) return;

    _mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(_userLocation!.latitude, _userLocation!.longitude),
      ),
    );
  }

  void _showQuickMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Menu Lainnya',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _buildMenuTile(
                    icon: Icons.calendar_today,
                    label: 'Jadwal',
                    color: ThemeColors.getStatusInProgressColor(context),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.shopping_cart,
                    label: 'Request',
                    color: ThemeColors.getStatusArrivedColor(context),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestPickupScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.qr_code_2,
                    label: 'Scan',
                    color: ThemeColors.getStatusPendingColor(context),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanWasteScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.history,
                    label: 'Riwayat',
                    color: ThemeColors.getStatusCompletedColor(context),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.bar_chart,
                    label: 'Statistik',
                    color: ThemeColors.getStatusRejectedColor(context),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.home,
                    label: 'Beranda',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : Stack(
              children: [
                // Google Maps
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: _userLocation != null
                        ? LatLng(
                            _userLocation!.latitude,
                            _userLocation!.longitude,
                          )
                        : _defaultLocation,
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),

                // Header
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, Color(0xFF0D5A2F)],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.lg,
                        vertical: AppPadding.md,
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
                            'Tracking Truk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: _centerOnUser,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Truck Info Card (Bottom Sheet)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildTruckInfoCard(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
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
                      'Tracking Truk',
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 20),
                    Text(
                      'Memuat peta dan lokasi truk...',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTruckInfoCard() {
    if (_truckData == null) {
      return Container(
        color: AppColors.white,
        padding: const EdgeInsets.all(AppPadding.lg),
        child: const Text(
          'Tidak ada truk yang sedang dalam perjalanan',
          textAlign: TextAlign.center,
        ),
      );
    }

    final distance = _userLocation != null && _truckData != null
        ? _trackingService.calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            _truckData!['latitude'] ?? 0.0,
            _truckData!['longitude'] ?? 0.0,
          )
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppPadding.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _truckData!['driver_name'] ?? 'Petugas',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Truk Sampah Anorganik',
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info Grid
          Row(
            children: [
              Expanded(
                child: _TruckInfoItem(
                  icon: Icons.schedule,
                  label: 'ETA',
                  value: _truckData!['estimated_time'] ?? '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TruckInfoItem(
                  icon: Icons.straighten,
                  label: 'Jarak',
                  value: '${distance.toStringAsFixed(1)} km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TruckInfoItem(
                  icon: Icons.check_circle,
                  label: 'Status',
                  value: _truckData!['status'] ?? 'pending',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TruckInfoItem(
                  icon: Icons.phone,
                  label: 'Hubungi',
                  value: _truckData!['phone'] ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Call Driver Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Implement phone call
                debugPrint('Call driver: ${_truckData!['phone']}');
              },
              icon: const Icon(Icons.phone),
              label: const Text('Hubungi Petugas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick Menu Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showQuickMenu();
              },
              icon: const Icon(Icons.apps),
              label: const Text('Menu Lainnya'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TruckInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TruckInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(AppPadding.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
