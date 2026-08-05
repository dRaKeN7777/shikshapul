import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/engine/exam_controller.dart';
import '../models/exam_models.dart';
import 'ai_tutor_screen.dart';

class ExamResultScreen extends StatelessWidget {
  final ExamSession session;
  final ExamController controller;
  const ExamResultScreen({
    super.key,
    required this.session,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final weaknesses = controller.generateWeaknessReport();

    // Sort weaknesses by lowest accuracy first
    weaknesses.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final criticalWeaknesses = weaknesses.where((w) => w.isCritical).toList();

    // Aggregate Data for a Clean Subject-Based Radar Chart
    final Map<String, List<double>> subjectScores = {};
    for (var w in weaknesses) {
      subjectScores.putIfAbsent(w.subject.name, () => []).add(w.accuracy);
    }

    final List<MapEntry<String, double>> radarData =
        subjectScores.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key.toUpperCase(), avg);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
          title: const Text("Exam Results"),
          backgroundColor: const Color(0xFF0B1020),
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 16),
            _buildRankOnePath(weaknesses),
            const SizedBox(height: 24),

            if (criticalWeaknesses.isNotEmpty)
              _buildCleanCriticalAlert(context, criticalWeaknesses),

            const SizedBox(height: 24),
            const Text(
              "SUBJECT MASTERY RADAR",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),

            // Fixed Radar Chart Height and Padding
            SizedBox(
              height: 260,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSubjectRadarChart(radarData),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              "TOP WEAKNESSES TO FIX",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Only show the top 5 absolute worst topics to prevent UI clutter
            ...weaknesses.take(5).map((w) => _buildWeaknessTile(context, w)),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiTutorScreen(
                      course: ExamSession.getProfile(session.examType),
                      focusTopicId:
                          weaknesses.isEmpty ? null : weaknesses.first.topicId,
                      initialQuery: weaknesses.isEmpty
                          ? 'Build me a scholarship-focused revision plan'
                          : 'Build a step-by-step mastery plan for ${weaknesses.first.topicName}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text("STUDY WEAK TOPICS WITH AI"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRankOnePath(List<WeaknessReport> weaknesses) {
    final accuracy = session.accuracy;
    final completion = session.totalQuestions == 0
        ? 0.0
        : (session.totalQuestions - session.skipped) / session.totalQuestions;
    final readiness = (accuracy * 0.8 + completion * 0.2).clamp(0.0, 1.0);
    final tier = readiness >= 0.9
        ? 'Strong practice consistency'
        : readiness >= 0.75
            ? 'Competitive — close the remaining gaps'
            : readiness >= 0.55
                ? 'Building momentum'
                : 'Foundation phase';
    final nextTarget = readiness >= 0.9
        ? 'Repeat this standard under full exam timing.'
        : weaknesses.isEmpty
            ? 'Raise accuracy above 90% in a full timed paper.'
            : 'Master ${weaknesses.first.topicName}, then retake a hard mock.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFF59E0B)),
              SizedBox(width: 9),
              Text('STUDY READINESS PATH',
                  style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: readiness,
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: const Color(0xFF334155),
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 9),
          Text('${(readiness * 100).round()}% readiness • $tier',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(nextTarget,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.4)),
          const SizedBox(height: 6),
          const Text(
            'Readiness is a personal study indicator, not an official rank or scholarship guarantee.',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final pct = session.totalQuestions == 0
        ? 0
        : (session.correctAnswers / session.totalQuestions * 100);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF0B1020)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ]),
      child: Column(
        children: [
          const Text(
            "YOUR SCORE",
            style: TextStyle(
                color: Colors.white70, fontSize: 14, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            session.finalScore.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Color(0xFF38BDF8),
              height: 1.1,
            ),
          ),
          Text(
            "${session.correctAnswers}/${session.totalQuestions} correct • ${pct.toStringAsFixed(1)}%",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat("Correct", session.correctAnswers.toString(),
                  const Color(0xFF10B981)),
              Container(width: 1, height: 40, color: Colors.white12),
              _buildMiniStat("Wrong", session.wrongAnswers.toString(),
                  const Color(0xFFEF4444)),
              Container(width: 1, height: 40, color: Colors.white12),
              _buildMiniStat("Skipped", session.skipped.toString(),
                  const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // FIXED: Clean Bulleted List instead of a massive paragraph!
  Widget _buildCleanCriticalAlert(
      BuildContext context, List<WeaknessReport> critical) {
    final topCritical = critical.take(3).toList();
    final extraCount = critical.length - 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 12),
              Text(
                "CRITICAL WEAKNESSES",
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topCritical.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ",
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        "${w.subject.name.toUpperCase()} - ${w.topicName}",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
          if (extraCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "+ $extraCount more topics require attention",
                style: TextStyle(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  // FIXED: Radar Chart aggregated by Subject for a clean geometric shape
  Widget _buildSubjectRadarChart(List<MapEntry<String, double>> radarData) {
    if (radarData.isEmpty) return const SizedBox.shrink();

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        gridBorderData: const BorderSide(color: Color(0xFF334155), width: 1.5),
        tickBorderData: const BorderSide(color: Colors.transparent),
        ticksTextStyle: const TextStyle(color: Colors.transparent),
        radarBorderData: const BorderSide(color: Color(0xFF38BDF8), width: 2),

        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        titlePositionPercentageOffset:
            0.25, // Pushed text further out so it doesn't overlap

        getTitle: (index, angle) {
          if (index >= radarData.length) return const RadarChartTitle(text: "");
          return RadarChartTitle(
            text: radarData[index].key,
            angle: angle,
          );
        },
        dataSets: [
          RadarDataSet(
            fillColor: const Color(0xFF38BDF8).withValues(alpha: 0.3),
            borderColor: const Color(0xFF38BDF8),
            entryRadius: 5,
            dataEntries:
                radarData.map((e) => RadarEntry(value: e.value * 100)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaknessTile(BuildContext context, WeaknessReport w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: w.isCritical
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  w.topicName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: w.accuracy < 0.4
                      ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                      : w.accuracy < 0.7
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                          : const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(w.accuracy * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: w.accuracy < 0.4
                        ? const Color(0xFFEF4444)
                        : w.accuracy < 0.7
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            w.subject.name.toUpperCase(),
            style: const TextStyle(
                color: Colors.grey, fontSize: 11, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          ...w.recommendedActions.take(2).map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right,
                          color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          action,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
