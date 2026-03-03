/// Example implementation showing how to use NoteService streams in a Flutter widget
///
/// This demonstrates the recommended approach for building real-time note lists
/// using StreamBuilder for automatic UI updates.

import 'package:flutter/material.dart';

// Note: Replace these imports with the actual paths from your project
// import 'package:your_app_name/services/crud/crud/note_service.dart';
// import 'package:your_app_name/models/note_model.dart';
//
// For this example to work, uncomment the imports above and adjust paths

/// Example 1: Basic Notes List Screen with StreamBuilder
///
/// This is the recommended approach as StreamBuilder automatically handles:
/// - Stream subscription and cleanup
/// - Loading, error, and data states
/// - Rebuilding UI when data changes
///
/// Usage:
/// ```dart
/// NotesListScreen(
///   noteService: noteService,
///   currentUser: currentUser,
/// )
/// ```
class NotesListScreen extends StatelessWidget {
  // final NoteService noteService;
  // final DatabaseUser currentUser;

  const NotesListScreen({
    Key? key,
    // required this.noteService,
    // required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example usage (uncomment when imports are set up):
    // return StreamBuilder<List<DatabaseNote>>(
    //   stream: noteService.allNotesStream,
    //   builder: (context, snapshot) {
    //     // Handle connection state
    //     if (snapshot.connectionState == ConnectionState.waiting &&
    //         snapshot.data == null) {
    //       return const Center(child: CircularProgressIndicator());
    //     }
    //
    //     // Handle error state
    //     if (snapshot.hasError) {
    //       return Center(
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             const Icon(Icons.error, size: 48, color: Colors.red),
    //             const SizedBox(height: 16),
    //             Text('Error: ${snapshot.error}'),
    //           ],
    //         ),
    //       );
    //     }
    //
    //     // Handle empty state
    //     final notes = snapshot.data ?? [];
    //     if (notes.isEmpty) {
    //       return const Center(
    //         child: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Icon(Icons.note_rounded, size: 64, color: Colors.grey),
    //             SizedBox(height: 16),
    //             Text('No notes yet'),
    //           ],
    //         ),
    //       );
    //     }
    //
    //     // Display notes
    //     return ListView.builder(
    //       itemCount: notes.length,
    //       itemBuilder: (context, index) {
    //         final note = notes[index];
    //         return NoteListItem(
    //           note: note,
    //           onTap: () => _editNote(context, note),
    //           onDelete: () => _deleteNote(context, note),
    //         );
    //       },
    //     );
    //   },
    // );

    return Scaffold(
      appBar: AppBar(title: const Text('Notes List (Example)')),
      body: const Center(child: Text('See code comments for usage example')),
    );
  }

  // void _editNote(BuildContext context, DatabaseNote note) {
  //   // Navigate to note detail/edit screen
  // }
  //
  // Future<void> _deleteNote(BuildContext context, DatabaseNote note) async {
  //   // Show confirmation dialog
  //   final shouldDelete = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Delete Note'),
  //       content: const Text('This action cannot be undone.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           style: TextButton.styleFrom(foregroundColor: Colors.red),
  //           child: const Text('Delete'),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (shouldDelete ?? false) {
  //     try {
  //       await noteService.deleteNote(id: note.id);
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Note deleted')),
  //         );
  //       }
  //     } catch (e) {
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Error: $e')),
  //         );
  //       }
  //     }
  //   }
  // }
}

/// Example 2: Reusable Note List Item Widget
///
/// This widget displays a single note and handles interactions
class NoteListItem extends StatelessWidget {
  // final DatabaseNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteListItem({
    Key? key,
    // required this.note,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example implementation:
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note Title', // note.text.isEmpty ? 'Untitled' : note.text
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note ID', // 'Note ID: ${note.id}'
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example 3: Pattern for handling streams with error states
///
/// This shows how to structure stream handling with proper error management
class StreamBuilderPattern extends StatelessWidget {
  const StreamBuilderPattern({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example pattern:
    // return StreamBuilder<List<DatabaseNote>>(
    //   stream: noteService.allNotesStream,
    //   builder: (context, snapshot) {
    //     // 1. Loading state
    //     if (snapshot.connectionState == ConnectionState.waiting &&
    //         !snapshot.hasData) {
    //       return const _LoadingWidget();
    //     }
    //
    //     // 2. Error state
    //     if (snapshot.hasError) {
    //       return _ErrorWidget(error: snapshot.error);
    //     }
    //
    //     // 3. Empty state
    //     final notes = snapshot.data ?? [];
    //     if (notes.isEmpty) {
    //       return const _EmptyWidget();
    //     }
    //
    //     // 4. Data state
    //     return _NotesListWidget(notes: notes);
    //   },
    // );

    return Scaffold(
      appBar: AppBar(title: const Text('Stream Pattern Example')),
      body: const Center(child: Text('See code comments for pattern examples')),
    );
  }
}

/// Widget showing loading state
/// Use this in your StreamBuilder implementation
/// Example: if (snapshot.connectionState == ConnectionState.waiting) return LoadingState();
class StreamLoadingState extends StatelessWidget {
  const StreamLoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Widget showing error state
/// Use this in your StreamBuilder implementation
/// Example: if (snapshot.hasError) return ErrorState(error: snapshot.error);
class StreamErrorState extends StatelessWidget {
  final Object? error;

  const StreamErrorState({Key? key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $error', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// Widget showing empty state
/// Use this in your StreamBuilder implementation
/// Example: if (notes.isEmpty) return EmptyState();
class StreamEmptyState extends StatelessWidget {
  const StreamEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No notes yet', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
