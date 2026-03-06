import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloud_notes_service.dart';
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
  late final CloudNotesService _cloudNotesService;
  bool _isLoading = false;
  bool _isModified = false;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;

  // Validation state
  String? _titleError;

  // Character counts
  int _titleCharCount = 0;
  int _contentCharCount = 0;
  int _contentWordCount = 0;

  // Original values for update mode tracking
  late String _originalTitle;
  late String _originalContent;

  // Constants
  static const int _titleMaxLength = 200;
  static const int _contentMaxLength = 5000;

  /// Check if in update mode
  bool get _isUpdateMode => widget.noteId != null;

  /// Check if there are actual changes from original
  bool get _hasChanges {
    if (!_isUpdateMode) return true; // Always allow save for create mode
    final currentTitle = _titleController.text.trim();
    final currentContent = _contentController.text.trim();
    return currentTitle != _originalTitle || currentContent != _originalContent;
  }

  /// Get summary of what has changed
  String _getChangesSummary() {
    final titleChanged = _titleController.text.trim() != _originalTitle;
    final contentChanged = _contentController.text.trim() != _originalContent;

    List<String> changes = [];
    if (titleChanged) changes.add('Judul');
    if (contentChanged) changes.add('Isi');

    return changes.join(' & ');
  }

  @override
  void initState() {
    super.initState();
    _cloudNotesService = CloudNotesService();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    // Store original values for update mode
    _originalTitle = widget.initialTitle;
    _originalContent = widget.initialContent;

    _titleCharCount = widget.initialTitle.length;
    _contentCharCount = widget.initialContent.length;
    _contentWordCount = _countWords(widget.initialContent);

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _titleController.addListener(_validateTitle);
    _titleController.addListener(_updateCharCounts);
    _contentController.addListener(_updateCharCounts);
  }

  /// Update character and word counts
  void _updateCharCounts() {
    setState(() {
      _titleCharCount = _titleController.text.length;
      _contentCharCount = _contentController.text.length;
      _contentWordCount = _countWords(_contentController.text);
    });
  }

  /// Count words in text
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
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

    // For update mode, check if there are actual changes
    if (_isUpdateMode && !_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada perubahan untuk disimpan'),
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
        await _cloudNotesService.createNote(
          title: trimmedTitle,
          content: trimmedContent,
        );
      } else {
        // Update existing note
        await _cloudNotesService.updateNote(
          noteId: widget.noteId!,
          title: trimmedTitle,
          content: trimmedContent,
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
        _showErrorDialog(
          'Error',
          'Terjadi kesalahan saat menyimpan catatan: $e',
        );
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

  /// Show preview of changes for update mode
  void _showChangesPreview() {
    final titleChanged = _titleController.text.trim() != _originalTitle;
    final contentChanged = _contentController.text.trim() != _originalContent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.info_outlined, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Expanded(child: Text('Perubahan yang Akan Disimpan')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (titleChanged)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Judul',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '❌ $_originalTitle',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '✅ ${_titleController.text.trim()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              if (contentChanged)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Isi',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _originalContent.isEmpty
                            ? '(kosong)'
                            : _originalContent.length > 100
                            ? '${_originalContent.substring(0, 100)}...'
                            : _originalContent,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _contentController.text.trim().isEmpty
                            ? '(kosong)'
                            : _contentController.text.trim().length > 100
                            ? '${_contentController.text.trim().substring(0, 100)}...'
                            : _contentController.text.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _saveNote();
            },
            icon: const Icon(Icons.check),
            label: const Text('Simpan Perubahan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.noteId == null ? 'Catatan Baru' : 'Edit Catatan'),
              if (_isUpdateMode && _hasChanges)
                Text(
                  'Perubahan: ${_getChangesSummary()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.amber[200],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (_isUpdateMode && !_hasChanges)
                Text(
                  'Tidak ada perubahan',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.green[200],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_isUpdateMode && _hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Lihat Perubahan',
                  child: IconButton(
                    icon: const Icon(Icons.difference),
                    onPressed: _showChangesPreview,
                  ),
                ),
              ),
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
                        onPressed: (_isUpdateMode && !_hasChanges)
                            ? null
                            : _saveNote,
                        icon: const Icon(Icons.save),
                        label: Text(_isUpdateMode ? 'Perbarui' : 'Simpan'),
                      ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Title Input with Character Count
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
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
                      suffixIcon: _titleCharCount > _titleMaxLength * 0.8
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '$_titleCharCount/$_titleMaxLength',
                                style: TextStyle(
                                  color: _titleCharCount > _titleMaxLength
                                      ? Colors.red
                                      : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    maxLength: _titleMaxLength,
                    onSubmitted: (_) {
                      _contentFocusNode.requestFocus();
                    },
                  ),
                ],
              ),
            ),
            // Content Input with Stats
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Expanded(
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
                        maxLength: _contentMaxLength,
                      ),
                    ),
                    // Stats Row
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kata: $_contentWordCount',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Karakter: $_contentCharCount/$_contentMaxLength',
                            style: TextStyle(
                              fontSize: 12,
                              color: _contentCharCount > _contentMaxLength * 0.8
                                  ? Colors.orange
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
