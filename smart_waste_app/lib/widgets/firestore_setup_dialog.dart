import 'package:flutter/material.dart';
import '../../services/firestore_init_service.dart';
import '../../utils/constants.dart';

class FirestoreSetupDialog extends StatefulWidget {
  const FirestoreSetupDialog({super.key});

  @override
  State<FirestoreSetupDialog> createState() => _FirestoreSetupDialogState();
}

class _FirestoreSetupDialogState extends State<FirestoreSetupDialog> {
  final FirestoreInitService _initService = FirestoreInitService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _initializeSampleData() async {
    setState(() => _isLoading = true);

    final success = await _initService.initializeSamplePickupRequests();

    setState(() {
      _isLoading = false;
      _statusMessage = success
          ? '✅ Data contoh berhasil dibuat'
          : '❌ Gagal membuat data contoh';
    });

    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _checkCollection() async {
    setState(() => _isLoading = true);

    final exists = await _initService.checkPickupRequestsCollection();

    setState(() {
      _isLoading = false;
      _statusMessage = exists
          ? '✅ Collection sudah ada dengan data'
          : '⚠️ Collection kosong atau belum ada';
    });
  }

  Future<void> _deleteData() async {
    setState(() => _isLoading = true);

    final success = await _initService.deleteSampleData();

    setState(() {
      _isLoading = false;
      _statusMessage = success
          ? '✅ Data berhasil dihapus'
          : '❌ Gagal menghapus data';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Setup Firestore'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inisialisasi data pickup_requests untuk testing & development',
              style: TextStyle(fontSize: 14, color: AppColors.grey),
            ),
            const SizedBox(height: 20),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.startsWith('✅')
                      ? const Color(0xFFE8F5E9)
                      : _statusMessage.startsWith('⚠️')
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.startsWith('✅')
                        ? AppColors.green
                        : _statusMessage.startsWith('⚠️')
                        ? AppColors.orange
                        : AppColors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Data yang akan dibuat:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Request 1: Anorganik (10kg) - In Progress\n'
              '• Request 2: Organik (5kg) - Pending',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _isLoading ? null : _checkCollection,
          icon: const Icon(Icons.search),
          label: const Text('Cek Data'),
        ),
        TextButton.icon(
          onPressed: _isLoading ? null : _deleteData,
          icon: const Icon(Icons.delete_forever),
          label: const Text('Hapus'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _initializeSampleData,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_circle),
          label: Text(_isLoading ? 'Membuat...' : 'Buat Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Show Firestore setup dialog
void showFirestoreSetupDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const FirestoreSetupDialog(),
  );
}
