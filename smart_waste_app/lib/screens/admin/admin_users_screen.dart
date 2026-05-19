import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import '../../services/firebase_auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final FirebaseAuthService _authService = FirebaseAuthService();
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  String selectedFilter = 'Semua';
  final List<String> filters = ['Semua', 'Aktif', 'Nonaktif'];

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
    searchController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    return DateTime(1970);
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^(?:\+62|0)[0-9]{9,12}$').hasMatch(phone);
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'petugas':
        return 'Petugas';
      default:
        return 'User';
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'petugas':
        return AppColors.orange;
      default:
        return AppColors.blue;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return AppColors.green;
      case 'nonaktif':
        return AppColors.red;
      default:
        return AppColors.grey;
    }
  }

  void _showSnackBar(String message, {Color color = AppColors.primary}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      searchQuery = '';
      searchController.clear();
      selectedFilter = 'Semua';
    });
  }

  // Get users from Firestore based on filter
  Stream<List<Map<String, dynamic>>> _getUsersStream() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((
      snapshot,
    ) {
      var users = snapshot.docs.map((doc) {
        var data = doc.data();
        final role = (data['role'] ?? 'user').toString().toLowerCase();
        final status = (data['status'] ?? 'Aktif').toString();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': role,
          'status': status,
          'points': _toInt(data['points'] ?? data['totalPoints']),
          'wasteCollected': _toInt(
            data['wasteCollected'] ?? data['totalWasteCollected'],
          ),
          'emailVerified': data['emailVerified'] ?? false,
          'createdAt': data['createdAt'],
        };
      }).toList();

      users.sort((a, b) {
        final aDate = _toDateTime(a['createdAt']);
        final bDate = _toDateTime(b['createdAt']);
        return bDate.compareTo(aDate);
      });

      // Filter
      if (selectedFilter != 'Semua') {
        users = users
            .where((user) => user['status'] == selectedFilter)
            .toList();
      }

      // Search
      if (searchQuery.isNotEmpty) {
        users = users
            .where(
              (user) =>
                  user['name'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  user['email'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }

      return users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserBottomSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Pengguna'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                      'Kelola Pengguna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resetFilters,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.refresh,
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
                    // Search Bar
                    TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Cari pengguna...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.lg,
                          vertical: AppPadding.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters.map((filter) {
                          bool isSelected = selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedFilter = filter),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.grey.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Users List from Firestore
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _getUsersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Gagal memuat pengguna: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.grey.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_off,
                                  size: 48,
                                  color: AppColors.grey.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada pengguna',
                                  style: TextStyle(
                                    color: AppColors.grey.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final users = snapshot.data!;
                        return Column(
                          children: List.generate(
                            users.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0.5, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(
                                          (index * 0.1).clamp(0.0, 1.0),
                                          ((index + 1) * 0.1).clamp(0.0, 1.0),
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                    ),
                                child: _buildUserCard(users[index]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = user['status']?.toString() ?? 'Aktif';
    final role = user['role']?.toString() ?? 'user';
    return GestureDetector(
      onTap: () => _showUserDetailDialog(user),
      child: Container(
        padding: const EdgeInsets.all(AppPadding.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'],
                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBadge(_roleLabel(role), _roleColor(role)),
                    const SizedBox(height: 6),
                    _buildBadge(status, _statusColor(status)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.recycling,
                    '${user['wasteCollected']} kg',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoItem(Icons.star, '${user['points']} Poin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showUserDetailDialog(Map<String, dynamic> user) {
    final status = user['status']?.toString() ?? 'Aktif';
    final role = user['role']?.toString() ?? 'user';
    final isVerified = user['emailVerified'] == true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user['name']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', user['email']),
                const SizedBox(height: 8),
                _buildDetailRow('Telepon', user['phone']),
                const SizedBox(height: 8),
                _buildDetailRow('Role', _roleLabel(role)),
                const SizedBox(height: 8),
                _buildDetailRow('Status', status),
                const SizedBox(height: 8),
                _buildDetailRow('Poin', '${user['points']}'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Sampah Terkumpul',
                  '${user['wasteCollected']} kg',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Email Terverifikasi',
                  isVerified ? 'Ya' : 'Belum',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            if (user['id'] != _authService.currentUser?.uid)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showRoleUpdateDialog(user);
                },
                child: const Text('Ubah Role'),
              ),
            ElevatedButton(
              onPressed: () {
                _updateUserStatus(user['id'], status);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'Aktif' ? Colors.red : Colors.green,
              ),
              child: Text(status == 'Aktif' ? 'Nonaktifkan' : 'Aktifkan'),
            ),
          ],
        );
      },
    );
  }

  void _showRoleUpdateDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    String selectedRole = (user['role'] ?? 'user').toString().toLowerCase();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setModalState) {
            Future<void> submitRole() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              setModalState(() => isSubmitting = true);

              final success = await _authService.updateUserRole(
                userId: user['id'],
                role: selectedRole,
              );

              if (!mounted) return;

              if (success) {
                Navigator.of(context).pop();
                _showSnackBar(
                  'Role pengguna berhasil diubah menjadi ${_roleLabel(selectedRole)}',
                );
                return;
              }

              setModalState(() => isSubmitting = false);
              _showSnackBar(
                'Gagal mengubah role pengguna',
                color: AppColors.red,
              );
            }

            return AlertDialog(
              title: const Text('Ubah Role Pengguna'),
              content: Form(
                key: formKey,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          if (value == null) return;
                          setModalState(() => selectedRole = value);
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih role terlebih dahulu';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitRole,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddUserBottomSheet() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    bool isSubmitting = false;
    String selectedRole = 'user';

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (_, setModalState) {
              Future<void> submit() async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                setModalState(() => isSubmitting = true);

                final result = await _authService.createUserByAdmin(
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  password: passwordController.text,
                  role: selectedRole,
                );

                if (!mounted) return;

                if (result['success'] == true) {
                  Navigator.of(context).pop();
                  final createdRole = _roleLabel(
                    result['role']?.toString() ?? selectedRole,
                  );
                  final verificationSent =
                      result['verificationEmailSent'] == true;
                  _showSnackBar(
                    verificationSent
                        ? 'Pengguna berhasil ditambahkan sebagai $createdRole dan email verifikasi sudah dikirim.'
                        : 'Pengguna berhasil ditambahkan sebagai $createdRole.',
                  );
                  return;
                }

                setModalState(() => isSubmitting = false);
                _showSnackBar(
                  result['message']?.toString() ?? 'Gagal menambahkan pengguna',
                  color: AppColors.red,
                );
              }

              final bottomPadding = MediaQuery.of(
                sheetContext,
              ).viewInsets.bottom;

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 52,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tambah Pengguna',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Buat akun baru dan atur role awalnya.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: nameController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  hintText: 'Contoh: Budi Santoso',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: AppColors.primary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nama wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'user@email.com',
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!_isValidEmail(email)) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Nomor HP',
                                  hintText: '08xxxxxxxxxx',
                                  prefixIcon: const Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.primary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  final phone = value?.trim() ?? '';
                                  if (phone.isEmpty) {
                                    return 'Nomor HP wajib diisi';
                                  }
                                  if (!_isValidPhone(phone)) {
                                    return 'Format nomor HP tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Minimal 6 karakter',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.grey,
                                    ),
                                    onPressed: isSubmitting
                                        ? null
                                        : () => setModalState(
                                            () => obscurePassword =
                                                !obscurePassword,
                                          ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  final password = value ?? '';
                                  if (password.isEmpty) {
                                    return 'Password wajib diisi';
                                  }
                                  if (password.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: confirmPasswordController,
                                obscureText: obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi Password',
                                  hintText: 'Ulangi password',
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_outlined,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.grey,
                                    ),
                                    onPressed: isSubmitting
                                        ? null
                                        : () => setModalState(
                                            () => obscureConfirmPassword =
                                                !obscureConfirmPassword,
                                          ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Konfirmasi password wajib diisi';
                                  }
                                  if (value != passwordController.text) {
                                    return 'Password tidak cocok';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue: selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Role',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: AppColors.primary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'user',
                                    child: Text('User'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'petugas',
                                    child: Text('Petugas'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                ],
                                onChanged: isSubmitting
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setModalState(
                                          () => selectedRole = value,
                                        );
                                      },
                              ),
                              const SizedBox(height: 14),
                              if (selectedRole == 'admin')
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.purple.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Role Admin memberi akses penuh ke data dan pengaturan sistem.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              if (selectedRole == 'admin')
                                const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: isSubmitting ? null : submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Simpan Pengguna',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _updateUserStatus(String userId, String currentStatus) {
    final newStatus = currentStatus == 'Aktif' ? 'Nonaktif' : 'Aktif';
    _authService.updateUserStatus(userId: userId, status: newStatus).then((
      success,
    ) {
      if (success) {
        _showSnackBar('Status pengguna diubah menjadi $newStatus');
        return;
      }

      _showSnackBar('Gagal mengubah status pengguna', color: AppColors.red);
    });
  }
}
