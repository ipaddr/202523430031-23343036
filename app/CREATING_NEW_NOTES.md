# Creating New Notes - Implementation Guide

## Quick Start

Get your note creation feature working in **15 minutes** by following this practical guide.

---

## Required Setup

### 1. Ensure NoteService has createNote()
```dart
// lib/services/crud/crud/note_service.dart

Future<DatabaseNote> createNote({
  required String userId,
  required String content,
}) async {
  final note = DatabaseNote(
    id: uuid.v4(),
    userId: userId,
    text: content,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final db = await database;
  await db.insert('notes', note.toMap());
  
  _notifyNotesChanged(); // Trigger stream update
  return note;
}
```

---

## Implementation

### Create lib/screens/create_note_screen.dart

```dart
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/crud/crud/note_service.dart';

class CreateNoteScreen extends StatefulWidget {
  final NoteService noteService;
  final String userId;

  const CreateNoteScreen({
    Key? key,
    required this.noteService,
    required this.userId,
  }) : super(key: key);

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  late TextEditingController _contentController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _clearError() {
    setState(() => _errorMessage = null);
  }

  bool _validateForm() {
    _clearError();

    final content = _contentController.text.trim();

    if (content.isEmpty) {
      setState(() => _errorMessage = 'Please enter note content');
      return false;
    }

    if (content.length < 3) {
      setState(() => _errorMessage = 'Note must be at least 3 characters');
      return false;
    }

    if (content.length > 5000) {
      setState(() => _errorMessage = 'Note is too long');
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      await widget.noteService.createNote(
        userId: widget.userId,
        content: _contentController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Note created'),
          duration: Duration(seconds: 1),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildContentField(),
          const SizedBox(height: 24),
          if (_errorMessage != null) _buildError(),
          const SizedBox(height: 16),
          _buildCreateButton(),
          const SizedBox(height: 8),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: 8,
          minLines: 5,
          decoration: InputDecoration(
            hintText: 'Write your note...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Error',
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Text('Create'),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    );
  }
}
```

---

## Integration with NotesViewScreen

### Add to lib/screens/notes_view_screen.dart

**1. Add constructor parameter:**
```dart
class NotesViewScreen extends StatefulWidget {
  final NoteService noteService;
  final String userId; // Add this line

  const NotesViewScreen({
    Key? key,
    required this.noteService,
    required this.userId, // Add this line
  }) : super(key: key);

  // ... rest of code
}
```

**2. Add method to open create screen:**
```dart
void _openCreateNoteScreen() async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CreateNoteScreen(
        noteService: widget.noteService,
        userId: widget.userId,
      ),
    ),
  );

  if (result == true && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Added to your notes'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
```

**3. Update floating action button:**
```dart
Widget _buildFloatingActionButton() {
  return FloatingActionButton(
    onPressed: _openCreateNoteScreen,
    tooltip: 'New note',
    child: const Icon(Icons.add),
  );
}
```

---

## Using Named Routes (if applicable)

### Add to lib/routes/app_routes.dart
```dart
class AppRoutes {
  static const String home = '/';
  static const String createNote = '/create'; // Add this

  Map<String, WidgetBuilder> get routes {
    return {
      home: (_) => NotesViewScreen(
        noteService: noteService,
        userId: currentUserId,
      ),
      createNote: (_) => CreateNoteScreen( // Add this
        noteService: noteService,
        userId: currentUserId,
      ),
    };
  }
}
```

### Navigate using:
```dart
Navigator.of(context).pushNamed(AppRoutes.createNote);
```

---

## Using GoRouter (if applicable)

### Add to GoRouter configuration:
```dart
GoRoute(
  path: 'create',
  builder: (context, state) => CreateNoteScreen(
    noteService: getIt<NoteService>(),
    userId: authProvider.currentUserId!,
  ),
),
```

### Navigate using:
```dart
context.push('/notes/create');
```

---

## How It Works

1. **User taps FAB** → opens CreateNoteScreen
2. **User enters content** → validation checks length/content
3. **User taps Create** → calls `noteService.createNote()`
4. **NoteService saves** → inserts to database
5. **NoteService notifies** → calls `_notifyNotesChanged()`
6. **Stream updates** → emits new `List<DatabaseNote>`
7. **NotesViewScreen rebuilds** → StreamBuilder gets new data
8. **User sees new note** → automatically added to list
9. **CreateNoteScreen closes** → pops with result=true

---

## Common Patterns

### Pattern 1: Simple Error Handling
```dart
try {
  await widget.noteService.createNote(
    userId: widget.userId,
    content: content,
  );
  Navigator.pop(context);
} catch (e) {
  _showError('Failed: $e');
}
```

### Pattern 2: Loading with Spinner
```dart
setState(() => _isLoading = true);
try {
  // ... do work
} finally {
  setState(() => _isLoading = false);
}
```

### Pattern 3: Validation
```dart
if (content.isEmpty) {
  _showError('Content required');
  return;
}
```

---

## Troubleshooting

### Issue: "Note not appearing in list"
**Solution:** Check that `createNote()` calls `_notifyNotesChanged()`

### Issue: "Context is null after navigation"
**Solution:** Always check `if (!mounted)` before setState

### Issue: "Loading spinner stuck"
**Solution:** Ensure finally block runs to clear `_isLoading`

### Issue: "Duplicate notes on creation"
**Solution:** Make sure NotesViewScreen uses StreamBuilder (not manual subscription)

### Issue: "Can't pass userId"
**Solution:** Get userId from:
- Authentication provider (Provider, Riverpod, etc.)
- Auth context (FirebaseAuth)
- Route arguments
- Parent widget constructor

---

## Testing

```dart
// Unit test example
testWidgets('Create note successfully', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CreateNoteScreen(
        noteService: mockNoteService,
        userId: 'test-user',
      ),
    ),
  );

  // Type content
  await tester.enterText(find.byType(TextField), 'Test note');

  // Tap create
  await tester.tap(find.text('Create'));
  await tester.pumpAndSettle();

  // Verify navigation
  expect(find.byType(CreateNoteScreen), findsNothing);
});
```

---

## Files to Create/Modify

| File | Action | Details |
|------|--------|---------|
| `lib/screens/create_note_screen.dart` | **Create** | New CreateNoteScreen widget |
| `lib/screens/notes_view_screen.dart` | **Modify** | Add userId param, add _openCreateNoteScreen() method, update FAB |
| `lib/routes/app_routes.dart` | **Modify** | Add createNote route |

---

## Checklist

- [ ] Create `create_note_screen.dart`
- [ ] Add userId to NotesViewScreen constructor
- [ ] Add `_openCreateNoteScreen()` method
- [ ] Update floating action button
- [ ] Update app_routes.dart
- [ ] Import CreateNoteScreen in routes/screens
- [ ] Test creating a note
- [ ] Verify note appears in list immediately
- [ ] Test error validation
- [ ] Test cancel button

---

## Next Steps

1. Copy the complete CreateNoteScreen code above
2. Update NotesViewScreen with the 3 modifications
3. Run `flutter pub get` if you added new imports
4. Test creating a new note
5. Verify stream updates the list automatically

**That's it!** Your note creation feature is ready.

---

**Related:**
- [PREPARING_CREATE_NOTES.md](PREPARING_CREATE_NOTES.md) - Detailed guide with architecture
- [NOTES_VIEW_QUICK_START.md](NOTES_VIEW_QUICK_START.md) - Quick reference
- [STREAMS_COMPLETE_IMPLEMENTATION.md](STREAMS_COMPLETE_IMPLEMENTATION.md) - Stream architecture deep dive
