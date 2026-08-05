import 'package:flutter/material.dart';
import '../models/exam_models.dart';
import 'ai_tutor_screen.dart';
import 'mock_exam_screen.dart';
import 'mistake_review_screen.dart';
import 'preparation_guide_screen.dart';
import 'real_exam_screen.dart';
import 'resource_library_screen.dart';
import 'syllabus_screen.dart';
import 'weakness_analysis_screen.dart';

class DashboardScreen extends StatelessWidget {
  final CourseProfile course;
  const DashboardScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: Text(course.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            const Text(
              "PREPARATION MODULES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildModuleCard(
                    context,
                    title: "AI Tutor",
                    subtitle: "Step-by-step\nexplanations",
                    icon: Icons.school_rounded,
                    color: const Color(0xFF38BDF8),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiTutorScreen(course: course),
                      ),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: "Syllabus",
                    subtitle: "Source-backed\ntopic checklist",
                    icon: Icons.fact_check_rounded,
                    color: const Color(0xFF14B8A6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SyllabusScreen(course: course),
                      ),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: "Mistakes",
                    subtitle: "Review every\nwrong answer",
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MistakeReviewScreen(course: course),
                      ),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: "Mock Exam",
                    subtitle: "Practice with\ninstant feedback",
                    icon: Icons.quiz_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MockExamScreen(course: course),
                      ),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: "Simulator",
                    subtitle: "Timed exam\nconditions",
                    icon: Icons.timer_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RealExamScreen(course: course),
                      ),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: "Weakness",
                    subtitle: "Your weak topics\n& AI fix plan",
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeaknessAnalysisScreen(course: course),
                      ),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: "Strategy",
                    subtitle: "Pass-focused\nstudy system",
                    icon: Icons.route_rounded,
                    color: const Color(0xFFEC4899),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreparationGuideScreen(course: course),
                      ),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: "Resources",
                    subtitle: "Official & model\nquestion sources",
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF22C55E),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResourceLibraryScreen(course: course),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0B1020)],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.fullName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            course.isOfficiallyVerified
                ? 'OFFLINE • SOURCE-VERIFIED BLUEPRINT'
                : 'OFFLINE PRACTICE • BLUEPRINT REQUIRES VERIFICATION',
            style: TextStyle(
                color: course.isOfficiallyVerified
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStat("${course.totalQuestions}", "Questions"),
              const SizedBox(width: 24),
              _buildStat("${course.durationMinutes}", "Minutes"),
              const SizedBox(width: 24),
              _buildStat("${course.totalMarks}", "Marks"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF38BDF8),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
