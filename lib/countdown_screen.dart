import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_smart/main.dart';
import 'package:todo_smart/task_library.dart';
import 'package:window_manager/window_manager.dart';

class CountdownScreen extends StatefulWidget {
  final Task task;
  final TaskLibrary? library;

  const CountdownScreen({super.key, required this.task, this.library});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  final FlutterBackgroundService _service = FlutterBackgroundService();
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  String _currentQuote = 'Loading quotes...';
  List<String> _quotes = [];
  int _lastQuoteIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _initializeTimer();

    if (!kIsWeb) {
      _serviceSubscription = _service.on('update').listen((event) {
        if (event != null && event.containsKey('remainingSeconds')) {
          final int seconds = event['remainingSeconds'];
          if (seconds <= 0) {
            _onTimerFinish();
          } else {
            if (mounted) {
              setState(() {
                _remainingSeconds = seconds;
              });
            }
          }
        }
      });
    }
  }

  Future<void> _loadQuotes() async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      if (!mounted) return;

      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final quoteFiles = manifestMap.keys.where((String key) => key.startsWith('assets/quotes/')).toList();

      List<String>? quotesList;
      if (quoteFiles.isNotEmpty) {
        final randomFile = quoteFiles[Random().nextInt(quoteFiles.length)];
        final quotesString = await DefaultAssetBundle.of(context).loadString(randomFile);
        quotesList = LineSplitter.split(quotesString).where((q) => q.trim().isNotEmpty).toList();
      }

      if (!mounted) return;

      if (quotesList != null && quotesList.isNotEmpty) {
        if (mounted) {
          setState(() {
            _quotes = quotesList!;
            _changeQuote();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentQuote = 'No quotes found.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentQuote = 'Could not load quotes.';
        });
      }
    }
  }

  void _changeQuote() {
    if (_quotes.isEmpty) return;
    final random = Random();
    int nextIndex;
    do {
      nextIndex = random.nextInt(_quotes.length);
    } while (nextIndex == _lastQuoteIndex && _quotes.length > 1);

    if (mounted) {
      setState(() {
        _currentQuote = _quotes[nextIndex];
        _lastQuoteIndex = nextIndex;
      });
    }
  }

  Future<void> _initializeTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = prefs.getInt('countdown_end_time');
    final runningTask = prefs.getString('running_task');

    if (endTime != null && runningTask == widget.task.id) {
      final remaining = (endTime - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
      if (remaining > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds = remaining;
            _isTimerRunning = true;
          });
        }
        if (kIsWeb) {
          _startWebTimer(isResuming: true);
        }
      } else {
        _clearStoredTimer();
      }
    } else {
      _remainingSeconds = _parseDuration(widget.task.time);
    }
  }

  void _startTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('manually_stopped'); // Clear flag on new timer start

    final duration = _parseDuration(widget.task.time);
    final endTime = DateTime.now().millisecondsSinceEpoch + duration * 1000;
    await prefs.setInt('countdown_end_time', endTime);
    await prefs.setString('running_task', widget.task.id);

    if (mounted) {
      setState(() {
        _isTimerRunning = true;
        _remainingSeconds = duration;
      });
    }

    if (kIsWeb) {
      _startWebTimer();
    } else {
      if (defaultTargetPlatform != TargetPlatform.android) {
        windowManager.setAlwaysOnTop(true);
      }
      _service.startService();
      _service.invoke('start', {'endTime': endTime});
    }

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isTimerRunning) {
        _changeQuote();
      } else {
        timer.cancel();
      }
    });
  }

  void _startWebTimer({bool isResuming = false}) {
    if (!isResuming) {
      _remainingSeconds = (_parseDuration(widget.task.time));
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _onTimerFinish();
      }
    });
  }

  int _parseDuration(String time) {
    final parts = time.split(' ');
    final value = int.tryParse(parts[0]) ?? 0;
    if (parts[1].startsWith('min')) {
      return value * 60;
    } else if (parts[1].startsWith('hour')) {
      return value * 3600;
    }
    return value;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<void> _clearStoredTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('countdown_end_time');
    await prefs.remove('running_task');
  }

  void _stopTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('manually_stopped', true);

    await _clearStoredTimer();
    _timer?.cancel();

    if (!kIsWeb) {
      if (defaultTargetPlatform != TargetPlatform.android) {
        windowManager.setAlwaysOnTop(false);
      }
      _service.invoke('stop');
    }

    if (mounted) {
      setState(() {
        _isTimerRunning = false;
        _remainingSeconds = _parseDuration(widget.task.time);
      });
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _serviceSubscription?.cancel();
    super.dispose();
  }

  void _onTimerFinish() async {
    final prefs = await SharedPreferences.getInstance();
    final wasManuallyStopped = prefs.getBool('manually_stopped') ?? false;

    // If it was manually stopped, just clean up the flag and exit without doing anything else.
    if (wasManuallyStopped) {
      await prefs.remove('manually_stopped');
      _timer?.cancel();
      await _clearStoredTimer();
      return;
    }

    // --- Normal Timer Completion Logic ---
    _timer?.cancel();
    await _clearStoredTimer();

    final unlockedTaskTitles = prefs.getStringList('unlocked_task_titles') ?? [];
    if (!unlockedTaskTitles.contains(widget.task.title)) {
      unlockedTaskTitles.add(widget.task.title);
      await prefs.setStringList('unlocked_task_titles', unlockedTaskTitles);
    }

    if (widget.library != null) {
      await prefs.setBool('custom_tasks_unlocked', true);
    }

    if (!kIsWeb) {
      if (defaultTargetPlatform != TargetPlatform.android) {
        windowManager.setAlwaysOnTop(false);
      }
    }

    if (mounted) {
      setState(() => _isTimerRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Focus session for "${widget.task.title}" is complete! You can now mark it as done.'),
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.of(context).pop();
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title, style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_formatDuration(_remainingSeconds), style: theme.textTheme.displayLarge?.copyWith(fontSize: 80)),
            const SizedBox(height: 20),
            if (widget.library != null)
              Chip(
                avatar: const Icon(Icons.library_books_outlined, size: 18),
                label: Text(widget.library!.name, style: theme.textTheme.bodyMedium),
                backgroundColor: theme.colorScheme.primary.withAlpha(51),
              ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                '"$_currentQuote"',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isTimerRunning)
                    ElevatedButton.icon(
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Focus'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: theme.textTheme.labelLarge,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _stopTimer,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: theme.textTheme.labelLarge,
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
