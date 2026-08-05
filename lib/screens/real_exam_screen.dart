// lib/screens/real_exam_screen.dart
import 'package:flutter/material.dart';
import '../core/engine/exam_controller.dart';
import '../models/exam_models.dart';
import 'exam_result_screen.dart';

class RealExamScreen extends StatefulWidget {
  final CourseProfile course;
  const RealExamScreen({super.key, required this.course});

  @override
  State<RealExamScreen> createState() => _RealExamScreenState();
}

class _RealExamScreenState extends State<RealExamScreen>
    with WidgetsBindingObserver {
  late ExamController _controller;
  bool _started = false;
  bool _starting = false;
  bool _finishing = false;
  bool _lifecycleViolationRecorded = false;

  // Question status: 0=not visited, 1=visited, 2=answered, 3=marked for review
  final List<int> _questionStatus = [];
  final Set<int> _markedForReview = {};

  // Subject section tracking
  late List<_SubjectSection> _sections;
  int _currentSectionIndex = 0;

  // Timer warnings
  bool _warned10Min = false;
  bool _warned5Min = false;
  bool _warned1Min = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ExamController(widget.course.type, mode: ExamMode.real);
    _controller.addListener(_onUpdate);
    _controller.remainingSecondsListenable.addListener(_onTimerUpdate);
    _buildSubjectSections();
  }

  void _buildSubjectSections() {
    final dist = widget.course.subjectDistribution;
    final subjects = widget.course.subjectOrder;
    _sections = [];
    int startIdx = 0;

    for (final subject in subjects) {
      final count = dist[subject] ?? 0;
      if (count > 0) {
        _sections.add(_SubjectSection(
          subject: subject,
          startIndex: startIdx,
          endIndex: startIdx + count - 1,
          color: _subjectColor(subject),
        ));
        startIdx += count;
      }
    }

    _questionStatus.addAll(List.filled(widget.course.totalQuestions, 0));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.remainingSecondsListenable.removeListener(_onTimerUpdate);
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lifecycleViolationRecorded = false;
      return;
    }
    if (_started && _controller.isActive) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        if (_lifecycleViolationRecorded) return;
        _lifecycleViolationRecorded = true;
        _controller.recordViolation();
        if (_controller.violationCount >= 2) {
          _showTerminatedDialog();
        } else {
          _showWarningDialog();
        }
      }
    }
  }

  void _onUpdate() {
    if (!_controller.isActive && _started && !_controller.isTerminated) {
      _goToResults();
      return;
    }

    if (_controller.currentIndex < widget.course.totalQuestions) {
      for (int i = 0; i < _sections.length; i++) {
        if (_controller.currentIndex >= _sections[i].startIndex &&
            _controller.currentIndex <= _sections[i].endIndex) {
          _currentSectionIndex = i;
          break;
        }
      }
    }

    if (_controller.currentIndex < _questionStatus.length) {
      if (_questionStatus[_controller.currentIndex] == 0) {
        _questionStatus[_controller.currentIndex] = 1;
      }
      if (_controller.selectedAnswers.length > _controller.currentIndex &&
          _controller.selectedAnswers[_controller.currentIndex] != null) {
        _questionStatus[_controller.currentIndex] = 2;
      }
    }

    setState(() {});
  }

  void _onTimerUpdate() {
    if (!mounted) return;
    final remaining = _controller.remainingSeconds;
    if (remaining <= 600 && remaining > 590 && !_warned10Min) {
      _warned10Min = true;
      _showTimeWarning("10 MINUTES REMAINING");
    }
    if (remaining <= 300 && remaining > 290 && !_warned5Min) {
      _warned5Min = true;
      _showTimeWarning("5 MINUTES REMAINING");
    }
    if (remaining <= 60 && remaining > 50 && !_warned1Min) {
      _warned1Min = true;
      _showTimeWarning("1 MINUTE REMAINING!");
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("⚠️ WARNING",
            style:
                TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: const Text(
          "You left the exam screen!\nOne more violation and your exam will be TERMINATED.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("RETURN TO EXAM",
                style: TextStyle(
                    color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTerminatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("EXAM TERMINATED",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          "You violated the proctoring policy twice. Your session has ended.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToResults();
            },
            child: const Text("VIEW RESULTS",
                style: TextStyle(
                    color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTimeWarning(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Icon(Icons.timer, color: Color(0xFFF59E0B), size: 48),
        content: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CONTINUE",
                style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  void _goToResults() async {
    if (_finishing) return;
    _finishing = true;
    final session = await _controller.finishExam();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExamResultScreen(session: session, controller: _controller),
      ),
    );
  }

  void _toggleMarkForReview() {
    final idx = _controller.currentIndex;
    setState(() {
      if (_markedForReview.contains(idx)) {
        _markedForReview.remove(idx);
        if (_controller.selectedAnswers.length > idx &&
            _controller.selectedAnswers[idx] != null) {
          _questionStatus[idx] = 2;
        } else {
          _questionStatus[idx] = 1;
        }
      } else {
        _markedForReview.add(idx);
        _questionStatus[idx] = 3;
      }
    });
  }

  void _jumpToQuestion(int index) {
    Navigator.pop(context);
    _controller.jumpToQuestion(index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return _buildStartScreen();
    if (_controller.isTerminated) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1020),
        body: Center(
          child: Text("EXAM TERMINATED",
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
        ),
      );
    }
    if (!_controller.isActive) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1020),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
      );
    }

    final q = _controller.currentQuestion!;
    final currentSection = _sections[_currentSectionIndex];
    final sectionProgress =
        _controller.currentIndex - currentSection.startIndex + 1;
    final sectionTotal =
        currentSection.endIndex - currentSection.startIndex + 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF0B1020),
          elevation: 0,
          title: Column(
            children: [
              Text(
                "${widget.course.name} • ${_controller.currentIndex + 1}/${widget.course.totalQuestions}",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: currentSection.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: currentSection.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  "${currentSection.subject.name.toUpperCase()}  $sectionProgress/$sectionTotal",
                  style: TextStyle(
                      color: currentSection.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, color: Color(0xFFEF4444), size: 14),
                  const SizedBox(width: 4),
                  Text("${_controller.violationCount}/2",
                      style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _controller.remainingSecondsListenable,
              builder: (context, remaining, child) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: remaining <= 60
                      ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: remaining <= 60
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  _controller.formattedTime,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: remaining <= 60
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
            if (!widget.course.isAdaptive)
              IconButton(
                icon: const Icon(Icons.grid_view, color: Color(0xFF38BDF8)),
                onPressed: () => _showQuestionPalette(),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value:
                  (_controller.currentIndex + 1) / widget.course.totalQuestions,
              backgroundColor: const Color(0xFF334155),
              color: currentSection.color,
              minHeight: 4,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _sections.map((section) {
                  final isCurrent = section.subject == currentSection.subject;
                  final sectionDone =
                      _controller.currentIndex > section.endIndex;
                  final sectionProgress = sectionDone
                      ? 1.0
                      : (_controller.currentIndex >= section.startIndex
                          ? (_controller.currentIndex -
                                  section.startIndex +
                                  1) /
                              (section.endIndex - section.startIndex + 1)
                          : 0.0);

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          Text(
                            section.subject.name.toUpperCase(),
                            style: TextStyle(
                              color: isCurrent ? section.color : Colors.grey,
                              fontSize: 9,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: sectionProgress,
                            backgroundColor: const Color(0xFF334155),
                            color: section.color,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: currentSection.color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentSection.color
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Q${_controller.currentIndex + 1}",
                                  style: TextStyle(
                                    color: currentSection.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (q.marks > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text("${q.marks} marks",
                                      style: const TextStyle(
                                          color: Color(0xFFF59E0B),
                                          fontSize: 11)),
                                ),
                              const Spacer(),
                              if (_markedForReview
                                  .contains(_controller.currentIndex))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFF8B5CF6)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bookmark,
                                          color: Color(0xFF8B5CF6), size: 12),
                                      SizedBox(width: 4),
                                      Text("REVIEW",
                                          style: TextStyle(
                                              color: Color(0xFF8B5CF6),
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                q.expertReviewed
                                    ? Icons.verified
                                    : Icons.science_outlined,
                                size: 13,
                                color: q.expertReviewed
                                    ? const Color(0xFF10B981)
                                    : Colors.white38,
                              ),
                              const SizedBox(width: 5),
                              Text(
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
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            q.text,
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(q.options.length, (idx) {
                      final isSelected = _controller.selectedAnswers.length >
                              _controller.currentIndex &&
                          _controller
                                  .selectedAnswers[_controller.currentIndex] ==
                              idx;
                      return GestureDetector(
                        onTap: () => _controller.selectAnswer(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? currentSection.color.withValues(alpha: 0.15)
                                : const Color(0xFF0B1020),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? currentSection.color
                                  : const Color(0xFF334155),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? currentSection.color
                                      : const Color(0xFF334155),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
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
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: currentSection.color, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Color(0xFF334155))),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (!widget.course.isAdaptive)
                          OutlinedButton.icon(
                            onPressed: _toggleMarkForReview,
                            icon: Icon(
                              _markedForReview
                                      .contains(_controller.currentIndex)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: const Color(0xFF8B5CF6),
                              size: 18,
                            ),
                            label: Text(
                              _markedForReview
                                      .contains(_controller.currentIndex)
                                  ? "UNMARK"
                                  : "REVIEW",
                              style: const TextStyle(
                                  color: Color(0xFF8B5CF6), fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF8B5CF6)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (!widget.course.isAdaptive &&
                            _controller.selectedAnswers.length >
                                _controller.currentIndex &&
                            _controller.selectedAnswers[
                                    _controller.currentIndex] !=
                                null)
                          OutlinedButton.icon(
                            onPressed: () {
                              final index = _controller.currentIndex;
                              _controller.clearAnswer(index);
                              setState(() => _questionStatus[index] =
                                  _markedForReview.contains(index) ? 3 : 1);
                            },
                            icon: const Icon(Icons.clear,
                                color: Colors.grey, size: 18),
                            label: const Text("CLEAR",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        const Spacer(),
                        if (!widget.course.isAdaptive &&
                            _controller.currentIndex > 0)
                          ElevatedButton.icon(
                            onPressed: _controller.previousQuestion,
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text("PREV",
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF334155),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _controller.currentIndex ==
                                  widget.course.totalQuestions - 1
                              ? _showFinishConfirmation
                              : _controller.nextQuestion,
                          icon: Icon(
                            _controller.currentIndex ==
                                    widget.course.totalQuestions - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                            size: 18,
                          ),
                          label: Text(
                            _controller.currentIndex ==
                                    widget.course.totalQuestions - 1
                                ? "FINISH"
                                : "NEXT",
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _controller.currentIndex ==
                                    widget.course.totalQuestions - 1
                                ? const Color(0xFF10B981)
                                : const Color(0xFF38BDF8),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionPalette() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Question Palette",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legendDot(const Color(0xFF334155), "Not visited"),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF38BDF8), "Visited"),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF10B981), "Answered"),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF8B5CF6), "Review"),
                ],
              ),
              const SizedBox(height: 16),
              ..._sections.map((section) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: section.color, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(section.subject.name.toUpperCase(),
                            style: TextStyle(
                                color: section.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        section.endIndex - section.startIndex + 1,
                        (i) {
                          final qIdx = section.startIndex + i;
                          final status = _questionStatus[qIdx];
                          final isCurrent = qIdx == _controller.currentIndex;
                          return GestureDetector(
                            onTap: () => _jumpToQuestion(qIdx),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _statusColor(status),
                                borderRadius: BorderRadius.circular(10),
                                border: isCurrent
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  "${qIdx + 1}",
                                  style: TextStyle(
                                    color: status == 0
                                        ? Colors.grey
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showFinishConfirmation();
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.black),
                  label: const Text("FINISH EXAM",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return const Color(0xFF334155);
      case 1:
        return const Color(0xFF38BDF8).withValues(alpha: 0.3);
      case 2:
        return const Color(0xFF10B981);
      case 3:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF334155);
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Leave Exam?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "You cannot resume this exam. Your progress will be submitted.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("STAY", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToResults();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text("EXIT & SUBMIT",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmation() {
    final answered = _controller.selectedAnswers.where((a) => a != null).length;
    final notAnswered = widget.course.totalQuestions - answered;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Submit Exam?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Answered: $answered",
                style: const TextStyle(color: Color(0xFF10B981))),
            Text("Not answered: $notAnswered",
                style: const TextStyle(color: Color(0xFFEF4444))),
            if (_markedForReview.isNotEmpty)
              Text("Marked for review: ${_markedForReview.length}",
                  style: const TextStyle(color: Color(0xFF8B5CF6))),
            const SizedBox(height: 12),
            const Text("Once submitted, you cannot change your answers.",
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToResults();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            child: const Text("SUBMIT",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_rounded,
                  size: 80, color: Color(0xFFF59E0B)),
              const SizedBox(height: 24),
              Text(
                widget.course.name.toUpperCase(),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text("EXAM-CONDITION SIMULATOR",
                  style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 4)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.format_list_numbered,
                        "${widget.course.totalQuestions} Questions"),
                    const SizedBox(height: 12),
                    _infoRow(Icons.timer,
                        "${widget.course.durationMinutes} Minutes"),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.gavel,
                      widget.course.hasNegativeMarking
                          ? "Negative Marking Applies"
                          : "No Negative Marking",
                    ),
                    const Divider(color: Color(0xFF334155), height: 24),
                    ..._sections.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: s.color, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Text(
                                  "${s.subject.name}: ${s.endIndex - s.startIndex + 1} questions",
                                  style:
                                      TextStyle(color: s.color, fontSize: 13)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Text("⚠️ PROCTORING RULES",
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      "• Do NOT leave this app\n• Do NOT switch apps\n• Do NOT press back\n• 2 violations = AUTO TERMINATION",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _starting
                    ? null
                    : () async {
                        setState(() => _starting = true);
                        try {
                          await _controller.startExam();
                          if (!mounted) return;
                          setState(() {
                            _started = true;
                            _starting = false;
                          });
                        } catch (error) {
                          if (!mounted) return;
                          setState(() => _starting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Could not start exam: $error')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _starting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text("START EXAM",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
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

class _SubjectSection {
  final SubjectDomain subject;
  final int startIndex;
  final int endIndex;
  final Color color;

  _SubjectSection({
    required this.subject,
    required this.startIndex,
    required this.endIndex,
    required this.color,
  });
}
