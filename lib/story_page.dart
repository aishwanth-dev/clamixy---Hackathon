import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stardust_soul/gemini/gemini_service.dart';
import 'package:stardust_soul/relief_story_models.dart';
import 'package:stardust_soul/services.dart';
import 'package:stardust_soul/tts/google_tts_service.dart';

class StoryPage extends StatefulWidget {
  const StoryPage({super.key});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final _promptController = TextEditingController();

  bool _isGenerating = false;
  String? _storyText;
  final List<StoryRecord> _library = [];

  // TTS
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
    _player.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    final items = await DataService.getStoryLibrary();
    setState(() {
      _library
        ..clear()
        ..addAll(items);
    });
  }

  // ---------- AI Generation ----------
  Future<void> _generateStory() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _storyText = null;
    });

    final story = await GeminiService.generateUpliftingStory(prompt: prompt);

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _storyText = story;
    });
  }

  // ---------- TTS ----------
  Future<void> _togglePlay() async {
    if (_storyText == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      setState(() => _isPlaying = true);
      final bytes = await GoogleTtsService.synthesize(
        text: _storyText!,
        languageCode: 'en-IN',
        voiceName: 'en-IN-Standard-A',
        speakingRate: 0.95,
        pitch: 0.0,
      );
      await _player.play(BytesSource(bytes));
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text-to-speech is unavailable right now.')),
        );
      }
    }
  }

  // ---------- Library ----------
  Future<void> _saveToLibrary() async {
    if (_storyText == null) return;
    final now = DateTime.now();
    final rec = StoryRecord(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'Calmixy Story – ${DateFormat('MMM d, y – h:mm a').format(now)}',
      body: _storyText!,
      createdAt: now,
      mood: _promptController.text.trim(),
    );
    await DataService.saveStoryToLibrary(rec);
    await _loadLibrary();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your library')),
    );
  }

  // ---------- Pre‑made stories ----------
  List<StoryRecord> get _premadeStories => _premadeBank
      .map((e) => StoryRecord(
            id: e['id']!,
            title: e['title']!,
            body: e['body']!,
            createdAt: DateTime.now(),
            mood: e['mood'],
          ))
      .toList();

  List<StoryRecord> get _fiveRandomPremade {
    final list = [..._premadeStories];
    list.shuffle(Random());
    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story'),
      ),
      body: SafeArea(
        child: _storyText == null ? _buildHome() : _buildStoryReader(),
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
                    hintText: 'Your mood or topic (e.g., feeling anxious)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.auto_stories),
                  ),
                  onSubmitted: (_) => _generateStory(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateStory,
                icon: _isGenerating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow),
                label: const Text('Generate'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Suggested
          Text('Suggested stories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._fiveRandomPremade.map((s) => Card(
                elevation: 0,
                child: ListTile(
                  title: Text(s.title),
                  subtitle: Text(s.mood ?? 'Calming'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _storyText = s.body;
                      _promptController.text = s.mood ?? '';
                    });
                  },
                ),
              )),
          const SizedBox(height: 24),

          // Library
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Library', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (_library.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await _loadLibrary();
                    if (mounted) setState(() {});
                  },
                  child: const Text('Refresh'),
                ),
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
                'No saved stories yet. Generate one and tap Save to keep it here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ..._library.map((s) => Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(s.title),
                    subtitle: Text(DateFormat('MMM d, y – h:mm a').format(s.createdAt)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        _storyText = s.body;
                        _promptController.text = s.mood ?? '';
                      });
                    },
                  ),
                )),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildStoryReader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _storyText = null);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _togglePlay,
                icon: Icon(_isPlaying ? Icons.stop : Icons.headphones),
                label: Text(_isPlaying ? 'Stop' : 'Listen'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _saveToLibrary,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _storyText ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

// Simple pre‑made bank (10+)
const List<Map<String, String>> _premadeBank = [
  {
    'id': 'p1',
    'title': 'Rain on the Rooftop',
    'mood': 'Calm • Sleep',
    'body': 'As the first drops began to tap the old rooftop, Rhea pulled her blanket a little higher...'
  },
  {
    'id': 'p2',
    'title': 'The Neem Tree Bench',
    'mood': 'Anxiety Ease',
    'body': 'Across the college gate stood a curved bench beneath a generous neem tree...'
  },
  {
    'id': 'p3',
    'title': 'Morning by the Lake',
    'mood': 'Reset • Fresh start',
    'body': 'Fog hovered above the water like cotton. With each slow breath, the lake answered...'
  },
  {
    'id': 'p4',
    'title': 'Bus Ride Breathing',
    'mood': 'Overwhelm',
    'body': 'The bus rattled and yet, inside, a tiny bubble of quiet grew with every 4-4-6 breath...'
  },
  {
    'id': 'p5',
    'title': 'Tea with Dadi',
    'mood': 'Comfort',
    'body': 'Steam curled from the cup like a soft ribbon. “One sip, one thought,” Dadi would say...'
  },
  {
    'id': 'p6',
    'title': 'Steps on the Terrace',
    'mood': 'Anger Cooldown',
    'body': 'On the terrace, counting ten slow steps under the open sky softened the sharp edges...'
  },
  {
    'id': 'p7',
    'title': 'A Quiet Library Corner',
    'mood': 'Focus • Study',
    'body': 'Between the shelves, a patch of sunlight landed on page 34. Breathe, read, pause, repeat...'
  },
  {
    'id': 'p8',
    'title': 'Monsoon Window',
    'mood': 'Soothing',
    'body': 'Rain pearls slid down the glass. Count five you can see, four you can hear, three you can feel...'
  },
  {
    'id': 'p9',
    'title': 'The Friendly Stray',
    'mood': 'Lonely → Warmth',
    'body': 'A wagging tail greeted Mira by the chai stall. Small kindness, big shift in the heart...'
  },
  {
    'id': 'p10',
    'title': 'Train to Home',
    'mood': 'Homesick',
    'body': 'The rhythm of the tracks matched a steady breath. With every station, hope came closer...'
  },
];
