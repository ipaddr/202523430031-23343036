import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'note_operation_success_screen.dart';

class AddNoteScreen extends StatefulWidget {
  final User user;
  final String? noteId;
  final String initialTitle;
  final String initialContent;

  const AddNoteScreen({
    super.key,
    required this.user,
    this.noteId,
    this.initialTitle = '',
    this.initialContent = '',
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {
      _isModified = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isCreating = widget.noteId == null;
      if (isCreating) {
        // Create new note
        await FirebaseService().createNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } else {
        // Update existing note
        await FirebaseService().updateNote(
          noteId: widget.noteId!,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      }

      if (mounted) {
        _showSuccessScreen(isCreating);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessScreen(bool isCreating) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => NoteOperationSuccessScreen(
          title: isCreating ? 'Catatan Dibuat!' : 'Catatan Diperbarui!',
          message: isCreating
              ? 'Catatan Anda berhasil disimpan dan siap untuk dilihat.'
              : 'Perubahan catatan Anda berhasil disimpan.',
          buttonText: 'Kembali ke Daftar',
          icon: isCreating ? Icons.note_add : Icons.edit,
          backgroundColor: Colors.blue,
          onContinue: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isModified) {
          return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Simpan Perubahan?'),
                  content: const Text('Ada perubahan yang belum disimpan.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Jangan Simpan'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context, false);
                        await _saveNote();
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.noteId == null ? 'Catatan Baru' : 'Edit Catatan'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _isModified ? _saveNote : null,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan'),
                      ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Title Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Judul catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
              ),
            ),
            // Content Input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    hintText: 'Tulis catatan Anda di sini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
