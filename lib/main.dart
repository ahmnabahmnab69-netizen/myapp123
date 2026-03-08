import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_smart/background_service.dart';
import 'package:todo_smart/countdown_screen.dart';
import 'package:todo_smart/router.dart';
import 'package:window_manager/window_manager.dart';

part 'main.g.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Notification and Service Initialization ---
  await _initializeNotifications();
  if (!kIsWeb) {
    if (Platform.isAndroid || Platform.isIOS) {
      await initializeService();
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await windowManager.ensureInitialized();
        WindowOptions windowOptions = const WindowOptions(
        size: Size(400, 800),
        center: true,
        title: 'to-do smart',
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        });
    }
  }
  // ---------------------------------------------

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // Request permissions for iOS
  if (!kIsWeb && Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.cyan;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.orbitron(fontSize: 57, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: GoogleFonts.jura(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: GoogleFonts.jura(fontSize: 16, color: Colors.white70),
      labelLarge: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme.apply(bodyColor: Colors.black87, displayColor: Colors.black87),
      scaffoldBackgroundColor: Colors.grey.shade200,
      appBarTheme: AppBarTheme(
        titleTextStyle: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
        surface: Colors.black,
      ),
      textTheme: appTextTheme,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'to-do smart',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

@JsonSerializable()
class Task {
  final String title;
  final String time;
  final int xp;
  bool isCompleted;

  Task({required this.title, required this.time, required this.xp, this.isCompleted = false});

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

class User {
  final String name;
  final int totalXp;

  User({required this.name, required this.totalXp});
}

class _MyHomePageState extends State<MyHomePage> {
  List<Task> _tasks = [];
  int _totalXp = 0;

  final List<User> _users = [
    User(name: 'You', totalXp: 0),
    User(name: 'Alice', totalXp: 1250),
    User(name: 'Bob', totalXp: 900),
    User(name: 'Charlie', totalXp: 750),
    User(name: 'David', totalXp: 500),
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadXp();
  }

  Future<void> _loadXp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalXp = prefs.getInt('totalXp') ?? 0;
      _users[0] = User(name: 'You', totalXp: _totalXp);
    });
  }

  Future<void> _saveXp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalXp', _totalXp);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      setState(() {
        _tasks = tasksJson.map((taskJson) => Task.fromJson(json.decode(taskJson))).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((task) => json.encode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
    _saveTasks();
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
    _saveTasks();
  }

  void _onTaskCompletionChanged(Task task, bool isCompleted) {
    setState(() {
      task.isCompleted = isCompleted;
      if (isCompleted) {
        _totalXp += task.xp;
      } else {
        _totalXp -= task.xp;
      }
      _users[0] = User(name: 'You', totalXp: _totalXp);
    });
    _saveTasks();
    _saveXp();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [Colors.black, Colors.grey[900]!, Colors.black]
                : [Colors.grey.shade100, Colors.grey.shade300, Colors.grey.shade100],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              pinned: true,
              expandedHeight: 120.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('to-do smart', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface)),
                centerTitle: true,
              ),
              actions: [
                IconButton(
                  icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: 'Toggle Theme',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.go('/settings'),
                  tooltip: 'Settings',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 8,
                  shadowColor: theme.colorScheme.primary.withAlpha(100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total XP', style: theme.textTheme.bodyMedium),
                            Text('$_totalXp', style: theme.textTheme.displayLarge?.copyWith(fontSize: 40)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/leaderboard', extra: _users),
                          icon: const Icon(Icons.leaderboard_outlined),
                          label: Text('Leaderboard', style: theme.textTheme.labelLarge),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary.withAlpha(204),
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = _tasks[index];
                  return TaskCard(
                    task: task, 
                    onCompleted: (isCompleted) => _onTaskCompletionChanged(task, isCompleted),
                    onDeleted: () => _deleteTask(task),
                  );
                },
                childCount: _tasks.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!mounted) return;
          context.push('/add_task').then((result) {
            if (result != null && result is Task) {
              _addTask(result);
            }
          });
        },
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add Task',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class TaskCard extends StatefulWidget {
  final Task task;
  final ValueChanged<bool> onCompleted;
  final VoidCallback onDeleted;
  const TaskCard({super.key, required this.task, required this.onCompleted, required this.onDeleted});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ObjectKey(widget.task),
      onDismissed: (direction) {
        widget.onDeleted();
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Card(
          elevation: 5,
          shadowColor: Colors.black.withAlpha(128),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Checkbox(
              value: widget.task.isCompleted,
              onChanged: (bool? value) {
                setState(() {
                  widget.task.isCompleted = value!;
                });
                widget.onCompleted(value!);
              },
              shape: const CircleBorder(),
              activeColor: theme.colorScheme.primary,
            ),
            title: Text(
              widget.task.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                color: widget.task.isCompleted ? Colors.white54 : Colors.white,
              ),
            ),
            subtitle: Text(
              '${widget.task.time}  •  ${widget.task.xp} XP',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.task.isCompleted ? Colors.white38 : Colors.white70,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 30),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CountdownScreen(
                    task: widget.task,
                    onTaskCompleted: () {
                      if (mounted) {
                        setState(() {
                          widget.task.isCompleted = true;
                        });
                        widget.onCompleted(true);
                      }
                    },
                  ),
                ));
              },
            ),
          ),
        ),
      ),
    );
  }
}
