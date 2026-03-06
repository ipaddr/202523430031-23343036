import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;

  // Validation state
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _titleController.addListener(_validateTitle);
  }

  /// Validate title field
  void _validateTitle() {
    if (_titleController.text.isEmpty && _titleFocusNode.hasFocus) {
      _titleError = 'Judul tidak boleh kosong';
    } else {
      _titleError = null;
    }
    if (mounted) setState(() {});
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
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final trimmedTitle = _titleController.text.trim();
    final trimmedContent = _contentController.text.trim();

    // Validate title
    if (trimmedTitle.isEmpty) {
      setState(() {
        _titleError = 'Judul tidak boleh kosong';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _titleError = null;
    });

    try {
      final isCreating = widget.noteId == null;

      if (isCreating) {
        // Create new note
        await FirebaseService().createNote(
          title: trimmedTitle,
          content: trimmedContent,
        );
      } else {
        // Update existing note
        await FirebaseService().updateNote(
          noteId: widget.noteId!,
          title: trimmedTitle,
          content: trimmedContent,
        );
      }

      if (mounted) {
        _showSuccessScreen(isCreating);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
          'Error Firebase',
          e.message ?? 'Terjadi kesalahan saat menyimpan catatan',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error', 'Terjadi kesalahan: $e');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan Perubahan?'),
        content: const Text('Ada perubahan yang belum disimpan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Jangan Simpan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveNote();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isModified,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_isModified) {
          Navigator.pop(context);
          return;
        }
        _showUnsavedChangesDialog();
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
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  hintText: 'Judul catatan',
                  errorText: _titleError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  prefixIcon: const Icon(Icons.title),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                onSubmitted: (_) {
                  _contentFocusNode.requestFocus();
                },
              ),
            ),
            // Content Input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
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
