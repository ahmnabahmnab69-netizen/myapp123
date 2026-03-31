import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_smart/task_library.dart';

class LibraryManagementScreen extends StatefulWidget {
  const LibraryManagementScreen({super.key});

  @override
  State<LibraryManagementScreen> createState() =>
      _LibraryManagementScreenState();
}

class _LibraryManagementScreenState extends State<LibraryManagementScreen> {
  List<TaskLibrary> _libraries = [];
  final TextEditingController _libraryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLibraries();
  }

  Future<void> _loadLibraries() async {
    final prefs = await SharedPreferences.getInstance();
    final librariesJson = prefs.getStringList('libraries');
    if (librariesJson != null) {
      setState(() {
        _libraries = librariesJson
            .map((libJson) => TaskLibrary.fromJson(json.decode(libJson)))
            .toList();
      });
    }
  }

  Future<void> _saveLibraries() async {
    final prefs = await SharedPreferences.getInstance();
    final librariesJson =
        _libraries.map((lib) => json.encode(lib.toJson())).toList();
    await prefs.setStringList('libraries', librariesJson);
  }

  void _addLibrary(String name) {
    setState(() {
      _libraries.add(TaskLibrary(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name));
    });
    _saveLibraries();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Library "$name" added.')),
    );
  }

  void _deleteLibrary(TaskLibrary library) {
    final libraryName = library.name;
    setState(() {
      _libraries.remove(library);
    });
    _saveLibraries();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Library "$libraryName" deleted.')),
    );
  }

  void _showAddLibraryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Library'),
          content: TextField(
            controller: _libraryNameController,
            decoration: const InputDecoration(hintText: 'Library Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _libraryNameController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_libraryNameController.text.isNotEmpty) {
                  _addLibrary(_libraryNameController.text);
                  _libraryNameController.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Libraries'),
      ),
      body: ListView.builder(
        itemCount: _libraries.length,
        itemBuilder: (context, index) {
          final library = _libraries[index];
          return ListTile(
            title: Text(library.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteLibrary(library),
              tooltip: 'Delete Library',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLibraryDialog,
        tooltip: 'Add Library',
        child: const Icon(Icons.add),
      ),
    );
  }
}
