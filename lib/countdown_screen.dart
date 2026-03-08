import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_smart/main.dart';
import 'package:window_manager/window_manager.dart';

class CountdownScreen extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskCompleted;

  const CountdownScreen({
    super.key,
    required this.task,
    required this.onTaskCompleted,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> with WindowListener {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  final service = kIsWeb ? null : FlutterBackgroundService();
  String _motivationalQuote = '';

  final List<String> _quotes = [
    'The secret of getting ahead is getting started.',
    'The only way to do great work is to love what you do.',
    'Believe you can and you\'re halfway there.',
    'Success is not final, failure is not fatal: it is the courage to continue that counts.',
    'The future belongs to those who believe in the beauty of their dreams.',
    'Don\'t watch the clock; do what it does. Keep going.'
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _remainingSeconds = _parseDuration(widget.task.time);
    _changeQuote();

    if (!kIsWeb) {
      service?.on('update').listen((event) {
        if (mounted && event != null && event.containsKey('remaining')) {
          setState(() {
            _remainingSeconds = event['remaining'];
          });
        }
      });

      service?.on('stop').listen((event) {
        if (mounted) {
          _onTimerFinish();
        }
      });
    }
    _checkIfServiceIsRunning();
  }

  @override
  void dispose() {
    _timer?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  void _changeQuote() {
    setState(() {
      _motivationalQuote = _quotes[Random().nextInt(_quotes.length)];
    });
  }

  void _checkIfServiceIsRunning() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = prefs.getInt('countdown_end_time');
    if (endTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = (endTime - now) ~/ 1000;
      if (remaining > 0) {
        setState(() {
          _remainingSeconds = remaining;
          _isTimerRunning = true;
        });
        if (kIsWeb) {
          _startWebTimer();
        } else if (defaultTargetPlatform != TargetPlatform.android) {
          windowManager.setAlwaysOnTop(true);
        }
      }
    }
  }

  int _parseDuration(String time) {
    final parts = time.split(' ');
    final value = int.tryParse(parts[0]) ?? 0;
    return parts[1] == 'min' ? value * 60 : value;
  }

  void _startTimer() async {
    final duration = _parseDuration(widget.task.time);
    final endTime = DateTime.now().millisecondsSinceEpoch + duration * 1000;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('countdown_end_time', endTime);

    setState(() {
      _isTimerRunning = true;
    });

    if (kIsWeb) {
      _startWebTimer();
    } else {
      if (defaultTargetPlatform != TargetPlatform.android) {
        windowManager.setAlwaysOnTop(true);
      }
      service?.startService();
      service?.invoke('start', {'endTime': endTime});
    }
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _changeQuote());
  }

  void _startWebTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return timer.cancel();
      final prefs = await SharedPreferences.getInstance();
      final endTime = prefs.getInt('countdown_end_time');
      if (endTime == null) return timer.cancel();

      final remaining = (endTime - DateTime.now().millisecondsSinceEpoch) ~/ 1000;

      if (remaining > 0) {
        setState(() => _remainingSeconds = remaining);
      } else {
        _onTimerFinish();
      }
    });
  }

  void _onTimerFinish() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('countdown_end_time');
    setState(() => _isTimerRunning = false);
    if (!kIsWeb) {
      if (defaultTargetPlatform != TargetPlatform.android) {
        windowManager.setAlwaysOnTop(false);
      }
    }
    if (mounted) {
      widget.onTaskCompleted();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDuration = _parseDuration(widget.task.time);
    final percentage = totalDuration > 0 ? 1.0 - (_remainingSeconds / totalDuration) : 0.0;
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [Colors.black, Colors.grey[900]!, Colors.black]
                : [Colors.white, Colors.grey.shade200, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.task.title,
                style: GoogleFonts.jura(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              Text(
                '+${widget.task.xp} XP',
                style: GoogleFonts.orbitron(fontSize: 20, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              CircularPercentIndicator(
                radius: 140.0,
                lineWidth: 20.0,
                percent: percentage,
                center: Text(
                  '$minutes:$seconds',
                  style: GoogleFonts.orbitron(fontSize: 60, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
                progressColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface.withAlpha(128),
                circularStrokeCap: CircularStrokeCap.round,
                animateFromLastPercent: true,
              ),
              const SizedBox(height: 60),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: Text(
                  _motivationalQuote,
                  key: ValueKey<String>(_motivationalQuote), // Important for AnimatedSwitcher
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jura(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 80),
              if (!_isTimerRunning)
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 32, color: Colors.white),
                  label: Text('Start Focus', style: GoogleFonts.orbitron(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
