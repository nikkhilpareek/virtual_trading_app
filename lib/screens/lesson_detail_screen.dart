import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/models/models.dart';

/// LessonDetailScreen
/// Displays the full lesson content from markdown file
class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  String _markdownContent = '';
  bool _isLoading = true;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadMarkdownContent();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    // Set up TTS configuration
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // iOS specific settings
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ], IosTextToSpeechAudioMode.defaultMode);

    // Set up handlers
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _isPaused = false;
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
      }
    });

    _flutterTts.setPauseHandler(() {
      if (mounted) {
        setState(() {
          _isPaused = true;
        });
      }
    });

    _flutterTts.setContinueHandler(() {
      if (mounted) {
        setState(() {
          _isPaused = false;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS Error: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadMarkdownContent() async {
    try {
      final content = await rootBundle.loadString(widget.lesson.file);
      setState(() {
        _markdownContent = content.isNotEmpty ? content : _getDefaultContent();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _markdownContent = _getDefaultContent();
        _isLoading = false;
      });
      // Show error but still display default content
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using default content'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // TTS Control Methods
  Future<void> _speak() async {
    if (_markdownContent.isNotEmpty) {
      // Remove markdown syntax for cleaner speech
      String cleanText = _markdownContent
          .replaceAll(RegExp(r'#+ '), '') // Remove headers
          .replaceAll(RegExp(r'\*\*'), '') // Remove bold
          .replaceAll(RegExp(r'__'), '') // Remove bold
          .replaceAll(RegExp(r'\*'), '') // Remove italic
          .replaceAll(RegExp(r'_'), '') // Remove italic
          .replaceAll(
            RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
            r'$1',
          ) // Remove links, keep text
          .replaceAll(RegExp(r'```[^`]*```'), '') // Remove code blocks
          .replaceAll(RegExp(r'`[^`]*`'), '') // Remove inline code
          .replaceAll(RegExp(r'---+'), '') // Remove horizontal rules
          .replaceAll(RegExp(r'\n+'), '\n'); // Clean multiple newlines

      await _flutterTts.speak(cleanText);
    }
  }

  Future<void> _pause() async {
    await _flutterTts.pause();
    setState(() {
      _isPaused = true;
    });
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
      _isPaused = false;
    });
  }

  String _getDefaultContent() {
    return '''
# ${widget.lesson.title}

${widget.lesson.description}

---

## About This Lesson

**Duration:** ${widget.lesson.duration}  
**Difficulty:** ${widget.lesson.difficulty}  
**Topics:** ${widget.lesson.tags.join(', ')}

---

## Content Coming Soon

This lesson is currently being developed. Check back soon for comprehensive content on this topic!

### What You'll Learn

- Key concepts related to ${widget.lesson.category.toLowerCase()}
- Practical examples and real-world applications
- Step-by-step guidance for beginners
- Tips and best practices

### Why This Matters

Understanding ${widget.lesson.title.toLowerCase()} is crucial for anyone looking to succeed in the Indian stock market. This lesson will provide you with the foundational knowledge you need to make informed decisions.

---

*Stay tuned for updates!*
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.lesson.title,
          style: const TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Lesson metadata card with TTS controls
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with metadata
                        Row(
                          children: [
                            // Difficulty badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withAlpha((0.15 * 255).round()),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.lesson.difficulty,
                                style: TextStyle(
                                  fontFamily: 'ClashDisplay',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Divider
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Theme.of(context).dividerColor,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // Audio Lesson Section
                        Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withAlpha((0.1 * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.headphones,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Text section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Audio Lesson',
                                    style: const TextStyle(
                                      fontFamily: 'ClashDisplay',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isSpeaking && !_isPaused
                                        ? 'Playing...'
                                        : _isPaused
                                        ? 'Paused'
                                        : 'Listen to this lesson',
                                    style: TextStyle(
                                      fontFamily: 'ClashDisplay',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: _isSpeaking
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Control buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Play/Pause button
                                GestureDetector(
                                  onTap: () {
                                    if (_isSpeaking && !_isPaused) {
                                      _pause();
                                    } else {
                                      _speak();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary
                                              .withAlpha((0.8 * 255).round()),
                                          Theme.of(context).colorScheme.primary
                                              .withAlpha((0.6 * 255).round()),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        if (_isSpeaking)
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha((0.3 * 255).round()),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isSpeaking && !_isPaused
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      size: 22,
                                    ),
                                  ),
                                ),

                                // Stop button (only show when speaking)
                                if (_isSpeaking) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _stop,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withAlpha(
                                          (0.1 * 255).round(),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.redAccent.withAlpha(
                                            (0.3 * 255).round(),
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.stop_rounded,
                                        color: Colors.redAccent,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Markdown content
                  Expanded(
                    child: Markdown(
                      data: _markdownContent,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                        h1: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        h2: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        h3: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        h4: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        listBullet: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        code: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        blockquote: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: Colors.white60,
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),

                  // Call to action button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: GestureDetector(
                        onTap: () {
                          // Pop back to home and navigate to market tab
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withAlpha(
                                  (0.8 * 255).round(),
                                ),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary
                                    .withAlpha((0.3 * 255).round()),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ready to Trade? Go to Market',
                                style: TextStyle(
                                  fontFamily: 'ClashDisplay',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
