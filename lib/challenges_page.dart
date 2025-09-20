import 'package:flutter/material.dart';
import 'package:stardust_soul/models.dart';
import 'package:stardust_soul/services.dart';
import 'package:stardust_soul/openai/openai_config.dart';
import 'package:stardust_soul/components.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> with SingleTickerProviderStateMixin {
  List<WellnessChallenge> _challenges = [];
  UserProgress? _userProgress;
  bool _isLoading = true;
  bool _isGeneratingChallenges = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    final challenges = await DataService.getChallenges();
    final progress = await DataService.getUserProgress();
    
    setState(() {
      _challenges = challenges;
      _userProgress = progress;
      _isLoading = false;
    });
  }

  Future<void> _generateNewChallenges() async {
    setState(() => _isGeneratingChallenges = true);
    
    try {
      final progress = await DataService.getUserProgress();
      final recentMoods = await DataService.getMoodEntries();
      final last7Days = recentMoods.where((mood) => 
        DateTime.now().difference(mood.date).inDays <= 7).toList();
      
      final newChallenges = await OpenAIService.generateWeeklyChallenges(
        progress: progress,
        recentMoods: last7Days,
      );
      
      // Add to existing challenges
      final allChallenges = [..._challenges, ...newChallenges];
      await DataService.saveChallenges(allChallenges);
      
      setState(() {
        _challenges = allChallenges;
        _isGeneratingChallenges = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated ${newChallenges.length} new challenges!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isGeneratingChallenges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate challenges. Try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeChallenge(String challengeId) async {
    await DataService.completeChallenge(challengeId);
    await _loadChallenges();
    
    // Show celebration animation
    _showCompletionCelebration();
  }

  void _showCompletionCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CelebrationDialog(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveTab(),
                  _buildCompletedTab(),
                  _buildRewardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGeneratingChallenges ? null : _generateNewChallenges,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: _isGeneratingChallenges 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isGeneratingChallenges ? 'Generating...' : 'New Challenges'),
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
                'Wellness Challenges',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_userProgress != null)
                Text(
                  '${_userProgress!.totalPoints} total points earned',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_userProgress?.currentStreak ?? 0}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    if (_userProgress == null) return const SizedBox.shrink();
    
    final nextRewardThreshold = _getNextRewardThreshold(_userProgress!.totalPoints);
    final progress = nextRewardThreshold > 0 
        ? _userProgress!.totalPoints / nextRewardThreshold 
        : 1.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to next reward',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${_userProgress!.totalPoints}/$nextRewardThreshold',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  int _getNextRewardThreshold(int currentPoints) {
    const thresholds = [50, 100, 200, 500, 1000];
    for (final threshold in thresholds) {
      if (currentPoints < threshold) return threshold;
    }
    return 0; // Max level reached
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Active'),
        Tab(text: 'Completed'),
        Tab(text: 'Rewards'),
      ],
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      indicatorColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildActiveTab() {
    final activeChallenges = _challenges.where((c) => 
        !c.completed && c.deadline.isAfter(DateTime.now())).toList();
    
    if (activeChallenges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt,
        title: 'No Active Challenges',
        subtitle: 'Generate new challenges to continue your wellness journey!',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeChallenges.length,
      itemBuilder: (context, index) {
        final challenge = activeChallenges[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChallengeCard(
            challenge: challenge,
            onComplete: () => _completeChallenge(challenge.id),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    final completedChallenges = _challenges.where((c) => c.completed).toList();
    
    if (completedChallenges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events,
        title: 'No Completed Challenges',
        subtitle: 'Complete challenges to see your achievements here!',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedChallenges.length,
      itemBuilder: (context, index) {
        final challenge = completedChallenges[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChallengeCard(challenge: challenge),
        );
      },
    );
  }

  Widget _buildRewardsTab() {
    if (_userProgress == null) return const SizedBox.shrink();
    
    final allRewards = [
      RewardItem('Galaxy Explorer', 50, '🌟', 'Unlock special star effects'),
      RewardItem('Mood Master', 100, '🎭', 'Access to mood insights'),
      RewardItem('Wellness Warrior', 200, '⚔️', 'Exclusive challenge types'),
      RewardItem('Stardust Champion', 500, '👑', 'Premium galaxy themes'),
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allRewards.length,
      itemBuilder: (context, index) {
        final reward = allRewards[index];
        final isUnlocked = _userProgress!.totalPoints >= reward.pointsRequired;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RewardCard(
            reward: reward,
            isUnlocked: isUnlocked,
            currentPoints: _userProgress!.totalPoints,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class RewardItem {
  final String title;
  final int pointsRequired;
  final String emoji;
  final String description;

  RewardItem(this.title, this.pointsRequired, this.emoji, this.description);
}

class RewardCard extends StatelessWidget {
  final RewardItem reward;
  final bool isUnlocked;
  final int currentPoints;

  const RewardCard({
    super.key,
    required this.reward,
    required this.isUnlocked,
    required this.currentPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnlocked 
              ? Colors.green.shade300
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isUnlocked 
              ? Colors.green.shade50
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked 
                    ? Colors.green.shade100
                    : Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: Center(
                child: Text(
                  reward.emoji,
                  style: TextStyle(
                    fontSize: 24,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
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
                        reward.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.green.shade700 : null,
                        ),
                      ),
                      if (isUnlocked) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.pointsRequired} points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isUnlocked && currentPoints < reward.pointsRequired) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${reward.pointsRequired - currentPoints} more needed)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ],
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

class CelebrationDialog extends StatefulWidget {
  const CelebrationDialog({super.key});

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog> 
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _scaleController.forward();
    _sparkleController.repeat();
    
    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _sparkleController.value * 2 * 3.14159,
                        child: const Text('🎉', style: TextStyle(fontSize: 80)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Challenge Complete!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Great job on your wellness journey! 🌟',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}