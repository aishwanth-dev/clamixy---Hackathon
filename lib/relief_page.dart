import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stardust_soul/gemini/gemini_service.dart';
import 'package:stardust_soul/relief_story_models.dart';
import 'package:stardust_soul/services.dart';

class ReliefPage extends StatefulWidget {
  const ReliefPage({super.key});

  @override
  State<ReliefPage> createState() => _ReliefPageState();
}

class _ReliefPageState extends State<ReliefPage> {
  final _promptController = TextEditingController();
  bool _loading = false;
  ReliefPackageModel? _pkg; // selected or generated

  int _currentIndex = -1; // not started
  int _remaining = 0;
  Timer? _timer;

  // Library
  final List<ReliefPackageModel> _library = [];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    final items = await DataService.getReliefLibrary();
    setState(() {
      _library
        ..clear()
        ..addAll(items);
    });
  }

  // ---------- Generate with AI ----------
  Future<void> _generate() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _pkg = null;
      _currentIndex = -1;
    });

    final json = await GeminiService.generateReliefPackageFromMessage(text);
    if (!mounted) return;
    setState(() {
      _pkg = ReliefPackageModel.fromJson(json);
      _loading = false;
    });
  }

  void _selectPremade(ReliefPackageModel p) {
    setState(() {
      _pkg = p;
      _currentIndex = -1;
      _remaining = 0;
    });
  }

  Future<void> _saveCurrentToLibrary() async {
    if (_pkg == null) return;
    await DataService.saveReliefToLibrary(_pkg!);
    await _loadLibrary();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your library')),
    );
  }

  void _start() {
    if (_pkg == null) return;
    setState(() {
      _currentIndex = 0;
      _remaining = _pkg!.steps[0].durationSec;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _next() {
    if (_pkg == null) return;
    final next = _currentIndex + 1;
    if (next >= _pkg!.steps.length) {
      _complete();
      return;
    }
    setState(() {
      _currentIndex = next;
      _remaining = _pkg!.steps[next].durationSec;
    });
    _startTimer();
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _currentIndex = -1;
      _remaining = 0;
    });
    final pts = _pkg?.points ?? 20;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Great job!'),
        content: Text('You completed the relief package. +$pts points 🎉'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relief')),
      body: SafeArea(
        child: _pkg == null ? _buildHome() : _buildPackage(),
      ),
    );
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create with AI
          Text('Create with AI', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: 'What are you feeling? (e.g., I am angry)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.spa_outlined),
                  ),
                  onSubmitted: (_) => _generate(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Suggested
          Text('Quick Relief Packs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._premadePackages.map((p) => Card(
                elevation: 0,
                child: ListTile(
                  leading: _iconFor(p.steps.first.type),
                  title: Text(p.title),
                  subtitle: Text('${p.points} pts • ${p.mood}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectPremade(p),
                ),
              )),
          const SizedBox(height: 24),

          // Library
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Library', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (_library.isNotEmpty)
                TextButton(onPressed: _loadLibrary, child: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 8),
          if (_library.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
              ),
              child: Text(
                'No saved packs yet. Create one and tap Save to reuse it later.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ..._library.asMap().entries.map((e) => Card(
                  elevation: 0,
                  child: ListTile(
                    leading: _iconFor(e.value.steps.first.type),
                    title: Text(e.value.title),
                    subtitle: Text('${e.value.points} pts • ${e.value.mood}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectPremade(e.value),
                  ),
                )),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildPackage() {
    final pkg = _pkg!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _pkg = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _saveCurrentToLibrary,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pkg.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Chip(label: Text('${pkg.points} pts')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final step = pkg.steps[i];
              final isCurrent = i == _currentIndex;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iconFor(step.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(step.title, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Text('${step.durationSec}s'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(step.instruction),
                    if (isCurrent) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 18),
                          const SizedBox(width: 6),
                          Text(_format(_remaining)),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _remaining == 0 ? _next : null,
                            child: Text(_currentIndex == pkg.steps.length - 1 ? 'Finish' : 'Next'),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: pkg.steps.length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _currentIndex == -1 ? _start : null,
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Start Package'),
            ),
          ),
        )
      ],
    );
  }

  String _format(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _iconFor(String type) {
    switch (type) {
      case 'breathing':
        return const Icon(Icons.air, color: Colors.blue);
      case 'mindfulness':
        return const Icon(Icons.self_improvement, color: Colors.purple);
      case 'activity':
        return const Icon(Icons.directions_walk, color: Colors.green);
      case 'journaling':
        return const Icon(Icons.edit_note, color: Colors.orange);
      case 'reflection':
        return const Icon(Icons.emoji_emotions, color: Colors.pink);
      default:
        return const Icon(Icons.check_circle_outline);
    }
  }
}

// Premade packages for quick start
final List<ReliefPackageModel> _premadePackages = [
  ReliefPackageModel(
    mood: 'anxiety',
    title: 'Anxiety Reset (5 min)',
    points: 20,
    steps: [
      ReliefStepModel(type: 'breathing', title: '4-4-6 Breathing', durationSec: 40, instruction: 'Inhale 4 • Hold 4 • Exhale 6.'),
      ReliefStepModel(type: 'mindfulness', title: 'Name 3-2-1', durationSec: 90, instruction: '3 things you see, 2 you hear, 1 you feel.'),
      ReliefStepModel(type: 'activity', title: 'Shoulder Roll', durationSec: 60, instruction: 'Roll shoulders back 10 times, then forward 10.'),
      ReliefStepModel(type: 'journaling', title: 'Name It', durationSec: 60, instruction: 'Write: What I feel, why I might feel it.'),
      ReliefStepModel(type: 'reflection', title: 'Check-in', durationSec: 30, instruction: 'Rate anxiety now 1–5.'),
    ],
  ),
  ReliefPackageModel(
    mood: 'anger',
    title: 'Anger Cooldown (6 min)',
    points: 24,
    steps: [
      ReliefStepModel(type: 'breathing', title: 'Box Breath', durationSec: 60, instruction: 'Inhale 4 • Hold 4 • Exhale 4 • Hold 4.'),
      ReliefStepModel(type: 'activity', title: 'Walk & Count', durationSec: 120, instruction: 'Walk 20 steps slowly. Count them out.'),
      ReliefStepModel(type: 'mindfulness', title: 'Name Colors', durationSec: 60, instruction: 'Pick a color. Find 5 things with it.'),
      ReliefStepModel(type: 'journaling', title: 'Unsent Note', durationSec: 90, instruction: 'Write a letter you will not send.'),
      ReliefStepModel(type: 'reflection', title: 'Where is the heat?', durationSec: 30, instruction: 'Notice where anger feels strong. Breathe into it.'),
    ],
  ),
  ReliefPackageModel(
    mood: 'sleep',
    title: 'Sleep Ease (7 min)',
    points: 28,
    steps: [
      ReliefStepModel(type: 'breathing', title: '6-2-6', durationSec: 60, instruction: 'Inhale 6 • Hold 2 • Exhale 6.'),
      ReliefStepModel(type: 'mindfulness', title: 'Body Scan', durationSec: 120, instruction: 'Relax from toes to head, part by part.'),
      ReliefStepModel(type: 'activity', title: 'Light Stretch', durationSec: 120, instruction: 'Neck tilt, arm stretch, ankle circles.'),
      ReliefStepModel(type: 'journaling', title: 'Unload Thoughts', durationSec: 90, instruction: 'Write down worries, then one kind next step.'),
      ReliefStepModel(type: 'reflection', title: 'Soft Landing', durationSec: 30, instruction: 'Picture a calm place for 30 seconds.'),
    ],
  ),
];
