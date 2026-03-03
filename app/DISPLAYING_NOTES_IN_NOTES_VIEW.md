# Displaying Notes in Notes View

## Overview

This guide shows you how to display notes from your database in the NotesViewScreen using the Stream-based architecture.

**What you'll implement:**
- StreamBuilder to listen for note updates
- Display notes in a ListView
- Handle loading, empty, and error states
- Show note metadata (created date, content preview)
- Implement note selection and actions

---

## Architecture

```
NoteService.allNotesStream
        │
        ├─→ Emits List<DatabaseNote>
        │
        ▼
   StreamBuilder
        │
        ├─→ listening: true (rebuilds on new data)
        │
        ├─→ Snapshot.connectionState
        │   ├─ waiting → Loading spinner
        │   ├─ done → Display notes / empty message
        │   └─ error → Error message
        │
        ▼
   ListView of NoteListItems
        │
        └─→ Each note shows:
            ├─ Title/preview
            ├─ Created date
            ├─ Action buttons
            └─ Sync status
```

---

## Step 1: Update NotesViewScreen Constructor

**File: lib/screens/notes_view_screen.dart**

Ensure your screen receives NoteService and userId:

```dart
class NotesViewScreen extends StatefulWidget {
  final NoteService noteService;
  final String userId;

  const NotesViewScreen({
    Key? key,
    required this.noteService,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotesViewScreen> createState() => _NotesViewScreenState();
}
```

---

## Step 2: Create StreamBuilder

**In _buildBody() method:**

```dart
Widget _buildBody() {
  return StreamBuilder<List<DatabaseNote>>(
    stream: widget.noteService.allNotesStream,
    builder: (context, snapshot) {
      // Handle connection states
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingState();
      }

      // Handle errors
      if (snapshot.hasError) {
        return _buildErrorState(snapshot.error);
      }

      // Handle no data
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return _buildEmptyState();
      }

      // Display notes
      final notes = snapshot.data!;
      return _buildNotesList(notes);
    },
  );
}
```

---

## Step 3: Build State Widgets

### Loading State
```dart
Widget _buildLoadingState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('Loading your notes...'),
      ],
    ),
  );
}
```

### Error State
```dart
Widget _buildErrorState(Object? error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'Error loading notes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _retryLoadNotes,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

void _retryLoadNotes() {
  // Trigger a refresh by rebuilding the stream
  setState(() {});
}
```

### Empty State
```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.note_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No notes yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Create your first note to get started',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _openCreateNoteScreen,
          icon: const Icon(Icons.add),
          label: const Text('Create Note'),
        ),
      ],
    ),
  );
}
```

---

## Step 4: Build Notes List

```dart
Widget _buildNotesList(List<DatabaseNote> notes) {
  return RefreshIndicator(
    onRefresh: () async {
      // Force refresh if needed
      await Future.delayed(const Duration(milliseconds: 500));
    },
    child: ListView.builder(
      itemCount: notes.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteListItem(
          note: note,
          onTap: () => _viewNote(note),
          onDelete: () => _deleteNote(note),
        );
      },
    ),
  );
}
```

---

## Step 5: NoteListItem Widget

Create **lib/widgets/note_list_item.dart**:

```dart
import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NoteListItem extends StatelessWidget {
  final DatabaseNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _getPreview() {
    final text = note.text.replaceAll('\n', ' ').trim();
    if (text.length > 100) {
      return '${text.substring(0, 100)}...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title/Preview
              Text(
                _getPreview().isEmpty ? 'Untitled note' : _getPreview(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),

              // Metadata row
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const Spacer(),

                  // Sync status
                  Icon(
                    Icons.cloud_done,
                    size: 16,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Synced',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade400,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Step 6: Add Click Handlers

Add these methods to _NotesViewScreenState:

```dart
void _viewNote(DatabaseNote note) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => NoteDetailScreen(
        note: note,
        noteService: widget.noteService,
      ),
    ),
  );
}

Future<void> _deleteNote(DatabaseNote note) async {
  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Note?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    await widget.noteService.deleteNote(noteId: note.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Note deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void _openCreateNoteScreen() async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CreateNoteScreen(
        noteService: widget.noteService,
        userId: widget.userId,
      ),
    ),
  );
}
```

---

## Step 7: Complete NotesViewScreen

Here's the full implementation:

```dart
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/crud/crud/note_service.dart';
import '../widgets/note_list_item.dart';
import 'create_note_screen.dart';
// import 'note_detail_screen.dart'; // When you create this

class NotesViewScreen extends StatefulWidget {
  final NoteService noteService;
  final String userId;

