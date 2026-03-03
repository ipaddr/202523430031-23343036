/// Examples and patterns for implementing NoteService with Streams
///
/// This file contains commented examples showing various patterns for using
/// the NoteService stream functionality in Flutter widgets.
///
/// Key Concepts:
/// - StreamBuilder for automatic stream management
/// - Error and loading state handling
/// - Multiple stream patterns
/// - CRUD operations with stream updates

import 'package:flutter/material.dart';

// ============================================================================
// EXAMPLE 1: Basic StreamBuilder Pattern (RECOMMENDED)
// ============================================================================
//
// Uncomment and customize with your actual imports:
//
// import 'package:your_app/services/crud/crud/note_service.dart';
//
// class NotesListExample extends StatelessWidget {
//   final NoteService noteService;
//
//   const NotesListExample({
//     Key? key,
//     required this.noteService,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('My Notes')),
//       body: StreamBuilder<List<DatabaseNote>>(
//         stream: noteService.allNotesStream,
//         builder: (context, snapshot) {
//           // Handle connection state while loading
//           if (snapshot.connectionState == ConnectionState.waiting &&
//               snapshot.data == null) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           // Handle error state
//           if (snapshot.hasError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error, size: 48, color: Colors.red),
//                   const SizedBox(height: 16),
//                   Text('Error: ${snapshot.error}'),
//                 ],
//               ),
//             );
//           }
//
//           // Handle empty state
//           final notes = snapshot.data ?? [];
//           if (notes.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.note_rounded, size: 64, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text('No notes yet'),
//                 ],
//               ),
//             );
//           }
//
//           // Display notes list
//           return ListView.builder(
//             itemCount: notes.length,
//             itemBuilder: (context, index) {
//               final note = notes[index];
//               return ListTile(
//                 title: Text(note.text.isEmpty ? 'Untitled' : note.text),
//                 trailing: note.isSyncedWithCloud
//                     ? const Icon(Icons.cloud_done, color: Colors.green)
//                     : const Icon(Icons.cloud_upload, color: Colors.orange),
//                 onTap: () {
//                   // Handle note tap - navigate to edit screen
//                 },
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           try {
//             // Create new note - stream automatically updates
//             await noteService.createNote(owner: currentUser);
//             // No need to call setState - stream handles it!
//           } catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Error: $e')),
//             );
//           }
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

// ============================================================================
// EXAMPLE 2: Stream with Search/Filter
// ============================================================================
//
// Use a search controller with Rx.combineLatest to filter streams:
//
// import 'rxdart/rxdart.dart';
//
// class SearchableNotesExample extends StatefulWidget {
//   final NoteService noteService;
//
//   const SearchableNotesExample({required this.noteService});
//
//   @override
//   State<SearchableNotesExample> createState() =>
//       _SearchableNotesExampleState();
// }
//
// class _SearchableNotesExampleState extends State<SearchableNotesExample> {
//   final _searchController = StreamController<String>();
//
//   Stream<List<DatabaseNote>> get _filteredNotes =>
//       Rx.combineLatest2(
//         widget.noteService.allNotesStream,
//         _searchController.stream.startWith(''),
//         (List<DatabaseNote> notes, String query) {
//           if (query.isEmpty) return notes;
//           return notes
//               .where((note) =>
//                   note.text.toLowerCase().contains(query.toLowerCase()))
//               .toList();
//         },
//       );
//
//   @override
//   void dispose() {
//     _searchController.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           onChanged: _searchController.add,
//           decoration: const InputDecoration(
//             hintText: 'Search notes...',
//             border: InputBorder.none,
//           ),
//         ),
//       ),
//       body: StreamBuilder<List<DatabaseNote>>(
//         stream: _filteredNotes,
//         builder: (context, snapshot) {
//           // ... same pattern as Example 1
//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }
// }

// ============================================================================
// EXAMPLE 3: Multiple Streams with Statistics
// ============================================================================
//
// Combine streams to show statistics alongside data:
//
// class NotesWithStatsExample extends StatelessWidget {
//   final NoteService noteService;
//
//   const NotesWithStatsExample({required this.noteService});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Statistics card
//         StreamBuilder<List<DatabaseNote>>(
//           stream: noteService.allNotesStream,
//           builder: (context, snapshot) {
//             final notes = snapshot.data ?? [];
//             final synced = notes.where((n) => n.isSyncedWithCloud).length;
//
//             return Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     Column(children: [
//                       Text('${notes.length}'),
//                       const Text('Total'),
//                     ]),
//                     Column(children: [
//                       Text('$synced'),
//                       const Text('Synced'),
//                     ]),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//         // Notes list
//         Expanded(
//           child: StreamBuilder<List<DatabaseNote>>(
//             stream: noteService.allNotesStream,
//             builder: (context, snapshot) {
//               // ... list implementation
//               return const SizedBox.shrink();
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// ============================================================================
// EXAMPLE 4: Error Handling Best Practices
// ============================================================================
//
// Complete error handling example:
//
// StreamBuilder<List<DatabaseNote>>(
//   stream: noteService.allNotesStream,
//   builder: (context, snapshot) {
//     // Check for connection state first
//     switch (snapshot.connectionState) {
//       case ConnectionState.none:
//         return const Text('Not connected');
//       case ConnectionState.waiting:
//         if (!snapshot.hasData) {
//           return const CircularProgressIndicator();
//         }
//         // Fall through to show previous data while loading
//         break;
//       case ConnectionState.active:
//       case ConnectionState.done:
//         break;
//     }
//
//     // Handle errors
//     if (snapshot.hasError) {
//       return ErrorWidget(error: snapshot.error);
//     }
//
//     // Build UI with data
//     final notes = snapshot.data ?? [];
//     return buildNotesList(notes);
//   },
// )

// ============================================================================
// HELPER: Reusable Error Widget
// ============================================================================

class StreamErrorWidget extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const StreamErrorWidget({Key? key, this.error, this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER: Reusable Loading Widget
// ============================================================================

class StreamLoadingWidget extends StatelessWidget {
  final String message;

  const StreamLoadingWidget({Key? key, this.message = 'Loading...'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER: Reusable Empty State Widget
// ============================================================================

class StreamEmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const StreamEmptyWidget({
    Key? key,
    this.message = 'No data available',
    this.icon = Icons.inbox,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

// ============================================================================
// TIPS FOR USING STREAMS EFFECTIVELY
// ============================================================================
//
// 1. ALWAYS use StreamBuilder for automatic subscription management
//    - Don't manually subscribe unless you have a specific reason
//    - StreamBuilder auto-cancels when widget is disposed
//
// 2. REMEMBER: onData callbacks need null coalescing
//    ```dart
//    final notes = snapshot.data ?? [];  // Handle null case
//    ```
//
// 3. CHECK connectionState before assuming data
//    - While loading, snapshot.data might be stale
//    - Use snapshot.connectionState == ConnectionState.waiting
//
// 4. HANDLE ALL STATES: loading, error, empty, data
//    - Users need feedback about what's happening
//    - At minimum show loading and error states
//
// 5. USE .distinct() for performance if needed
//    ```dart
//    stream: noteService.allNotesStream.distinct()
//    ```
//
// 6. CREATE temporary streams for filtering
//    - Don't modify the original service stream
//    - Map/filter/where in the widget layer
//
// 7. LEVERAGE Rx combinators from package:rxdart
//    - Rx.combineLatest for multiple streams
//    - Rx.merge for combining streams
//    - debounce/throttle for user input
//
// For more examples and implementation details, see the other example files
// in this directory.
