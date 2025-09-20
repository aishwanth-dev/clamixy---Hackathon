import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:stardust_soul/models.dart';
import 'package:stardust_soul/services.dart';
import 'package:stardust_soul/openai/openai_config.dart';
import 'package:intl/intl.dart';

class GalaxyPage extends StatefulWidget {
  const GalaxyPage({super.key});

  @override
  State<GalaxyPage> createState() => _GalaxyPageState();
}

class _GalaxyPageState extends State<GalaxyPage> with TickerProviderStateMixin {
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;
  MoodEntry? _selectedEntry;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMoodEntries();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
  }

  Future<void> _loadMoodEntries() async {
    final entries = await DataService.getMoodEntries();
    setState(() {
      _moodEntries = entries;
      _isLoading = false;
    });
  }

  void _onStarTapped(MoodEntry entry) {
    setState(() => _selectedEntry = entry);
    _showStarDetails(entry);
  }

  Future<void> _showStarDetails(MoodEntry entry) async {
    String? reflection = entry.aiReflection;
    
    if (reflection == null) {
      // Generate AI reflection for this entry
      reflection = await OpenAIService.generateDailyReflection(moodEntry: entry);
      // Update the entry with the new reflection
      final updatedEntries = _moodEntries.map((e) {
        if (e.date == entry.date) {
          return MoodEntry(
            date: e.date,
            emotion: e.emotion,
            intensity: e.intensity,
            note: e.note,
            aiReflection: reflection,
          );
        }
        return e;
      }).toList();
      
      // Save updated entries
      final prefs = await DataService.getMoodEntries(); // This will be replaced with proper update method
      setState(() => _moodEntries = updatedEntries);
    }

    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StarDetailModal(
        entry: MoodEntry(
          date: entry.date,
          emotion: entry.emotion,
          intensity: entry.intensity,
          note: entry.note,
          aiReflection: reflection,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _moodEntries.isEmpty
                      ? _buildEmptyGalaxy()
                      : _buildGalaxy(),
            ),
            _buildGalaxyStats(),
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
                'Your Emotion Galaxy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_moodEntries.length} stars in your constellation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGalaxyInfo,
            tooltip: 'Galaxy Info',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGalaxy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your galaxy awaits',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Check in daily to add stars and watch your emotion galaxy grow over time.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate back to home for check-in
                final homeState = context.findAncestorStateOfType<State>();
                if (homeState != null) {
                  // This would trigger navigation to home page
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Add Your First Star'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalaxy() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.indigo.shade900,
            Colors.purple.shade900,
            Colors.black,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return CustomPaint(
            painter: GalaxyPainter(
              entries: _moodEntries,
              rotationValue: _rotationController.value,
              pulseAnimation: _pulseController,
              onStarTapped: _onStarTapped,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildGalaxyStats() {
    if (_moodEntries.isEmpty) return const SizedBox.shrink();
    
    final emotionCounts = <Emotion, int>{};
    for (final entry in _moodEntries) {
      emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;
    }
    
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galaxy Composition',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedEmotions.take(5).map((entry) {
              final percentage = ((entry.value / _moodEntries.length) * 100).round();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: entry.key.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: entry.key.color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: entry.key.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showGalaxyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🌌'),
            SizedBox(width: 8),
            Text('About Your Galaxy'),
          ],
        ),
        content: const Text(
          'Your Emotion Galaxy is a unique visualization of your emotional journey:\n\n'
          '⭐ Each star represents a daily mood check-in\n'
          '🎨 Colors reflect your emotions\n'
          '✨ Star brightness shows intensity\n'
          '🔄 The galaxy slowly rotates over time\n'
          '📚 Tap any star to see AI reflections\n\n'
          'Watch your galaxy grow as you continue your wellness journey!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}

class GalaxyPainter extends CustomPainter {
  final List<MoodEntry> entries;
  final double rotationValue;
  final Animation<double> pulseAnimation;
  final Function(MoodEntry) onStarTapped;

  GalaxyPainter({
    required this.entries,
    required this.rotationValue,
    required this.pulseAnimation,
    required this.onStarTapped,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 50;
    
    // Background stars for ambiance
    _drawBackgroundStars(canvas, size);
    
    // Draw mood stars in spiral formation
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final angle = (i / entries.length) * 2 * math.pi * 3 + (rotationValue * 2 * math.pi);
      final radius = (i / entries.length) * maxRadius + 30;
      
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final starCenter = Offset(x, y);
      
      _drawStar(canvas, starCenter, entry);
    }
  }

  void _drawBackgroundStars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42); // Fixed seed for consistent stars
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, MoodEntry entry) {
    final paint = Paint()
      ..color = entry.emotion.color
      ..style = PaintingStyle.fill;
    
    // Pulsing effect based on intensity
    final pulseScale = 1.0 + (pulseAnimation.value * entry.intensity * 0.1);
    final starSize = (8.0 + entry.intensity * 2) * pulseScale;
    
    // Outer glow
    final glowPaint = Paint()
      ..color = entry.emotion.color.withValues(alpha: 0.3 * pulseAnimation.value)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    
    canvas.drawCircle(center, starSize * 1.5, glowPaint);
    
    // Main star
    canvas.drawCircle(center, starSize, paint);
    
    // Inner sparkle
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, starSize * 0.4, sparklePaint);
    
    // Star points for higher intensity emotions
    if (entry.intensity >= 4) {
      _drawStarPoints(canvas, center, starSize, paint);
    }
  }

  void _drawStarPoints(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final numPoints = 5;
    final angleStep = (2 * math.pi) / numPoints;
    final outerRadius = size * 1.2;
    final innerRadius = size * 0.6;
    
    for (int i = 0; i < numPoints * 2; i++) {
      final angle = i * angleStep / 2;
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle - math.pi / 2);
      final y = center.dy + radius * math.sin(angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(GalaxyPainter oldDelegate) {
    return oldDelegate.entries.length != entries.length ||
           oldDelegate.rotationValue != rotationValue;
  }

  @override
  bool hitTest(Offset position) => true;
}

class StarDetailModal extends StatelessWidget {
  final MoodEntry entry;

  const StarDetailModal({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.emotion.color,
                    boxShadow: [
                      BoxShadow(
                        color: entry.emotion.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      entry.emotion.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.emotion.name.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: entry.emotion.color,
                        ),
                      ),
                      Text(
                        dateFormat.format(entry.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) => Icon(
                          index < entry.intensity ? Icons.star : Icons.star_outline,
                          color: entry.emotion.color,
                          size: 16,
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Your Note',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.note,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            
            if (entry.aiReflection != null) ...[
              const SizedBox(height: 24),
              Text(
                'AI Reflection',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: entry.emotion.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: entry.emotion.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  entry.aiReflection!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}