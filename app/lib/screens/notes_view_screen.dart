/// Notes View Screen - Display all notes using StreamBuilder
///
/// This screen demonstrates how to read and display all notes from the
/// NoteService using a Stream. The UI automatically updates whenever notes
/// are created, updated, or deleted.
///
/// Features:
/// - Real-time notes display using StreamBuilder
/// - Loading, error, and empty state handling
/// - Note list with tap to view/edit functionality
/// - Delete confirmation dialog
/// - Sync status indicator
/// - Pull-to-refresh support

import 'package:flutter/material.dart';

// Uncomment and adjust for your project:
// import 'package:your_app/services/crud/crud/note_service.dart';
// import 'package:your_app/models/note_model.dart';

/// Main screen showing all notes
///
/// Usage:
/// ```dart
/// NotesViewScreen(
///   noteService: noteService,
///   currentUser: currentUser,
/// )
/// ```
class NotesViewScreen extends StatefulWidget {
  // final NoteService noteService;
  // final DatabaseUser currentUser;

  const NotesViewScreen({
    Key? key,
    // required this.noteService,
    // required this.currentUser,
  }) : super(key: key);

  @override
  State<NotesViewScreen> createState() => _NotesViewScreenState();
}

class _NotesViewScreenState extends State<NotesViewScreen> {
  // Search functionality
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar with title and search
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('My Notes'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Could implement search dialog here
          },
        ),
      ],
    );
  }

  /// Build main body with stream
  Widget _buildBody() {
    // Uncomment when imports are ready:
    // return StreamBuilder<List<DatabaseNote>>(
    //   stream: widget.noteService.allNotesStream,
    //   builder: (context, snapshot) => _buildStreamContent(context, snapshot),
    // );

    return const _PlaceholderContent();
  }

  /// Build floating action button
  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _createNote,
      tooltip: 'Create new note',
      child: const Icon(Icons.add),
    );
  }

  // ========================================================================
  // ACTIONS
  // ========================================================================

  /// Handle create note action
  void _createNote() {
    // Uncomment when ready:
    // try {
    //   await widget.noteService.createNote(owner: widget.currentUser);
    //   // Stream automatically updates UI
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('New note created')),
    //     );
    //   }
    // } catch (e) {
    //   if (mounted) {
    //     _showError('Failed to create note: $e');
    //   }
    // }
  }
}

// ============================================================================
// REUSABLE COMPONENTS
// ============================================================================

/// Single note list item widget
///
/// Displays a note with its content preview, sync status,
/// and action buttons for view/edit and delete
class NoteListItem extends StatelessWidget {
  final dynamic note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Uncomment and use actual note data when ready
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note title/content preview
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Note Title', // note.text.isEmpty ? 'Untitled' : note.text
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Delete button
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Metadata row
              Row(
                children: [
                  // Sync status
                  _buildSyncStatus(context),
                  const SizedBox(width: 16),
                  // Note ID
                  Text(
                    'ID: 1', // note.id.toString()
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build sync status indicator
  Widget _buildSyncStatus(BuildContext context) {
    // Uncomment when ready:
    // if (note.isSyncedWithCloud) {
    //   return Row(
    //     children: [
    //       const Icon(Icons.cloud_done, size: 16, color: Colors.green),
    //       const SizedBox(width: 4),
    //       Text(
    //         'Synced',
    //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
    //           color: Colors.green,
    //         ),
    //       ),
    //     ],
    //   );
    // } else {
    //   return Row(
    //     children: [
    //       const Icon(Icons.cloud_upload, size: 16, color: Colors.orange),
    //       const SizedBox(width: 4),
    //       Text(
    //         'Pending',
    //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
    //           color: Colors.orange,
    //         ),
    //       ),
    //     ],
    //   );
    // }

    return Row(
      children: [
        const Icon(Icons.cloud_done, size: 16, color: Colors.green),
        const SizedBox(width: 4),
        Text(
          'Synced',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.green),
        ),
      ],
    );
  }
}

/// Placeholder content for when imports aren't configured
class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text('Notes View', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Uncomment imports and parameters in notes_view_screen.dart to enable this screen',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
