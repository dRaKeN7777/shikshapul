import 'package:flutter/material.dart';

import '../models/exam_models.dart';
import 'ai_tutor_screen.dart';

class PreparationGuideScreen extends StatelessWidget {
  final CourseProfile course;

  const PreparationGuideScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(title: const Text('Pass & Rank Strategy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            'THE NON-NEGOTIABLE SYSTEM',
            const [
              'Diagnose: take one timed baseline paper without notes.',
              'Repair: study the weakest concept and solve 15–25 focused questions.',
              'Recall: close the notes and reproduce formulas, definitions, and steps.',
              'Retest: repeat the same topic after 24 hours and again after 7 days.',
              'Simulate: complete one full timed paper weekly, then two per week near the exam.',
            ],
            const Color(0xFF10B981),
          ),
          _card('DAILY CONFIGURATION', _dailyPlan(), const Color(0xFF38BDF8)),
          _card('EXAM-DAY DECISIONS', _examPlan(), const Color(0xFFF59E0B)),
          _card('SUBJECT SCORING HABITS', _subjectTips(),
              const Color(0xFF8B5CF6)),
          _card(
            'EPCM / EXTERNAL BOOK WORKFLOW',
            const [
              'Use only a purchased or authorized copy.',
              'Attempt a set under time before checking its answer key.',
              'For every error, write: concept gap, calculation error, or rushed reading.',
              'Re-solve wrong questions without viewing the answer after 24 hours.',
              'Do not memorize answer letters or expect exact repetition in the exam.',
            ],
            const Color(0xFFEC4899),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AiTutorScreen(
                  course: course,
                  initialQuery:
                      'Build a realistic seven-day study plan from my weakest topics. Do not promise a rank or scholarship.',
                ),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('BUILD MY 7-DAY PLAN'),
          ),
          const SizedBox(height: 12),
          const Text(
            'No app can guarantee admission, rank, or scholarship. This system improves preparation only when the student completes the work consistently and verifies doubtful material.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  List<String> _dailyPlan() {
    final minutes = course.durationMinutes >= 180 ? '180–240' : '120–180';
    return [
      '$minutes focused minutes on normal study days; adjust the duration to a sustainable level without reducing the review cycle.',
      '40% weak-topic repair, 30% mixed timed MCQs, 20% active recall, 10% mistake review.',
      'Use Mock Exam for learning and Simulator only for timed measurement.',
      'End each session by scheduling the next review instead of merely rereading notes.',
    ];
  }

  List<String> _examPlan() {
    if (course.isAdaptive) {
      return const [
        'Treat every answer as final; read the stem and all four options before committing.',
        'Begin each subject calmly—the adaptive level responds to performance.',
        'Use estimation and unit checks before numerical submission.',
        'Do not chase speed at the cost of early accuracy.',
      ];
    }
    if (course.hasNegativeMarking) {
      return const [
        'First pass: answer questions you can justify and mark uncertain ones for review when navigation permits.',
        'Second pass: eliminate options using definitions, signs, units, and limiting cases.',
        'Do not blind-guess; negative marking punishes unsupported attempts.',
        'Reserve final minutes for answer-state and unit checks.',
      ];
    }
    return const [
      'Complete confident questions first when navigation permits.',
      'Use elimination for uncertain items and avoid leaving answerable questions blank.',
      'Check signs, units, biological terminology, and option wording.',
      'Reserve final minutes for unanswered questions and accidental selections.',
    ];
  }

  List<String> _subjectTips() {
    final tips = <String>[];
    for (final subject in course.subjectOrder) {
      final tip = switch (subject) {
        SubjectDomain.physics =>
          'Physics: draw the situation, list givens with units, choose a governing law, then calculate.',
        SubjectDomain.chemistry =>
          'Chemistry: separate factual recall from numerical work; check mole ratios, charge, and conditions.',
        SubjectDomain.mathematics =>
          'Mathematics: write the identity or theorem first, control signs, and test the result quickly.',
        SubjectDomain.biology =>
          'Biology: use exact textbook terminology and compare every option, especially words such as always/only.',
        SubjectDomain.english =>
          'English: identify the tested rule before selecting the option; use context for vocabulary.',
        SubjectDomain.mat =>
          'Mental aptitude: identify the pattern type, test the simplest rule, and skip lengthy dead ends.',
        SubjectDomain.healthKnowledge =>
          'Health knowledge: prefer current official definitions and avoid unsupported clinical assumptions.',
      };
      if (!tips.contains(tip)) tips.add(tip);
    }
    return tips;
  }

  Widget _card(String title, List<String> points, Color color) => Card(
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7)),
              const SizedBox(height: 10),
              for (final point in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(point,
                            style: const TextStyle(
                                color: Colors.white70, height: 1.4)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}
