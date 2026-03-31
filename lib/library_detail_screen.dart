import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_smart/main.dart';
import 'package:todo_smart/task_library.dart';

class LibraryDetailScreen extends StatefulWidget {
  final TaskLibrary library;

  const LibraryDetailScreen({super.key, required this.library});

  @override
  State<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends State<LibraryDetailScreen> {
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      final allTasks = tasksJson
          .map((taskJson) => Task.fromJson(json.decode(taskJson)))
          .toList();
      setState(() {
        _tasks = allTasks
            .where((task) => task.libraryId == widget.library.id)
            .toList();
      });
    }
  }

  Future<void> _removeTaskFromLibrary(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      final allTasks = tasksJson
          .map((taskJson) => Task.fromJson(json.decode(taskJson)))
          .toList();
      final taskIndex = allTasks.indexWhere((t) => t.title == task.title); // Assuming titles are unique for now
      if (taskIndex != -1) {
        allTasks[taskIndex].libraryId = null;
        final updatedTasksJson =
            allTasks.map((t) => json.encode(t.toJson())).toList();
        await prefs.setStringList('tasks', updatedTasksJson);
        _loadTasks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.library.name, style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(task.title, style: theme.textTheme.bodyMedium),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeTaskFromLibrary(task),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/assign_tasks', extra: widget.library);
          if (mounted) {
            _loadTasks();
          }
        },
        child: const Icon(Icons.add_task),
      ),
    );
  }
}
