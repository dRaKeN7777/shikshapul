import 'package:flutter/material.dart';

import '../core/data/syllabus_tree.dart';
import '../core/database/database_helper.dart';
import '../models/exam_models.dart';
import 'ai_tutor_screen.dart';

class MistakeReviewScreen extends StatefulWidget {
  final CourseProfile course;

  const MistakeReviewScreen({super.key, required this.course});

  @override
  State<MistakeReviewScreen> createState() => _MistakeReviewScreenState();
}

class _MistakeReviewScreenState extends State<MistakeReviewScreen> {
  late Future<List<Map<String, dynamic>>> _mistakes;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _mistakes = DatabaseHelper.instance
        .getRecentMistakesByType(widget.course.type.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(title: const Text('Mistake Notebook')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _mistakes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final mistakes = snapshot.data ?? const [];
          if (mistakes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No recorded mistakes yet. Complete a mock or exam and your incorrect answers will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _mistakes;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mistakes.length,
              itemBuilder: (context, index) =>
                  _buildMistakeCard(context, mistakes[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMistakeCard(BuildContext context, Map<String, dynamic> mistake) {
    final topicId = mistake['topic_id'] as String? ?? '';
    final topic = SyllabusTree.findTopicById(topicId);
    final subject = mistake['subject'] as String? ?? 'unknown';
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${subject.toUpperCase()} • ${topic?.nameEn ?? topicId}',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mistake['question_text'] as String? ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your answer: ${mistake['student_answer'] ?? '—'}',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 4),
            Text(
              'Correct answer: ${mistake['correct_answer'] ?? '—'}',
              style: const TextStyle(color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiTutorScreen(
                      course: widget.course,
                      focusTopicId: topicId,
                      initialQuery:
                          'Teach me the concept behind this mistake without assuming the recorded answer is an official past-paper question: ${mistake['question_text']}',
                    ),
                  ),
                ),
                icon: const Icon(Icons.school_outlined),
                label: const Text('FIX THIS CONCEPT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
