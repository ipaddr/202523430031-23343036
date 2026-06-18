import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../utils/constants.dart';
import '../../utils/auth_provider.dart';
import '../../utils/theme_provider.dart';
import '../../services/petugas_task_service.dart';

class PetugasProfileScreen extends StatefulWidget {
  const PetugasProfileScreen({super.key});

  @override
  State<PetugasProfileScreen> createState() => _PetugasProfileScreenState();
}

class _PetugasProfileScreenState extends State<PetugasProfileScreen>
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _staggeredAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            (0.6 + ((index * 0.1).clamp(0.0, 1.0))).clamp(0.0, 1.0),
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
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _taskService.getTaskStatistics(_officerId!),
          _taskService.getOfficerDetails(_officerId!),
        ]),
        builder: (context, snapshot) {
          final stats = snapshot.hasData
              ? snapshot.data![0] as Map<String, int>
              : <String, int>{};
          final details = snapshot.hasData && snapshot.data![1] != null
              ? snapshot.data![1] as Map<String, dynamic>
              : <String, dynamic>{};

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(user, details),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildSectionTitle('Statistik Kinerja'),
                      const SizedBox(height: 16),
                      _buildStatsGrid(stats),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Informasi Akun'),
                      const SizedBox(height: 16),
                      _buildAccountInfo(user, details),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Pengaturan'),
                      const SizedBox(height: 16),
                      _buildMenuItems(),
                      const SizedBox(height: 40),
                      _buildLogoutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic user, Map<String, dynamic> details) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0D5A2F)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x331B5E20),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderIconButton(
                Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context),
              ),
              const Text(
                'Profil Petugas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              _buildHeaderIconButton(Icons.settings_suggest_rounded, () {}),
            ],
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _staggeredAnimations[0],
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _staggeredAnimations[1],
            child: Column(
              children: [
                Text(
                  user?.name ?? 'Petugas',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Petugas Kebersihan 👷',
                  style: TextStyle(
                    color: Color(0xFFD0E8D8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: _buildRatingBadge(details),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildRatingBadge(Map<String, dynamic> details) {
    final avgRating = (details['average_rating'] as num?)?.toDouble() ?? 0.0;
    final totalRatings = details['total_ratings'] as int? ?? 0;

    if (totalRatings > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: 6),
          Text(
            '${avgRating.toStringAsFixed(1)} Rating',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: const TextStyle(color: Color(0xFFD0E8D8), fontSize: 12),
          ),
        ],
      );
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_rounded, color: Color(0xFF86EFAC), size: 18),
        SizedBox(width: 8),
        Text(
          'Petugas Aktif',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    final totalTasks = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;

    return FadeTransition(
      opacity: _staggeredAnimations[2],
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Tugas',
              '$totalTasks',
              Icons.assignment_turned_in_rounded,
              const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Selesai',
              '$completed',
              Icons.recycling_rounded,
              const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(dynamic user, Map<String, dynamic> details) {
    final officerId = details['id'] ?? _officerId ?? '-';
    final area =
        (details['area'] ?? details['zone'] ?? details['region'] ?? '-')
            .toString();

    return FadeTransition(
      opacity: _staggeredAnimations[3],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        child: Column(
          children: [
            _buildInfoRow('ID Petugas', '$officerId', Icons.badge_rounded),
            _buildDivider(),
            _buildInfoRow(
              'Email',
              user?.email ?? (details['email'] ?? '-').toString(),
              Icons.email_rounded,
            ),
            _buildDivider(),
            _buildInfoRow(
              'No. HP',
              user?.phone ?? (details['phone'] ?? '-').toString(),
              Icons.phone_rounded,
            ),
            _buildDivider(),
            _buildInfoRow('Area Kerja', area, Icons.map_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }

  Widget _buildMenuItems() {
    return FadeTransition(
      opacity: _staggeredAnimations[4],
      child: Column(
        children: [
          _buildMenuTile('Edit Profil', Icons.edit_rounded, () {}),
          _buildMenuTile('Riwayat Kinerja', Icons.history_rounded, () {}),
          _buildMenuTile('Privasi & Keamanan', Icons.security_rounded, () {}),
          _buildMenuTile('Pusat Bantuan', Icons.help_center_rounded, () {}),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _buildMenuTileWithSwitch(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                'Mode Gelap',
                themeProvider.isDarkMode,
                (value) => themeProvider.setTheme(value),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFFCBD5E1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildMenuTileWithSwitch(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF1B7A3E),
          inactiveThumbColor: const Color(0xFFCBD5E1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return FadeTransition(
      opacity: _staggeredAnimations[5],
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        child: TextButton.icon(
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            await authProvider.logout();
          },
          icon: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          label: const Text(
            'Keluar Akun',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }
}
