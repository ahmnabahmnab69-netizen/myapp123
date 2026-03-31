import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:todo_smart/leaderboard_screen.dart';
import 'package:todo_smart/library_management_screen.dart';
import 'package:todo_smart/main.dart';
import 'package:todo_smart/settings_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MyHomePage();
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (BuildContext context, GoRouterState state) {
        final users = state.extra as List<User>? ?? [];
        return LeaderboardScreen(users: users);
      },
    ),
    GoRoute(
      path: '/library_management',
      builder: (BuildContext context, GoRouterState state) {
        return const LibraryManagementScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
);
