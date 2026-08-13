import 'package:flutter/material.dart';

void main() {
  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const NotesScreen(),
      },
    );
  }
}

class Note {
  final String id;
  String title;
  String content;
  DateTime lastModified;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.lastModified,
  });
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> _notes = [];
  Note? _selectedNote;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isMobileView = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _createNewNote() {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Note',
      content: '',
      lastModified: DateTime.now(),
    );
    setState(() {
      _notes.insert(0, newNote);
      _selectNote(newNote);
    });
    
    if (_isMobileView) {
      _navigateToMobileEditor();
    }
  }

  void _selectNote(Note note) {
    setState(() {
      _selectedNote = note;
      _titleController.text = note.title;
      _contentController.text = note.content;
    });
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
      if (_selectedNote?.id == note.id) {
        _selectedNote = null;
      }
    });
  }

  void _updateCurrentNote() {
    if (_selectedNote != null) {
      setState(() {
        _selectedNote!.title = _titleController.text.isNotEmpty ? _titleController.text : 'Untitled Note';
        _selectedNote!.content = _contentController.text;
        _selectedNote!.lastModified = DateTime.now();
        // Move to top
        _notes.remove(_selectedNote);
        _notes.insert(0, _selectedNote!);
      });
    }
  }

  void _navigateToMobileEditor() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MobileEditorScreen(
        titleController: _titleController,
        contentController: _contentController,
        onChanged: _updateCurrentNote,
        onDelete: () {
          if (_selectedNote != null) {
            _deleteNote(_selectedNote!);
            Navigator.of(context).pop();
          }
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Note',
            onPressed: _createNewNote,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _isMobileView = constraints.maxWidth < 600;

          if (_isMobileView) {
            return _buildNotesList();
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildNotesList(),
                  ),
                ),
                Expanded(
                  child: _selectedNote == null
                      ? const Center(
                          child: Text(
                            'Select or create a note',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : _buildDesktopEditor(),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: _isMobileView
          ? FloatingActionButton(
              onPressed: _createNewNote,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildNotesList() {
    if (_notes.isEmpty) {
      return const Center(child: Text('No notes yet.'));
    }

    return ListView.builder(
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        final isSelected = !_isMobileView && _selectedNote?.id == note.id;

        return ListTile(
          title: Text(
            note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${note.lastModified.toLocal().toString().split('.')[0]}\n${note.content}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          onTap: () {
            _selectNote(note);
            if (_isMobileView) {
              _navigateToMobileEditor();
            }
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteNote(note),
          ),
        );
      },
    );
  }

  Widget _buildDesktopEditor() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              hintText: 'Note Title',
              border: InputBorder.none,
            ),
            onChanged: (_) => _updateCurrentNote(),
          ),
          const Divider(),
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Start typing your note here...',
                border: InputBorder.none,
              ),
              onChanged: (_) => _updateCurrentNote(),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileEditorScreen extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const MobileEditorScreen({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  hintText: 'Note Title',
                  border: InputBorder.none,
                ),
                onChanged: (_) => onChanged(),
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  expands: true,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Start typing...',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
