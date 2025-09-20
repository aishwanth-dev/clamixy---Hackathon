import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stardust_soul/models.dart';
import 'package:stardust_soul/components.dart';
import 'package:stardust_soul/services.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  UserProgress? _userProgress;
  List<WellnessChallenge> _challenges = [];
  List<MoodEntry> _moodEntries = [];
  List<JournalEntry> _journals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await DataService.getUserProgress();
    final challenges = await DataService.getChallenges();
    final moods = await DataService.getMoodEntries();
    final journals = await DataService.getJournalEntries();
    if (!mounted) return;
    setState(() {
      _userProgress = progress;
      _challenges = challenges;
      _moodEntries = moods;
      _journals = journals;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildOverviewCards(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMoodAnalyticsTab(),
                  _buildAchievementsTab(),
                  _buildJournalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Me',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Track your wellness journey',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProgress,
            tooltip: 'Share Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    if (_userProgress == null) return const SizedBox.shrink();

    final completedChallenges = _challenges.where((c) => c.completed).length;
    final totalChallenges = _challenges.length;
    final completionRate =
        totalChallenges > 0 ? (completedChallenges / totalChallenges * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ProgressCard(
                  title: 'Current Streak',
                  value: '${_userProgress!.currentStreak}',
                  subtitle: 'days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProgressCard(
                  title: 'Total Stars',
                  value: '${_userProgress!.totalStars}',
                  subtitle: 'mood entries',
                  icon: Icons.auto_awesome,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProgressCard(
                  title: 'Points Earned',
                  value: '${_userProgress!.totalPoints}',
                  subtitle: 'wellness points',
                  icon: Icons.stars,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProgressCard(
                  title: 'Challenge Rate',
                  value: '$completionRate%',
                  subtitle: 'completion',
                  icon: Icons.task_alt,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Mood Analytics'),
          Tab(text: 'Achievements'),
          Tab(text: 'Journal'),
        ],
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildMoodAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMoodDistribution(),
          const SizedBox(height: 24),
          _buildMoodTrend(),
          const SizedBox(height: 24),
          _buildMoodCalendar(),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final milestones = _calculateMilestones();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MilestoneCard(milestone: milestone),
        );
      },
    );
  }

  Widget _buildMoodDistribution() {
    if (_moodEntries.isEmpty) return const SizedBox.shrink();

    final emotionCounts = <Emotion, int>{};
    for (final entry in _moodEntries) {
      emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;
    }

    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emotion Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...sortedEmotions.map((entry) {
              final percentage = ((entry.value / _moodEntries.length) * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(entry.key.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key.name.toUpperCase(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: entry.key.color,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(entry.key.color),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodTrend() {
    if (_moodEntries.length < 7) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.trending_up,
                size: 48,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Mood Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track for 7+ days to see mood trends and patterns',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final last7Days = _moodEntries
        .where((mood) => DateTime.now().difference(mood.date).inDays <= 7)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter:
                    MoodTrendPainter(last7Days, Theme.of(context).colorScheme.primary),
                size: const Size(double.infinity, 100),
              ),
            ),
            const SizedBox(height: 16),
            _buildTrendInsights(last7Days),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendInsights(List<MoodEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final averageIntensity =
        entries.fold(0, (sum, e) => sum + e.intensity) / entries.length;
    final dominantEmotion = _getDominantEmotion(entries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.psychology,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Average intensity: ${averageIntensity.toStringAsFixed(1)}/5',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(dominantEmotion.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Most frequent: ${dominantEmotion.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Emotion _getDominantEmotion(List<MoodEntry> entries) {
    final counts = <Emotion, int>{};
    for (final entry in entries) {
      counts[entry.emotion] = (counts[entry.emotion] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Widget _buildMoodCalendar() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mood Calendar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('MMMM y').format(currentMonth),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(now.year, now.month, day);
                final moodEntry = _moodEntries.firstWhere(
                  (entry) =>
                      entry.date.year == date.year &&
                      entry.date.month == date.month &&
                      entry.date.day == date.day,
                  orElse: () => MoodEntry(
                    date: date,
                    emotion: Emotion.neutral,
                    intensity: 0,
                    note: '',
                  ),
                );

                final hasEntry = moodEntry.intensity > 0;

                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEntry
                        ? moodEntry.emotion.color.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.surfaceContainer,
                    border: date.day == now.day
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      hasEntry ? moodEntry.emotion.emoji : '$day',
                      style: TextStyle(
                        fontSize: hasEntry ? 16 : 12,
                        fontWeight: date.day == now.day
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Milestone> _calculateMilestones() {
    if (_userProgress == null) return [];
    final milestones = <Milestone>[];

    // Streak milestones
    if (_userProgress!.currentStreak >= 7) {
      milestones.add(Milestone(
        title: 'Week Warrior',
        description: 'Maintained a 7-day streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        isAchieved: true,
        dateAchieved: DateTime.now()
            .subtract(Duration(days: _userProgress!.currentStreak - 7)),
      ));
    }

    if (_userProgress!.longestStreak >= 30) {
      milestones.add(Milestone(
        title: 'Monthly Master',
        description: 'Achieved a 30-day streak',
        icon: Icons.calendar_month,
        color: Colors.blue,
        isAchieved: true,
        dateAchieved: DateTime.now(),
      ));
    }

    // Points milestones
    if (_userProgress!.totalPoints >= 100) {
      milestones.add(Milestone(
        title: 'Century Club',
        description: 'Earned 100+ wellness points',
        icon: Icons.stars,
        color: Colors.purple,
        isAchieved: true,
        dateAchieved: DateTime.now(),
      ));
    }

    // Galaxy milestones
    if (_userProgress!.totalStars >= 50) {
      milestones.add(Milestone(
        title: 'Galaxy Creator',
        description: 'Added 50+ stars to your galaxy',
        icon: Icons.auto_awesome,
        color: Colors.indigo,
        isAchieved: true,
        dateAchieved: DateTime.now(),
      ));
    }

    // Challenge milestones
    final completedChallenges = _challenges.where((c) => c.completed).length;
    if (completedChallenges >= 10) {
      milestones.add(Milestone(
        title: 'Challenge Champion',
        description: 'Completed 10+ wellness challenges',
        icon: Icons.emoji_events,
        color: Colors.amber,
        isAchieved: true,
        dateAchieved: DateTime.now(),
      ));
    }

    // Add future milestones
    milestones.addAll(_getFutureMilestones());

    return milestones;
  }

  List<Milestone> _getFutureMilestones() {
    if (_userProgress == null) return [];
    final future = <Milestone>[];

    if (_userProgress!.currentStreak < 7) {
      future.add(Milestone(
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        isAchieved: false,
        progress: _userProgress!.currentStreak / 7,
      ));
    }

    if (_userProgress!.totalPoints < 500) {
      future.add(Milestone(
        title: 'Point Master',
        description: 'Earn 500 wellness points',
        icon: Icons.stars,
        color: Colors.purple,
        isAchieved: false,
        progress: _userProgress!.totalPoints / 500,
      ));
    }

    return future;
  }

  void _shareProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress sharing coming soon! 🚀'),
      ),
    );
  }
}

// ---------------- Journal Tab ----------------
extension on _ProgressPageState {
  Widget _buildJournalTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your Journal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddJournal,
                icon: const Icon(Icons.add),
                label: const Text('New'),
              )
            ],
          ),
        ),
        Expanded(
          child: _journals.isEmpty
              ? Center(
                  child: Text(
                    'Write your first entry. Your thoughts are safe here.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _journals.length,
                  itemBuilder: (context, i) {
                    final j = _journals[i];
                    return Card(
                      elevation: 0,
                      child: ListTile(
                        title: Text(DateFormat('MMM d, y – h:mm a').format(j.date)),
                        subtitle: Text(
                          j.text.length > 80 ? j.text.substring(0, 80) + '…' : j.text,
                          maxLines: 2,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _showEditJournal(j);
                            if (value == 'delete') _deleteJournal(j);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        onTap: () => _showEditJournal(j, readOnly: true),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showAddJournal() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _JournalDialog(
        title: 'New Entry',
        controller: controller,
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      final entry = JournalEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), date: DateTime.now(), text: text.trim());
      await DataService.addJournalEntry(entry);
      _loadData();
    }
  }

  Future<void> _showEditJournal(JournalEntry entry, {bool readOnly = false}) async {
    final controller = TextEditingController(text: entry.text);
    final result = await showDialog<_JournalEditResult>(
      context: context,
      builder: (_) => _JournalDialog(
        title: readOnly ? 'View Entry' : 'Edit Entry',
        controller: controller,
        readOnly: readOnly,
        showActions: !readOnly,
      ),
    );
    if (result != null && result.text.trim().isNotEmpty) {
      final updated = JournalEntry(id: entry.id, date: entry.date, text: result.text.trim());
      await DataService.updateJournalEntry(updated);
      _loadData();
    }
  }

  Future<void> _deleteJournal(JournalEntry entry) async {
    await DataService.deleteJournalEntry(entry.id);
    _loadData();
  }
}

class _JournalEditResult {
  final String text;
  _JournalEditResult(this.text);
}

class _JournalDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool readOnly;
  final bool showActions;
  const _JournalDialog({required this.title, required this.controller, this.readOnly = false, this.showActions = true});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 8,
        readOnly: readOnly,
        decoration: const InputDecoration(hintText: 'Write from your heart…'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (showActions)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _JournalEditResult(controller.text)),
            child: const Text('Save'),
          ),
      ],
    );
  }
}

class MoodTrendPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final Color lineColor;

  MoodTrendPainter(this.entries, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < entries.length; i++) {
      final x = (i / (entries.length - 1)) * size.width;
      final y = size.height - (entries[i].intensity / 5.0) * size.height;
      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Milestone {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isAchieved;
  final DateTime? dateAchieved;
  final double? progress;

  Milestone({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isAchieved,
    this.dateAchieved,
    this.progress,
  });
}

class MilestoneCard extends StatelessWidget {
  final Milestone milestone;

  const MilestoneCard({
    super.key,
    required this.milestone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: milestone.isAchieved
              ? milestone.color.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: milestone.isAchieved
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    milestone.color.withValues(alpha: 0.1),
                    milestone.color.withValues(alpha: 0.05),
                  ],
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: milestone.color
                    .withValues(alpha: milestone.isAchieved ? 0.2 : 0.1),
              ),
              child: Icon(
                milestone.icon,
                color: milestone.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        milestone.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (milestone.isAchieved) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: milestone.color,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (milestone.dateAchieved != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Achieved ${DateFormat('MMM d, y').format(milestone.dateAchieved!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: milestone.color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                  if (!milestone.isAchieved && milestone.progress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: milestone.progress!.clamp(0.0, 1.0),
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(milestone.color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(milestone.progress! * 100).round()}% complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: milestone.color,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}