import 'package:equatable/equatable.dart';

/// Lesson Model
/// Represents an educational lesson with metadata and file path
class Lesson extends Equatable {
  final String id;
  final String title;
  final String description;
  final String file;
  final List<String> tags;
  final String duration;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.file,
    required this.tags,
    required this.duration,
  });

  /// Create Lesson from JSON
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      file: json['file'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      duration: json['duration'] as String,
    );
  }

  /// Convert Lesson to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'file': file,
      'tags': tags,
      'duration': duration,
    };
  }

  /// Get difficulty level from tags
  String get difficulty {
    if (tags.contains('beginner') || tags.contains('introduction')) {
      return 'Beginner';
    } else if (tags.contains('advanced')) {
      return 'Advanced';
    } else {
      return 'Intermediate';
    }
  }

  /// Get category from tags
  String get category {
    if (tags.contains('basics')) return 'Basics';
    if (tags.contains('trading')) return 'Trading';
    if (tags.contains('analysis')) return 'Analysis';
    if (tags.contains('strategy')) return 'Strategy';
    if (tags.contains('risk')) return 'Risk Management';
    return 'General';
  }

  @override
  List<Object?> get props => [id, title, description, file, tags, duration];

  @override
  String toString() {
    return 'Lesson(id: $id, title: $title, duration: $duration)';
  }
}
