import 'package:flutter/material.dart';
import 'package:stardust_soul/chat_page.dart';
import 'package:stardust_soul/story_page.dart';
import 'package:stardust_soul/relief_page.dart';
import 'package:stardust_soul/progress_page.dart';
import 'package:stardust_soul/services.dart';
import 'package:stardust_soul/models.dart';
import 'package:stardust_soul/components.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  UserProgress? _userProgress;
  List<MoodEntry> _recentMoods = [];
  bool _hasCheckedInToday = false;

  final List<Widget> _pages = const [
    ChatPage(),
    StoryPage(),
    ReliefPage(),
    ProgressPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await DataService.generateSampleData();
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    final progress = await DataService.getUserProgress();
    final moods = await DataService.getMoodEntries();
    final hasCheckedIn = await DataService.hasCheckedInToday();
    
    setState(() {
      _userProgress = progress;
      _recentMoods = moods;
      _hasCheckedInToday = hasCheckedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Story',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            label: 'Relief',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  UserProgress? _userProgress;
  List<MoodEntry> _recentMoods = [];
  List<WellnessChallenge> _challenges = [];
  bool _hasCheckedInToday = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final progress = await DataService.getUserProgress();
    final moods = await DataService.getMoodEntries();
    final challenges = await DataService.getChallenges();
    final hasCheckedIn = await DataService.hasCheckedInToday();
    
    setState(() {
      _userProgress = progress;
      _recentMoods = moods.take(7).toList();
      _challenges = challenges;
      _hasCheckedInToday = hasCheckedIn;
      _isLoading = false;
    });
  }

  Future<void> _showMoodCheckIn() async {
    final result = await showModalBottomSheet<MoodEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MoodCheckInModal(),
    );

    if (result != null) {
      await DataService.saveMoodEntry(result);
      await DataService.markCheckInComplete();
      _loadData(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 24),
              if (!_hasCheckedInToday) _buildCheckInPrompt(),
              const SizedBox(height: 24),
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildRecentMoods(),
              const SizedBox(height: 24),
              _buildActiveChallenges(),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How are you feeling today?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInPrompt() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              '⭐',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              'Daily Check-in',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a new star to your emotion galaxy!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showMoodCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Check In Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_userProgress == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Journey',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProgressCard(
                title: 'Current Streak',
                value: '${_userProgress!.currentStreak}',
                subtitle: 'days in a row',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressCard(
                title: 'Total Points',
                value: '${_userProgress!.totalPoints}',
                subtitle: 'wellness points',
                icon: Icons.stars,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentMoods() {
    if (_recentMoods.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Stars',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentMoods.length,
            itemBuilder: (context, index) {
              final mood = _recentMoods[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    StarWidget(entry: mood, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      '${mood.date.day}/${mood.date.month}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveChallenges() {
    final activeChallenges = _challenges.where((c) => 
        !c.completed && c.deadline.isAfter(DateTime.now())).take(2).toList();
    
    if (activeChallenges.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Challenges',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to challenges tab
                final homeState = context.findAncestorStateOfType<_HomePageState>();
                homeState?.setState(() => homeState._currentIndex = 3);
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...activeChallenges.map((challenge) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChallengeCard(
            challenge: challenge,
            onComplete: () async {
              await DataService.completeChallenge(challenge.id);
              _loadData();
            },
          ),
        )),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'Chat with AI',
                subtitle: 'Get support',
                onTap: () {
                  final homeState = context.findAncestorStateOfType<_HomePageState>();
                  homeState?.setState(() => homeState._currentIndex = 0);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.auto_awesome,
                title: 'View Galaxy',
                subtitle: 'See your journey',
                onTap: () {
                  final homeState = context.findAncestorStateOfType<_HomePageState>();
                  homeState?.setState(() => homeState._currentIndex = 3);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoodCheckInModal extends StatefulWidget {
  const MoodCheckInModal({super.key});

  @override
  State<MoodCheckInModal> createState() => _MoodCheckInModalState();
}

class _MoodCheckInModalState extends State<MoodCheckInModal> {
  Emotion? _selectedEmotion;
  int _intensity = 3;
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            EmotionSelector(
              selectedEmotion: _selectedEmotion,
              onEmotionSelected: (emotion) => setState(() => _selectedEmotion = emotion),
            ),
            if (_selectedEmotion != null) ...[
              const SizedBox(height: 24),
              IntensitySlider(
                intensity: _intensity,
                onIntensityChanged: (value) => setState(() => _intensity = value),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'What\'s on your mind? (optional)',
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final entry = MoodEntry(
                      date: DateTime.now(),
                      emotion: _selectedEmotion!,
                      intensity: _intensity,
                      note: _noteController.text,
                    );
                    Navigator.pop(context, entry);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add to Galaxy'),
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}