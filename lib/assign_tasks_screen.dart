import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_smart/task.dart';
import 'package:todo_smart/task_library.dart';

class AssignTasksScreen extends StatefulWidget {
  final TaskLibrary library;

  const AssignTasksScreen({super.key, required this.library});

  @override
  State<AssignTasksScreen> createState() => _AssignTasksScreenState();
}

class _AssignTasksScreenState extends State<AssignTasksScreen> {
  List<Task> _unassignedTasks = [];
  final Set<String> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadUnassignedTasks();
  }

  Future<void> _loadUnassignedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      final allTasks = tasksJson
          .map((taskJson) => Task.fromJson(json.decode(taskJson)))
          .toList();
      if(mounted){
        setState(() {
          _unassignedTasks = allTasks
              .where((task) => task.libraryId == null)
              .toList();
        });
      }
    }
  }

  Future<void> _assignTasksToLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      List<Task> allTasks = tasksJson
          .map((taskJson) => Task.fromJson(json.decode(taskJson)))
          .toList();

      for (final taskId in _selectedTaskIds) {
        final taskIndex = allTasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) {
          allTasks[taskIndex].libraryId = widget.library.id;
        }
      }

      final updatedTasksJson = allTasks
          .map((t) => json.encode(t.toJson()))
          .toList();
      await prefs.setStringList('tasks', updatedTasksJson);
    }
    if (mounted) {
      context.pop(true); // Return true to indicate a change was made
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [Colors.black, Colors.grey[900]!, Colors.black]
                : [
                    Colors.grey.shade100,
                    Colors.grey.shade300,
                    Colors.grey.shade100,
                  ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Add Tasks to ${widget.library.name}'),
              titleTextStyle: theme.textTheme.titleLarge?.copyWith(fontSize: 20, color: theme.colorScheme.onSurface),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
            ),
            _unassignedTasks.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No unassigned tasks available.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = _unassignedTasks[index];
                      final isSelected = _selectedTaskIds.contains(task.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Card(
                          elevation: 5,
                          shadowColor: Colors.black.withAlpha(128),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedTaskIds.add(task.id);
                                } else {
                                  _selectedTaskIds.remove(task.id);
                                }
                              });
                            },
                            title: Text(
                              task.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              '${task.time}  •  ${task.xp} XP',
                              style: theme.textTheme.bodyMedium,
                            ),
                            activeColor: theme.colorScheme.primary,
                            checkboxShape: const CircleBorder(),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      );
                    },
                    childCount: _unassignedTasks.length,
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: _selectedTaskIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _assignTasksToLibrary,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: Text(
                'Assign ${_selectedTaskIds.length} Tasks',
                style: theme.textTheme.labelLarge,
              ),
              backgroundColor: theme.colorScheme.primary,
            )
          : null,
    );
  }
}
