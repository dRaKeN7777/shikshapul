// lib/screens/weakness_analysis_screen.dart
import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/exam_models.dart';
import 'ai_tutor_screen.dart';
import 'mock_exam_screen.dart';

class WeaknessAnalysisScreen extends StatefulWidget {
  final CourseProfile course;
  const WeaknessAnalysisScreen({super.key, required this.course});

  @override
  State<WeaknessAnalysisScreen> createState() => _WeaknessAnalysisScreenState();
}

class _WeaknessAnalysisScreenState extends State<WeaknessAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  List<Map<String, dynamic>> _masteryData = [];
  List<Map<String, dynamic>> _subjectSummary = [];
  List<Map<String, dynamic>> _examHistory = [];
  List<Map<String, dynamic>> _persistentWeak = [];
  List<Map<String, dynamic>> _improved = [];

  String? _selectedTrendTopicId;
  List<Map<String, dynamic>> _trendData = [];

  String get _examType => widget.course.type.name;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final db = DatabaseHelper.instance;
    final results = await Future.wait([
      db.getMasterySummaryByType(_examType),
      db.getSubjectWiseSummaryByType(_examType),
      db.getAllExamsWithWeaknessByType(_examType),
      db.getPersistentWeaknessByType(_examType),
      db.getRecentlyImprovedTopicsByType(_examType),
    ]);

    if (!mounted) return;
    setState(() {
      _masteryData = results[0];
      _subjectSummary = results[1];
      _examHistory = results[2];
      _persistentWeak = results[3];
      _improved = results[4];
      _loading = false;
    });
  }

  Future<void> _loadTrend(String topicId) async {
    final data = await DatabaseHelper.instance
        .getTopicMasteryHistoryByType(topicId, _examType);
    if (!mounted) return;
    setState(() {
      _selectedTrendTopicId = topicId;
      _trendData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: Text('${widget.course.name} Weakness'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.subject), text: 'Subjects'),
            Tab(icon: Icon(Icons.history), text: 'Exams'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSubjectsTab(),
                _buildExamsTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  // ================================================================
  //  OVERVIEW TAB
  // ================================================================
  Widget _buildOverviewTab() {
    if (_masteryData.isEmpty) return _buildEmptyState();

    final weakCount =
        _masteryData.where((r) => (r['avg_mastery'] as num) < 0.6).length;
    final strongCount =
        _masteryData.where((r) => (r['avg_mastery'] as num) >= 0.8).length;
    final totalTopics = _masteryData.length;
    final overallMastery = totalTopics > 0
        ? _masteryData
                .map((r) => (r['avg_mastery'] as num))
                .reduce((a, b) => a + b) /
            totalTopics
        : 0.0;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCards(overallMastery, weakCount, strongCount, totalTopics),
          const SizedBox(height: 20),
          if (_persistentWeak.isNotEmpty) ...[
            _buildSectionHeader('Persistent Weaknesses', Icons.warning_amber),
            const SizedBox(height: 12),
            ..._persistentWeak
                .take(5)
                .map((w) => _buildWeaknessCard(w, showActions: true)),
            const SizedBox(height: 20),
          ],
          if (_improved.isNotEmpty) ...[
            _buildSectionHeader('Recently Improved', Icons.trending_up),
            const SizedBox(height: 12),
            ..._improved.take(5).map((i) => _buildImprovementCard(i)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCards(
      double overallMastery, int weak, int strong, int total) {
    return Row(
      children: [
        _statCard('Overall', '${(overallMastery * 100).toStringAsFixed(0)}%',
            const Color(0xFF38BDF8), Icons.assessment),
        const SizedBox(width: 12),
        _statCard('Weak', '$weak', const Color(0xFFEF4444), Icons.warning),
        const SizedBox(width: 12),
        _statCard(
            'Strong', '$strong', const Color(0xFF10B981), Icons.check_circle),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ================================================================
  //  SUBJECTS TAB
  // ================================================================
  Widget _buildSubjectsTab() {
    if (_subjectSummary.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjectSummary.length,
      itemBuilder: (context, index) {
        final subject = _subjectSummary[index];
        final name = subject['subject'] as String? ?? 'Unknown';
        final mastery = (subject['overall_mastery'] as num?)?.toDouble() ?? 0.0;
        final weakCount = (subject['weak_count'] as num?)?.toInt() ?? 0;
        final topicCount = (subject['topic_count'] as num?)?.toInt() ?? 0;
        final totalAttempts = (subject['total_attempts'] as num?)?.toInt() ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: _subjectColor(name).withValues(alpha: 0.3)),
          ),
          child: ExpansionTile(
            iconColor: _subjectColor(name),
            collapsedIconColor: Colors.white54,
            title: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _subjectColor(name),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text('$topicCount topics • $totalAttempts attempts',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (weakCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$weakCount weak',
                        style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: mastery,
                      backgroundColor: const Color(0xFF334155),
                      color: _masteryColor(mastery),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(mastery * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: _masteryColor(mastery),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
            ),
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance
                    .getWeakTopicsBySubjectAndType(name, _examType),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No weak topics in this subject!',
                          style: TextStyle(color: Color(0xFF10B981))),
                    );
                  }
                  return Column(
                    children: snapshot.data!
                        .map((topic) => _buildTopicRow(topic))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicRow(Map<String, dynamic> topic) {
    final topicName = topic['topic'] as String? ?? 'Unknown';
    final topicId = topic['topic_id'] as String? ?? '';
    final mastery = (topic['avg_mastery'] as num?)?.toDouble() ?? 0.0;
    final attempts = (topic['total_attempts'] as num?)?.toInt() ?? 0;
    final streak = (topic['streak'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topicName,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniBadge('$attempts attempts', Colors.grey),
                    const SizedBox(width: 6),
                    if (streak >= 3)
                      _miniBadge('$streak streak', const Color(0xFFF59E0B)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: mastery,
              backgroundColor: const Color(0xFF334155),
              color: _masteryColor(mastery),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(mastery * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  color: _masteryColor(mastery),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _iconButton(Icons.school, const Color(0xFF38BDF8), () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiTutorScreen(
                    course: widget.course,
                    focusTopicId: topicId,
                    initialQuery: 'Help me master $topicName step by step',
                  ),
                ));
          }),
          _iconButton(Icons.play_arrow, const Color(0xFF10B981), () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MockExamScreen(course: widget.course),
                ));
          }),
        ],
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ================================================================
  //  EXAMS TAB
  // ================================================================
  Widget _buildExamsTab() {
    if (_examHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ${widget.course.name} exams yet',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a Mock or Simulator exam to see your progress here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _examHistory.length,
      itemBuilder: (context, index) {
        final exam = _examHistory[index];
        final examType = exam['exam_type'] as String? ?? 'UNKNOWN';
        final score = (exam['percentage'] as num?)?.toDouble() ?? 0.0;
        final correct = (exam['correct_answers'] as num?)?.toInt() ?? 0;
        final total = (exam['total_questions'] as num?)?.toInt() ?? 1;
        final weakCount = (exam['weak_count'] as num?)?.toInt() ?? 0;
        final dateStr = exam['started_at'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        final isTerminated = (exam['is_terminated'] as num?)?.toInt() == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTerminated
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF334155),
            ),
          ),
          child: ExpansionTile(
            iconColor: const Color(0xFF38BDF8),
            collapsedIconColor: Colors.white54,
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(examType,
                      style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      Text('$correct / $total correct',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                      Text('$weakCount weak topics',
                          style: const TextStyle(
                              color: Color(0xFFEF4444), fontSize: 11)),
                    ],
                  ),
                ),
                if (isTerminated)
                  const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: const Color(0xFF334155),
                      color: score >= 60
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${score.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: score >= 60
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
            ),
            children: [
              if ((exam['weak_topics'] as List).isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('WEAK AREAS IN THIS EXAM',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                ...(exam['weak_topics'] as List)
                    .map((w) => _buildExamWeaknessRow(w)),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No weak areas! Excellent performance.',
                      style: TextStyle(color: Color(0xFF10B981))),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamWeaknessRow(Map<String, dynamic> w) {
    final topicName = w['topic_name'] as String? ?? 'Unknown';
    final subject = w['subject'] as String? ?? '';
    final mastery = (w['mastery_at_exam'] as num?)?.toDouble() ?? 0.0;
    final attempted = (w['questions_attempted'] as num?)?.toInt() ?? 0;
    final correct = (w['questions_correct'] as num?)?.toInt() ?? 0;
    final recommendation = w['recommendation'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 30,
                decoration: BoxDecoration(
                  color: _subjectColor(subject),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topicName,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                    Text('$correct / $attempted correct',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${(mastery * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(recommendation,
                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
          ],
        ],
      ),
    );
  }

  // ================================================================
  //  TRENDS TAB
  // ================================================================
  Widget _buildTrendsTab() {
    if (_masteryData.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              value: _selectedTrendTopicId ??
                  _masteryData.first['topic_id'] as String?,
              hint: const Text('Select topic to view trend',
                  style: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF38BDF8)),
              items: _masteryData.map((m) {
                final topicId = m['topic_id'] as String? ?? '';
                final topicName = m['topic'] as String? ?? 'Unknown';
                final subject = m['subject'] as String? ?? '';
                return DropdownMenuItem(
                  value: topicId,
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: _subjectColor(subject),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              Text(topicName, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _loadTrend(val);
              },
            ),
          ),
        ),
        Expanded(
          child: _trendData.length >= 2
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: _MasteryLineChart(data: _trendData),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.show_chart,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _trendData.isEmpty
                            ? 'Select a topic to see mastery trend over time'
                            : 'Need at least 2 exam records to show trend',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ================================================================
  //  SHARED WIDGETS
  // ================================================================
  Widget _buildWeaknessCard(Map<String, dynamic> row,
      {bool showActions = false}) {
    final subject = row['subject'] as String? ?? 'Unknown';
    final topic = row['topic'] as String? ?? 'Unknown';
    final mastery = (row['avg_mastery'] as num?)?.toDouble() ?? 0.0;
    final attempts = (row['total_attempts'] as num?)?.toInt() ?? 0;
    final status = row['status'] as String? ?? 'Weak';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('$subject • $topic',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: mastery,
            backgroundColor: const Color(0xFF334155),
            color: const Color(0xFFEF4444),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Mastery: ${(mastery * 100).toStringAsFixed(0)}%  •  $attempts attempts',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (showActions)
                Row(
                  children: [
                    _actionChip('Study AI', const Color(0xFF38BDF8), () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AiTutorScreen(course: widget.course),
                          ));
                    }),
                    const SizedBox(width: 8),
                    _actionChip('Practice', const Color(0xFF10B981), () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MockExamScreen(course: widget.course),
                          ));
                    }),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCard(Map<String, dynamic> i) {
    final topicName = i['topic_name'] as String? ?? 'Unknown';
    final subject = i['subject'] as String? ?? '';
    final latest = (i['latest_mastery'] as num?)?.toDouble() ?? 0.0;
    final previous = (i['previous_mastery'] as num?)?.toDouble() ?? 0.0;
    final improvement = (i['improvement'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up,
                color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topicName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subject,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${(improvement * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text(
                  '${(previous * 100).toStringAsFixed(0)}% → ${(latest * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No data yet',
              style: TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
              'Take a Mock Exam or Simulator session to see your weaknesses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('GO TO EXAMS',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _masteryColor(double mastery) {
    if (mastery < 0.4) return const Color(0xFFEF4444);
    if (mastery < 0.6) return const Color(0xFFF59E0B);
    if (mastery < 0.8) return const Color(0xFF38BDF8);
    return const Color(0xFF10B981);
  }

  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return const Color(0xFF38BDF8);
      case 'chemistry':
        return const Color(0xFFA855F7);
      case 'mathematics':
        return const Color(0xFFF59E0B);
      case 'math':
        return const Color(0xFFF59E0B);
      case 'biology':
        return const Color(0xFF10B981);
      case 'english':
        return const Color(0xFFF43F5E);
      case 'mat':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

// ================================================================
//  CUSTOM LINE CHART PAINTER
// ================================================================
class _MasteryLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _MasteryLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mastery Trend',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(data: data),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exam 1',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
              Text('Exam ${data.length}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final values = data
        .map((d) => (d['mastery_value'] as num?)?.toDouble() ?? 0.0)
        .toList();
    if (values.length < 2) return;

    const padding = 20.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;

    final gridPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = padding + chartH * (i / 4);
      canvas.drawLine(
          Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = padding + (chartW / (values.length - 1)) * i;
      final y = padding + chartH * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(padding + chartW, padding + chartH);
    fillPath.lineTo(padding, padding + chartH);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()
      ..color = const Color(0xFF0B1020)
      ..style = PaintingStyle.fill;
    final pointBorder = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < values.length; i++) {
      final x = padding + (chartW / (values.length - 1)) * i;
      final y = padding + chartH * (1 - values[i]);
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
