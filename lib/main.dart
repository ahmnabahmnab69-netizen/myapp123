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
import 'package:todo_smart/task_library.dart';
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
  final String id;
  final String title;
  final String time;
  final int xp;
  bool isCompleted;
  bool isCompletable;
  String? libraryId;

  Task({
    required this.id,
    required this.title, 
    required this.time, 
    required this.xp, 
    this.isCompleted = false,
    this.isCompletable = false,
    this.libraryId,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

class LevelingSystem {
  static const Map<int, int> levelThresholds = {
    1: 0,
    2: 250,
    3: 500,
    4: 750,
    5: 1000,
    6: 1250,
    7: 1500,
  };

  static int getLevel(int xp) {
    for (var i = levelThresholds.length; i >= 1; i--) {
      if (xp >= levelThresholds[i]!) {
        return i;
      }
    }
    return 1;
  }

  static int getXpForNextLevel(int currentLevel) {
    return levelThresholds[currentLevel + 1] ?? levelThresholds.values.last;
  }

  static int getXpForCurrentLevel(int currentLevel) {
    return levelThresholds[currentLevel] ?? 0;
  }
}

class User {
  final String name;
  final int totalXp;
  late final int level;

  User({required this.name, required this.totalXp}) {
    level = LevelingSystem.getLevel(totalXp);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<Task> _tasks = [];
  int _totalXp = 0;
  List<TaskLibrary> _libraries = [];

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
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    await _loadLibraries();
    await _loadTasksAndSyncStatus();
    await _loadXp();
  }


  Future<void> _loadXp() async {
    final prefs = await SharedPreferences.getInstance();
    if(mounted){
      setState(() {
        _totalXp = prefs.getInt('totalXp') ?? 0;
        _users[0] = User(name: 'You', totalXp: _totalXp);
      });
    }
  }

  Future<void> _saveXp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalXp', _totalXp);
  }

  Future<void> _loadLibraries() async {
    final prefs = await SharedPreferences.getInstance();
    final librariesJson = prefs.getStringList('libraries');
    if (librariesJson != null) {
      if(mounted){
        setState(() {
          _libraries = librariesJson
              .map((libJson) => TaskLibrary.fromJson(json.decode(libJson)))
              .toList();
        });
      }
    }
  }

  Future<void> _loadTasksAndSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      _tasks = tasksJson.map((taskJson) => Task.fromJson(json.decode(taskJson))).toList();
    }
    
    await _syncTaskStatus();
  }

  Future<void> _syncTaskStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedTaskTitles = prefs.getStringList('unlocked_task_titles') ?? [];
    
    if(mounted){
      setState(() {
        for (var task in _tasks) {
          if (unlockedTaskTitles.contains(task.title)) {
            task.isCompletable = true;
          }
        }
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((task) => json.encode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  void _addTask(Task task) {
    if(mounted){
      setState(() {
        _tasks.add(task);
      });
    }
    _saveTasks();
  }

  void _deleteTask(Task task) {
    if(mounted){
      setState(() {
        _tasks.remove(task);
      });
    }
    _saveTasks();
  }

  void _onTaskCompletionChanged(Task task, bool isCompleted) {
    if(mounted){
      setState(() {
        task.isCompleted = isCompleted;
        if (isCompleted) {
          _totalXp += task.xp;
        } else {
          _totalXp -= task.xp;
        }
        _users[0] = User(name: 'You', totalXp: _totalXp);
      });
    }
    _saveTasks();
    _saveXp();
  }
  
  void _handleFocus(Task task) async {
    TaskLibrary? library;
    if (task.libraryId != null) {
      library = _libraries.firstWhere((lib) => lib.id == task.libraryId);
    }
    _startFocusSession(task, library);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    final currentUser = _users[0];
    final currentLevel = LevelingSystem.getLevel(currentUser.totalXp);
    final xpForNextLevel = LevelingSystem.getXpForNextLevel(currentLevel);
    final xpForCurrentLevel = LevelingSystem.getXpForCurrentLevel(currentLevel);
    final progress = (currentUser.totalXp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);

    final List<Widget> slivers = [
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
            icon: const Icon(Icons.library_books_outlined),
            onPressed: () async {
              await context.push('/library_management');
              _loadEverything();
            },
            tooltip: 'Manage Libraries',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
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
              child: Column(
                children: [
                  Row(
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
                        onPressed: () => context.push('/leaderboard', extra: _users),
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
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Level $currentLevel', style: theme.textTheme.bodyMedium),
                          Text('$xpForNextLevel XP to Level ${currentLevel + 1}', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        backgroundColor: Colors.grey.shade700,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.list, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Tasks',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = _tasks[index];
              TaskLibrary? library;
              if (task.libraryId != null) {
                library = _libraries.firstWhere((lib) => lib.id == task.libraryId, orElse: () => TaskLibrary(id: '', name: 'Unknown Library'));
              }
              return TaskCard(
                task: task,
                library: library,
                onCompleted: (isCompleted) => _onTaskCompletionChanged(task, isCompleted),
                onDeleted: () => _deleteTask(task),
                onFocus: () => _handleFocus(task),
              );
            },
            childCount: _tasks.length,
          ),
        ),
    ];

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
          slivers: slivers,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add Task',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  void _showAddTaskDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final librariesJson = prefs.getStringList('libraries');
    List<TaskLibrary> libraries = [];
    if (librariesJson != null) {
      libraries = librariesJson
          .map((libJson) => TaskLibrary.fromJson(json.decode(libJson)))
          .toList();
    }

    final titleController = TextEditingController();
    String? selectedTime;
    TaskLibrary? selectedLibrary;

    final Map<String, int> timeXpMap = {
      '15 min': 10,
      '30 min': 20,
      '60 min': 40,
      '120 min': 80,
      '180 min': 120,
    };
    final List<String> timeOptions = timeXpMap.keys.toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: 'Task Title'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedTime,
                      hint: const Text('Select Time'),
                      isExpanded: true,
                      items: timeOptions.map((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTime = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a time' : null,
                    ),
                    const SizedBox(height: 20),
                    if (libraries.isNotEmpty)
                      DropdownButtonFormField<TaskLibrary?>(
                        initialValue: selectedLibrary,
                        hint: const Text('Assign to Library (Optional)'),
                        isExpanded: true,
                        items: libraries.map((TaskLibrary library) {
                          return DropdownMenuItem<TaskLibrary>(
                            value: library,
                            child: Text(library.name),
                          );
                        }).toList(),
                        onChanged: (TaskLibrary? newValue) {
                          setState(() {
                            selectedLibrary = newValue;
                          });
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && selectedTime != null) {
                  final int xp = timeXpMap[selectedTime!]!;
                  final newTask = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    time: selectedTime!,
                    xp: xp,
                    libraryId: selectedLibrary?.id,
                  );
                  _addTask(newTask);
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

  void _startFocusSession(Task task, TaskLibrary? library) async {
    if (library != null) {
      if(mounted){
        setState(() {
          task.libraryId = library.id;
        });
      }
      _saveTasks();
    }

    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CountdownScreen(task: task, library: library),
    ));
    await _syncTaskStatus();
  }
}

class TaskCard extends StatefulWidget {
  final Task task;
  final TaskLibrary? library;
  final ValueChanged<bool> onCompleted;
  final VoidCallback onDeleted;
  final VoidCallback onFocus;
  const TaskCard({
    super.key, 
    required this.task, 
    this.library,
    required this.onCompleted, 
    required this.onDeleted,
    required this.onFocus,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ObjectKey(widget.task.id),
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
              onChanged: widget.task.isCompletable ? (bool? value) {
                if(mounted){
                  setState(() {
                    widget.task.isCompleted = value!;
                  });
                }
                widget.onCompleted(value!);
              } : null,
              shape: const CircleBorder(),
              activeColor: theme.colorScheme.primary,
            ),
            title: Text(
              widget.task.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                color: widget.task.isCompleted ? (theme.brightness == Brightness.dark ? Colors.white54 : Colors.black54) : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.task.time}  •  ${widget.task.xp} XP',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.task.isCompleted ? (theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38) : null,
                  ),
                ),
                if (widget.library != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Library: ${widget.library!.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: widget.task.isCompleted ? (theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38) : null,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.play_circle_fill_rounded, color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54, size: 30),
              onPressed: widget.onFocus,
            ),
          ),
        ),
      ),
    );
  }
}
