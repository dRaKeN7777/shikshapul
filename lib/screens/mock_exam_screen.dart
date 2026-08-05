// lib/screens/mock_exam_screen.dart
import 'package:flutter/material.dart';
import '../core/data/syllabus_tree.dart';
import '../core/engine/exam_controller.dart';
import '../models/exam_models.dart';
import 'ai_tutor_screen.dart';
import 'exam_result_screen.dart';

class MockExamScreen extends StatefulWidget {
  final CourseProfile course;
  const MockExamScreen({super.key, required this.course});

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  // Selection state
  final Set<SubjectDomain> _selectedSubjects = {};
  final Set<String> _selectedTopics = {};
  bool _isRapidFire = false;
  bool _showTopicSelection = false;
  String _difficulty = 'medium';
  bool _starting = false;

  // Exam state
  ExamController? _controller;
  bool _examStarted = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    // Pre-select all subjects by default
    _selectedSubjects.addAll(widget.course.subjectDistribution.keys);
  }

  Future<void> _startExam() async {
    if (_starting) return;
    final subjects = _selectedSubjects.toList();
    final isRapid = _isRapidFire;

    setState(() => _starting = true);

    _controller = ExamController(
      widget.course.type,
      mode: ExamMode.mock,
      subjectFilter: subjects,
      weakTopics: _selectedTopics.isNotEmpty ? _selectedTopics.toList() : null,
      difficulty: _difficulty,
      questionCount: isRapid ? 10 : null,
      durationMinutes: isRapid ? 2 : null,
    );

    _controller!.addListener(_onControllerUpdate);
    try {
      await _controller!.startExam();
      if (!mounted) return;
      setState(() {
        _examStarted = true;
        _starting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start mock exam: $error')),
      );
    }
  }

  void _onControllerUpdate() {
    if (!_controller!.isActive && _examStarted) {
      _goToResults();
      return;
    }
    setState(() {});
  }

  void _goToResults() async {
    if (_controller == null || _finishing) return;
    _finishing = true;
    final session = await _controller!.finishExam();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExamResultScreen(session: session, controller: _controller!),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_examStarted) {
      return _showSubjectSelection();
    }
    return _buildExamScreen();
  }

  // ================================================================
  //  SUBJECT & TOPIC SELECTION SCREEN
  // ================================================================
  Widget _showSubjectSelection() {
    final allSubjects = widget.course.subjectDistribution.keys.toList();
    final rapidFireEligible =
        _selectedSubjects.length <= 2 && _selectedSubjects.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text("Mock Exam Setup"),
        backgroundColor: const Color(0xFF0B1020),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Course info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "${widget.course.name}: ${widget.course.totalQuestions} questions • ${widget.course.durationMinutes} min",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "DIFFICULTY",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'easy', label: Text('Easy'), icon: Icon(Icons.eco)),
                ButtonSegment(
                    value: 'medium',
                    label: Text('Medium'),
                    icon: Icon(Icons.trending_up)),
                ButtonSegment(
                    value: 'hard',
                    label: Text('Hard'),
                    icon: Icon(Icons.local_fire_department)),
              ],
              selected: {_difficulty},
              onSelectionChanged: (value) =>
                  setState(() => _difficulty = value.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 24),

            // Subject selection header
            const Text(
              "SELECT SUBJECTS",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 12),

            // Subject chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allSubjects.map((subject) {
                final isSelected = _selectedSubjects.contains(subject);
                final color = _subjectColor(subject);
                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor: const Color(0xFF1E293B),
                  selectedColor: color.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected ? color : const Color(0xFF334155),
                    width: isSelected ? 2 : 1,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subject.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? color : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSubjects.add(subject);
                      } else {
                        _selectedSubjects.remove(subject);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Rapid Fire Toggle
            if (rapidFireEligible) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      const Color(0xFFEF4444).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt,
                            color: Color(0xFFF59E0B), size: 24),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "RAPID FIRE MODE",
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isRapidFire,
                          onChanged: (v) => setState(() => _isRapidFire = v),
                          activeThumbColor: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRapidFire
                          ? "⚡ 10 questions • 2 minutes • Instant feedback • Focused practice"
                          : "Toggle ON for quick thinking practice with fewer questions and faster pacing.",
                      style: TextStyle(
                        color: _isRapidFire
                            ? const Color(0xFFF59E0B)
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Topic selection toggle
            if (_selectedSubjects.isNotEmpty) ...[
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showTopicSelection = !_showTopicSelection),
                icon: Icon(
                  _showTopicSelection ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF38BDF8),
                ),
                label: Text(
                  _showTopicSelection
                      ? "Hide Topic Selection"
                      : "Select Specific Topics (Optional)",
                  style: const TextStyle(color: Color(0xFF38BDF8)),
                ),
              ),
              if (_showTopicSelection) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: _buildTopicSelector(),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Start button
            ElevatedButton.icon(
              onPressed: _selectedSubjects.isNotEmpty && !_starting
                  ? _startExam
                  : null,
              icon: _starting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(
                _isRapidFire && rapidFireEligible
                    ? "START RAPID FIRE"
                    : "START MOCK EXAM",
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRapidFire && rapidFireEligible
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: _selectedSubjects.expand((subject) {
          final topics = SyllabusTree.getAllTopics(subject);
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                subject.name.toUpperCase(),
                style: TextStyle(
                  color: _subjectColor(subject),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics.map((topic) {
                final isSelected = _selectedTopics.contains(topic.id);
                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor: const Color(0xFF0B1020),
                  selectedColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF334155),
                  ),
                  label: Text(
                    topic.nameEn,
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFF38BDF8) : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTopics.add(topic.id);
                      } else {
                        _selectedTopics.remove(topic.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ];
        }).toList(),
      ),
    );
  }

  // ================================================================
  //  EXAM SCREEN (Instant Feedback)
  // ================================================================
  Widget _buildExamScreen() {
    if (_controller == null) return const SizedBox.shrink();

    final q = _controller!.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    final isRevealed =
        _controller!.revealed.length > _controller!.currentIndex &&
            _controller!.revealed[_controller!.currentIndex];
    final selectedIdx =
        _controller!.selectedAnswers.length > _controller!.currentIndex
            ? _controller!.selectedAnswers[_controller!.currentIndex]
            : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B1020),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "MOCK • ${_controller!.currentIndex + 1}/${_controller!.totalQuestions}",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            if (_isRapidFire)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 14),
                    SizedBox(width: 4),
                    Text("RAPID",
                        style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ValueListenableBuilder<int>(
              valueListenable: _controller!.remainingSecondsListenable,
              builder: (context, remaining, child) => Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                ),
                child: Text(
                  _controller!.formattedTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value:
                  (_controller!.currentIndex + 1) / _controller!.totalQuestions,
              backgroundColor: const Color(0xFF334155),
              color: const Color(0xFF10B981),
              minHeight: 4,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject tag
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _subjectColor(q.subject).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              _subjectColor(q.subject).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      q.subject.name.toUpperCase(),
                      style: TextStyle(
                        color: _subjectColor(q.subject),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      q.topicName,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    q.expertReviewed ? Icons.verified : Icons.science_outlined,
                    size: 13,
                    color: q.expertReviewed
                        ? const Color(0xFF10B981)
                        : Colors.white38,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      q.trustLabel,
                      style: TextStyle(
                        color: q.expertReviewed
                            ? const Color(0xFF10B981)
                            : Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  q.text,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Options with instant feedback
              ...List.generate(q.options.length, (idx) {
                final isSelected = selectedIdx == idx;
                final isCorrect = idx == q.correctIndex;
                final showCorrect = isRevealed && isCorrect;
                final showWrong = isRevealed && isSelected && !isCorrect;

                Color borderColor = const Color(0xFF334155);
                Color bgColor = const Color(0xFF0B1020);
                Color textColor = Colors.white70;

                if (showCorrect) {
                  borderColor = const Color(0xFF10B981);
                  bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
                  textColor = Colors.white;
                } else if (showWrong) {
                  borderColor = const Color(0xFFEF4444);
                  bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
                  textColor = Colors.white;
                } else if (isSelected) {
                  borderColor = const Color(0xFF38BDF8);
                  bgColor = const Color(0xFF38BDF8).withValues(alpha: 0.15);
                  textColor = Colors.white;
                }

                return GestureDetector(
                  onTap:
                      isRevealed ? null : () => _controller!.selectAnswer(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: borderColor,
                          width:
                              isSelected || showCorrect || showWrong ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: showCorrect
                                ? const Color(0xFF10B981)
                                : showWrong
                                    ? const Color(0xFFEF4444)
                                    : isSelected
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF334155),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: showCorrect
                                ? const Icon(Icons.check,
                                    color: Colors.black, size: 18)
                                : showWrong
                                    ? const Icon(Icons.close,
                                        color: Colors.black, size: 18)
                                    : Text(
                                        String.fromCharCode(65 + idx),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            q.options[idx],
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: isSelected || showCorrect || showWrong
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Instant feedback card
              if (isRevealed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedIdx == q.correctIndex
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedIdx == q.correctIndex
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            selectedIdx == q.correctIndex
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: selectedIdx == q.correctIndex
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedIdx == q.correctIndex
                                ? "CORRECT!"
                                : "INCORRECT",
                            style: TextStyle(
                              color: selectedIdx == q.correctIndex
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (selectedIdx != q.correctIndex) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Correct answer: ${q.options[q.correctIndex]}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AiTutorScreen(course: widget.course),
                              ),
                            );
                          },
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text("LEARN THIS TOPIC WITH AI"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Navigation
              Row(
                children: [
                  if (_controller!.currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _controller!.previousQuestion,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        child: const Text("PREV"),
                      ),
                    ),
                  if (_controller!.currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isRevealed ? _controller!.nextQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _controller!.isLastQuestion ? "FINISH" : "NEXT",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
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

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Exit Mock Exam?",
            style: TextStyle(color: Colors.white)),
        content: const Text("Your unfinished progress will be discarded.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("STAY", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text("EXIT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _subjectColor(SubjectDomain subject) {
    switch (subject) {
      case SubjectDomain.physics:
        return const Color(0xFF38BDF8);
      case SubjectDomain.chemistry:
        return const Color(0xFFA855F7);
      case SubjectDomain.mathematics:
        return const Color(0xFFF59E0B);
      case SubjectDomain.biology:
        return const Color(0xFF10B981);
      case SubjectDomain.english:
        return const Color(0xFFF43F5E);
      case SubjectDomain.mat:
        return const Color(0xFFEC4899);
      case SubjectDomain.healthKnowledge:
        return const Color(0xFF14B8A6);
    }
  }
}