  const NotesViewScreen({
    Key? key,
    required this.noteService,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotesViewScreen> createState() => _NotesViewScreenState();
}

class _NotesViewScreenState extends State<NotesViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('My Notes'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tap a note to edit it'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<DatabaseNote>>(
      stream: widget.noteService.allNotesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        return _buildNotesList(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading your notes...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryLoadNotes,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first note to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreateNoteScreen,
            icon: const Icon(Icons.add),
            label: const Text('Create Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<DatabaseNote> notes) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        itemCount: notes.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteListItem(
            note: note,
            onTap: () => _viewNote(note),
            onDelete: () => _deleteNote(note),
          );
        },
      ),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _openCreateNoteScreen,
      tooltip: 'New note',
      child: const Icon(Icons.add),
    );
  }

  void _retryLoadNotes() {
    setState(() {});
  }

  void _viewNote(DatabaseNote note) {
    // TODO: Navigate to NoteDetailScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note detail view - Coming soon')),
    );
  }

  Future<void> _deleteNote(DatabaseNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.noteService.deleteNote(noteId: note.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Note deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openCreateNoteScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateNoteScreen(
          noteService: widget.noteService,
          userId: widget.userId,
        ),
      ),
    );
  }
}
```

---

## Files to Create/Modify

| File | Action | Details |
|------|--------|---------|
| `lib/screens/notes_view_screen.dart` | **Modify/Create** | Complete NotesViewScreen implementation with StreamBuilder |
| `lib/widgets/note_list_item.dart` | **Create** | NoteListItem widget for display |
| `lib/screens/create_note_screen.dart` | **Create** | CreateNoteScreen (from CREATING_NEW_NOTES.md) |

---

## Key Features Explained

### StreamBuilder
```dart
StreamBuilder<List<DatabaseNote>>(
  stream: widget.noteService.allNotesStream,
  builder: (context, snapshot) {
    // Rebuilds automatically when stream emits
  },
)
```
- Listens to `noteService.allNotesStream`
- Rebuilds whenever a new list is emitted
- Automatically handles subscription/cleanup

### Connection States
```dart
snapshot.connectionState == ConnectionState.waiting  // Loading
snapshot.connectionState == ConnectionState.done     // Data ready
snapshot.hasError                                     // Error occurred
snapshot.hasData                                      // Data available
```

### Date Formatting
```dart
'Just now'      // Less than 1 minute
'5m ago'        // Minutes
'2h ago'        // Hours
'3d ago'        // Days
'3/4/2026'      // Older dates
```

### Sync Status
```dart
Icon(Icons.cloud_done, color: Colors.green)  // Synced
Icon(Icons.cloud_upload, color: Colors.orange) // Pending
Icon(Icons.cloud_off, color: Colors.red)     // Offline
```

---

## Testing Checklist

- [ ] App starts with empty state message
- [ ] Create a note via CreateNoteScreen
- [ ] New note appears in list immediately (via Stream)
- [ ] Note shows correct preview text
- [ ] Note shows correct date (e.g., "Just now")
- [ ] Tap note (should show detail view or TODO message)
- [ ] Delete note - shows confirmation dialog
- [ ] Confirm delete - note disappears from list
- [ ] Pull to refresh works
- [ ] Loading spinner shows briefly on app start
- [ ] Error message shows for database errors

---

## Performance Tips

1. **Use const constructors** where possible (NoteListItem is already const)
2. **Limit list items** - consider pagination for large notes
3. **Cache formatted dates** if you have many items
4. **Use `.distinct()`** on stream if emitting duplicate lists
5. **Avoid rebuilding entire list** - use `key:` for items

---

## Troubleshooting

### Issue: "Notes not showing"
**Check:**
- Is `allNotesStream` being emitted?
- Does `NoteService.createNote()` call `_notifyNotesChanged()`?
- Is StreamBuilder connected to correct stream?

### Issue: "List not updating after creating note"
**Check:**
- Is `_notifyNotesChanged()` being called?
- Is the new note's `userId` matching current user?
- Is StreamBuilder listening to correct stream?

### Issue: "Loading spinner stuck"
**Check:**
- Is database query completing?
- Check for uncaught exceptions in database

### Issue: "Memory leak or stream not closing"
**Check:**
- StreamBuilder automatically handles cleanup
- No manual `subscription` variable needed

---

## Next Steps

1. Create/update `notes_view_screen.dart` with StreamBuilder
2. Create `lib/widgets/note_list_item.dart`
3. Run the app and test creating/viewing notes
4. Create `NoteDetailScreen` next (for editing notes)

---

**Related Documentation:**
- [CREATING_NEW_NOTES.md](CREATING_NEW_NOTES.md) - Create feature
- [STREAMS_GUIDE.md](STREAMS_GUIDE.md) - Stream fundamentals
- [STREAMS_COMPLETE_IMPLEMENTATION.md](STREAMS_COMPLETE_IMPLEMENTATION.md) - Architecture detail
