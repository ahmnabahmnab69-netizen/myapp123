import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_smart/main.dart';
import 'package:todo_smart/settings_screen.dart';


final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MyHomePage();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'leaderboard',
          builder: (BuildContext context, GoRouterState state) {
            final users = state.extra as List<User>? ?? [];
            return LeaderboardScreen(users: users);
          },
        ),
        GoRoute(
          path: 'add_task',
          builder: (BuildContext context, GoRouterState state) {
            return const AddTaskScreen();
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
      ],
    ),
  ],
);

class LeaderboardScreen extends StatelessWidget {
  final List<User> users;
  const LeaderboardScreen({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    users.sort((a, b) => b.totalXp.compareTo(a.totalXp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: Text('${index + 1}'),
            title: Text(user.name),
            trailing: Text('${user.totalXp} XP'),
          );
        },
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  final Map<String, int> _timeOptions = {
    '30 min': 10,
    '60 min': 20,
    '120 min': 30,
    '180 min': 40,
  };
  String? _selectedTimeValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Time'),
                hint: const Text('Select Time'),
                items: _timeOptions.keys.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeValue = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final xp = _timeOptions[_selectedTimeValue]!;
                    final task = Task(
                      title: _titleController.text,
                      time: _selectedTimeValue!,
                      xp: xp,
                    );
                    context.pop(task);
                  }
                },
                child: const Text('Add Task'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
