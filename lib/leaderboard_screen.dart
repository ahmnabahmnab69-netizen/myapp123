import 'package:flutter/material.dart';
import 'package:todo_smart/main.dart'; // Import to get the User class

class LeaderboardScreen extends StatelessWidget {
  final List<User> users;

  const LeaderboardScreen({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    // Sort users by totalXp in descending order
    final sortedUsers = List<User>.from(users)
      ..sort((a, b) => b.totalXp.compareTo(a.totalXp));

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
        child: ListView.builder(
          itemCount: sortedUsers.length,
          itemBuilder: (context, index) {
            final user = sortedUsers[index];
            final rank = index + 1;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                 elevation: 4,
                shadowColor: theme.colorScheme.primary.withAlpha(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      '$rank',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  trailing: Text(
                    '${user.totalXp} XP',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
