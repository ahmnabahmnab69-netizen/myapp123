
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementsScreen extends StatelessWidget {
  final int completedTasks;
  final int totalXp;

  const AchievementsScreen({
    super.key,
    required this.completedTasks,
    required this.totalXp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildAchievementSection(
              context,
              title: 'Tasks Completed',
              achievements: [
                _buildAchievementCard(
                  context,
                  title: 'Easy: Task Novice',
                  description: 'Complete 5 tasks',
                  isUnlocked: completedTasks >= 5,
                ),
                _buildAchievementCard(
                  context,
                  title: 'Medium: Task Apprentice',
                  description: 'Complete 15 tasks',
                  isUnlocked: completedTasks >= 15,
                ),
                _buildAchievementCard(
                  context,
                  title: 'Hard: Task Master',
                  description: 'Complete 40 tasks',
                  isUnlocked: completedTasks >= 40,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAchievementSection(
              context,
              title: 'Total XP',
              achievements: [
                _buildAchievementCard(
                  context,
                  title: 'Easy: XP Explorer',
                  description: 'Collect 250 XP',
                  isUnlocked: totalXp >= 250,
                ),
                _buildAchievementCard(
                  context,
                  title: 'Medium: XP Champion',
                  description: 'Collect 750 XP',
                  isUnlocked: totalXp >= 750,
                ),
                _buildAchievementCard(
                  context,
                  title: 'Hard: XP Legend',
                  description: 'Collect 1750 XP',
                  isUnlocked: totalXp >= 1750,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementSection(BuildContext context, {required String title, required List<Widget> achievements}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.jura(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        ...achievements,
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, {required String title, required String description, required bool isUnlocked}) {
    return Card(
      color: isUnlocked ? Colors.grey[850] : Colors.grey[900],
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnlocked ? Theme.of(context).colorScheme.secondary : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isUnlocked ? Icons.check_circle : Icons.lock,
              color: isUnlocked ? Theme.of(context).colorScheme.secondary : Colors.grey[600],
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.jura(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.jura(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
