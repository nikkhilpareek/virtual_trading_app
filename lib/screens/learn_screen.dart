import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../core/models/models.dart';
import 'lesson_detail_screen.dart';

/// LearnScreen
/// A simple educational screen consistent with the app's dark theme.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/lessons.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _lessons = jsonData.map((json) => Lesson.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load lessons';
        _isLoading = false;
      });
    }
  }

  void _openLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Learn title
                    const Text(
                      'Learn',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Featured lesson card at the top
                    if (_lessons.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openLesson(_lessons.first),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _lessons.first.title,
                                      style: const TextStyle(
                                        fontFamily: 'ClashDisplay',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _lessons.first.description,
                                      style: const TextStyle(
                                        fontFamily: 'ClashDisplay',
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Categories

                    // Lessons list
                    const Text(
                      'Lessons',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Flexible list area
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return _LessonCard(
                            lesson: lesson,
                            onTap: () => _openLesson(lesson),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// class _CategoryChip extends StatelessWidget {
//   final String label;
//   const _CategoryChip({required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 8.0),
//       child: GestureDetector(
//         onTap: () {
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filter: $label')));
//         },
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//           decoration: BoxDecoration(
//             color: const Color(0xff121212),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: Colors.white.withOpacity(0.06)),
//           ),
//           child: Text(
//             label,
//             style: const TextStyle(
//               fontFamily: 'ClashDisplay',
//               color: Colors.white70,
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonCard({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lesson.difficulty,
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
