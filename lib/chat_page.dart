import 'package:flutter/material.dart';
import 'package:stardust_soul/models.dart';
import 'package:stardust_soul/services.dart';
import 'package:stardust_soul/gemini/gemini_service.dart';
import 'package:stardust_soul/components.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _crisisDetected;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _sendWelcomeMessage();
  }

  Future<void> _loadMessages() async {
    final messages = await DataService.getChatMessages();
    setState(() => _messages = messages);
    _scrollToBottom();
  }

  Future<void> _sendWelcomeMessage() async {
    if (_messages.isEmpty) {
      final welcomeMessage = ChatMessage(
        content: "Hi there! 👋 I'm Calmixy, your all‑in‑one AI wellness companion. How are you feeling today?",
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() => _messages.add(welcomeMessage));
      await DataService.saveChatMessage(welcomeMessage);
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    await DataService.saveChatMessage(userMessage);
    _messageController.clear();
    _scrollToBottom();

    // Check for crisis keywords
    _checkForCrisis(content);

    // Get mood context
    final recentMoods = await DataService.getMoodEntries();
    String? moodContext;
    if (recentMoods.isNotEmpty) {
      final latestMood = recentMoods.last;
      moodContext = "Recent mood: ${latestMood.emotion.name} (${latestMood.intensity}/5) - ${latestMood.note}";
    }

    // Get AI response
    try {
      final combinedContext = moodContext;

      final aiResponse = await GeminiService.generateChatResponseWithHistory(
        history: _messages,
        message: content,
        moodContext: combinedContext,
      );

      final aiMessage = ChatMessage(
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        moodContext: moodContext,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      
      await DataService.saveChatMessage(aiMessage);
      _scrollToBottom();
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorMessage();
    }
  }

  void _checkForCrisis(String message) {
    final crisisKeywords = [
      'suicide', 'kill myself', 'end it all', 'hurt myself', 'self harm',
      'want to die', 'no hope', 'worthless', 'better off dead', 'can\'t go on'
    ];
    
    final lowerMessage = message.toLowerCase();
    for (final keyword in crisisKeywords) {
      if (lowerMessage.contains(keyword)) {
        setState(() => _crisisDetected = 'Crisis keywords detected');
        _showCrisisSupport();
        break;
      }
    }
  }

  void _showCrisisSupport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 8),
            Text('We Care About You'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your feelings matter, and you\'re not alone. Please consider reaching out for professional support:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text('🇮🇳 India Crisis Resources:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Vandrevala Foundation: 9999 666 555'),
            Text('• AASRA: 91-22-2754 6669'),
            Text('• Sneha: 044-2464 0050'),
            Text('• Fortis Stress Helpline: +91-8376804102'),
            SizedBox(height: 12),
            Text('🌍 International:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Crisis Text Line: Text HOME to 741741'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _crisisDetected = null);
            },
            child: const Text('Thank you'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to get AI response. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCopingTechniques() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CopingTechniquesModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calmixy'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: _showCopingTechniques,
            tooltip: 'Coping Techniques',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Container(
                    margin: const EdgeInsets.only(left: 16, right: 50, bottom: 8),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('AI is thinking...'),
                      ],
                    ),
                  );
                }
                
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          
          // Crisis Warning
          if (_crisisDetected != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Professional help is available. You\'re not alone.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          
          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _isLoading 
                      ? null 
                      : () => _sendMessage(_messageController.text),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CopingTechniquesModal extends StatelessWidget {
  const CopingTechniquesModal({super.key});

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Quick Coping Techniques',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _CopingTechnique(
              icon: Icons.air,
              title: 'Deep Breathing',
              description: 'Inhale for 4 counts, hold for 4, exhale for 6. Repeat 5 times.',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _CopingTechnique(
              icon: Icons.favorite,
              title: 'Gratitude Practice',
              description: 'Name 3 things you\'re grateful for right now.',
              color: Colors.pink,
            ),
            const SizedBox(height: 16),
            _CopingTechnique(
              icon: Icons.nature,
              title: '5-4-3-2-1 Grounding',
              description: '5 things you see, 4 you touch, 3 you hear, 2 you smell, 1 you taste.',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _CopingTechnique(
              icon: Icons.edit,
              title: 'Journaling Prompt',
              description: '"What would I tell a friend going through this same situation?"',
              color: Colors.orange,
            ),
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
                child: const Text('Got It'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopingTechnique extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _CopingTechnique({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}