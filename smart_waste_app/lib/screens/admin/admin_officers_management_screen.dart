import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class AdminOfficersManagementScreen extends StatefulWidget {
  const AdminOfficersManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminOfficersManagementScreen> createState() =>
      _AdminOfficersManagementScreenState();
}

class _AdminOfficersManagementScreenState
    extends State<AdminOfficersManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  String selectedRole = 'Semua';
  final List<String> roles = ['Semua', 'Petugas', 'Admin'];

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

  Stream<List<Map<String, dynamic>>> _getOfficersStream() {
    return FirebaseFirestore.instance.collection('officers').snapshots().map((
      snapshot,
    ) {
      var officers = snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? 'Petugas',
          'status': data['status'] ?? 'Aktif',
          'assignedRequests': data['assignedRequests'] ?? 0,
          'completedRequests': data['completedRequests'] ?? 0,
          'createdAt': data['createdAt'],
        };
      }).toList();

      // Filter by role
      if (selectedRole != 'Semua') {
        officers = officers.where((o) => o['role'] == selectedRole).toList();
      }

      // Search
      if (searchQuery.isNotEmpty) {
        officers = officers
            .where(
              (o) =>
                  o['name'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  o['email'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }

      return officers;
    });
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
                      'Kelola Admin & Petugas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddOfficerDialog(),
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
                    // Search Bar
                    TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Cari admin/petugas...',
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
                        children: roles.map((role) {
                          bool isSelected = selectedRole == role;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => selectedRole = role),
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
                                  role,
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

                    // Officers List from Firestore
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _getOfficersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: AppColors.grey.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada admin/petugas',
                                  style: TextStyle(
                                    color: AppColors.grey.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final officers = snapshot.data!;
                        return Column(
                          children: List.generate(
                            officers.length,
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
                                child: _buildOfficerCard(officers[index]),
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildOfficerCard(Map<String, dynamic> officer) {
    final isAdmin = officer['role'] == 'Admin';
    final isActive = officer['status'] == 'Aktif';

    return GestureDetector(
      onTap: () => _showOfficerDetailDialog(officer),
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
                        officer['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        officer['email'],
                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? Colors.purple.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        officer['role'],
                        style: TextStyle(
                          fontSize: 10,
                          color: isAdmin ? Colors.purple : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        officer['status'],
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.assignment_turned_in,
                    '${officer['assignedRequests']} Ditugaskan',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoItem(
                    Icons.check_circle,
                    '${officer['completedRequests']} Selesai',
                  ),
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

  void _showOfficerDetailDialog(Map<String, dynamic> officer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(officer['name']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', officer['email']),
                const SizedBox(height: 8),
                _buildDetailRow('Telepon', officer['phone']),
                const SizedBox(height: 8),
                _buildDetailRow('Role', officer['role']),
                const SizedBox(height: 8),
                _buildDetailRow('Status', officer['status']),
                const SizedBox(height: 8),
                _buildDetailRow('Ditugaskan', '${officer['assignedRequests']}'),
                const SizedBox(height: 8),
                _buildDetailRow('Selesai', '${officer['completedRequests']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateOfficerStatus(officer['id'], officer['status']);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: officer['status'] == 'Aktif'
                    ? Colors.red
                    : Colors.green,
              ),
              child: Text(
                officer['status'] == 'Aktif' ? 'Nonaktifkan' : 'Aktifkan',
              ),
            ),
            if (officer['role'] != 'Admin')
              ElevatedButton(
                onPressed: () {
                  _deleteOfficer(officer['id']);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
          ],
        );
      },
    );
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

  void _updateOfficerStatus(String officerId, String currentStatus) {
    final newStatus = currentStatus == 'Aktif' ? 'Nonaktif' : 'Aktif';
    FirebaseFirestore.instance
        .collection('officers')
        .doc(officerId)
        .update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status berhasil diubah menjadi $newStatus'),
              duration: const Duration(seconds: 2),
            ),
          );
        })
        .catchError((e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        });
  }

  void _deleteOfficer(String officerId) {
    FirebaseFirestore.instance
        .collection('officers')
        .doc(officerId)
        .delete()
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Petugas berhasil dihapus'),
              duration: Duration(seconds: 2),
            ),
          );
        })
        .catchError((e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        });
  }

  void _showAddOfficerDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Petugas';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Admin/Petugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  onChanged: (value) => selectedRole = value ?? 'Petugas',
                  items: const [
                    DropdownMenuItem(value: 'Petugas', child: Text('Petugas')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('officers')
                      .add({
                        'name': nameController.text,
                        'email': emailController.text,
                        'phone': phoneController.text,
                        'role': selectedRole,
                        'status': 'Aktif',
                        'assignedRequests': 0,
                        'completedRequests': 0,
                        'createdAt': FieldValue.serverTimestamp(),
                      })
                      .then((_) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Admin/Petugas berhasil ditambahkan'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      })
                      .catchError((e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      });
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}
