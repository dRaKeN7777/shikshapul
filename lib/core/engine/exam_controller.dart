// lib/core/engine/exam_controller.dart
// Enhanced Exam Controller: Instant Feedback, Wrong-Question Queue, Subject Filtering

// ignore_for_file: unused_import

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/exam_models.dart';
import '../data/question_bank.dart';
import '../database/database_helper.dart';

enum ExamMode { mock, real }

class ExamController extends ChangeNotifier {
  final ExamType _type;
  final ExamMode _mode;
  final List<SubjectDomain>? _subjectFilter;
  final List<String>? _weakTopics;
  final String _difficulty;
  final int? _questionCount;
  final int? _durationMinutes;

  late ExamSession _session;
  List<DynamicQuestion> _questions = [];
  final List<int?> _selectedAnswers = [];
  final List<bool> _revealed = []; // For instant feedback in mock
  final List<int> _timePerQuestion = [];
  int _currentIndex = 0;
  bool _isActive = false;
  bool _isTerminated = false;
  int _violationCount = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _questionStartTime = 0;
  Future<ExamSession>? _finishFuture;
  int _adaptiveLevel = 1;

  ExamController(
    this._type, {
    ExamMode mode = ExamMode.mock,
    List<SubjectDomain>? subjectFilter,
    List<String>? weakTopics,
    String difficulty = 'medium',
    int? questionCount,
    int? durationMinutes,
  })  : _mode = mode,
        _subjectFilter = subjectFilter,
        _weakTopics = weakTopics,
        _difficulty = mode == ExamMode.real ? 'hard' : difficulty,
        _questionCount = questionCount,
        _durationMinutes = durationMinutes {
    _session = ExamSession(
      examType: _type,
      startedAt: DateTime.now(),
      isProctored: mode == ExamMode.real,
      selectedSubjects: subjectFilter,
    );
  }

  // ─── Getters ───
  bool get isActive => _isActive;
  bool get isTerminated => _isTerminated;
  bool get isMock => _mode == ExamMode.mock;
  bool get isReal => _mode == ExamMode.real;
  int get violationCount => _violationCount;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  List<int?> get selectedAnswers => List.unmodifiable(_selectedAnswers);
  List<bool> get revealed => List.unmodifiable(_revealed);
  List<DynamicQuestion> get questions => List.unmodifiable(_questions);
  ExamSession get session => _session;

  /// NEW: remaining seconds for timer warnings
  int get remainingSeconds => _remainingSeconds;

  DynamicQuestion? get currentQuestion =>
      _isActive && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  bool get isLastQuestion => _currentIndex >= _questions.length - 1;

  String get formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get progress =>
      _questions.isEmpty ? 0 : (_currentIndex + 1) / _questions.length;

  // ─── Exam Lifecycle ───
  Future<void> startExam() async {
    QuestionEngine.init();
    final usedQuestions =
        await DatabaseHelper.instance.getUsedQuestionTexts(_type.name);
    _questions = QuestionEngine.generateExam(
      _type,
      subjectFilter: _subjectFilter,
      weakTopics: _weakTopics,
      totalQuestionCount: _questionCount,
      difficulty: _difficulty,
      excludedQuestionTexts: usedQuestions,
    );
    if (ExamSession.getProfile(_type).isAdaptive) {
      SubjectDomain? previousSubject;
      for (var index = 0; index < _questions.length; index++) {
        final question = _questions[index];
        if (question.subject != previousSubject) {
          _questions[index] = QuestionEngine.generateSingle(
            question.topicId,
            _type,
            forceLevel: 1,
            difficulty: 'easy',
          );
          previousSubject = question.subject;
        }
      }
    }
    _selectedAnswers.clear();
    _revealed.clear();
    _timePerQuestion.clear();
    for (int i = 0; i < _questions.length; i++) {
      _selectedAnswers.add(null);
      _revealed.add(false);
      _timePerQuestion.add(0);
    }

    _currentIndex = 0;
    _isActive = true;
    _isTerminated = false;
    _violationCount = 0;
    _remainingSeconds =
        (_durationMinutes ?? ExamSession.getProfile(_type).durationMinutes) *
            60;
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _endExam();
      }
    });
    notifyListeners();
  }

  void selectAnswer(int index) {
    if (!_isActive || _isTerminated) return;
    if (_currentIndex < _selectedAnswers.length) {
      if (ExamSession.getProfile(_type).isAdaptive &&
          _selectedAnswers[_currentIndex] != null) {
        return;
      }
      _selectedAnswers[_currentIndex] = index;
      if (isMock) {
        _revealed[_currentIndex] = true; // Instant reveal in mock
      }
      notifyListeners();
    }
  }

  void revealCurrent() {
    if (!isMock || !_isActive) return;
    _revealed[_currentIndex] = true;
    notifyListeners();
  }

  void nextQuestion() {
    if (!_isActive) return;
    final isAdaptive = ExamSession.getProfile(_type).isAdaptive;
    if (isAdaptive && _selectedAnswers[_currentIndex] == null) return;
    _recordTime();
    if (_currentIndex < _questions.length - 1) {
      if (isAdaptive) {
        final current = _questions[_currentIndex];
        final next = _questions[_currentIndex + 1];
        if (next.subject != current.subject) {
          _adaptiveLevel = 1;
        } else if (_selectedAnswers[_currentIndex] == current.correctIndex) {
          _adaptiveLevel = min(5, _adaptiveLevel + 1);
        } else {
          _adaptiveLevel = max(1, _adaptiveLevel - 1);
        }
        _questions[_currentIndex + 1] = QuestionEngine.generateSingle(
          next.topicId,
          _type,
          forceLevel: _adaptiveLevel,
          difficulty: _adaptiveLevel <= 2
              ? 'easy'
              : (_adaptiveLevel >= 4 ? 'hard' : 'medium'),
        );
      }
      _currentIndex++;
      _questionStartTime = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    } else {
      _endExam();
    }
  }

  void previousQuestion() {
    if (!_isActive || _currentIndex <= 0) return;
    if (ExamSession.getProfile(_type).isAdaptive) return;
    _recordTime();
    _currentIndex--;
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  /// NEW: Jump to any question (for palette navigation)
  void jumpToQuestion(int index) {
    if (!_isActive || index < 0 || index >= _questions.length) return;
    if (ExamSession.getProfile(_type).isAdaptive) return;
    _recordTime();
    _currentIndex = index;
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  /// NEW: Clear answer for a question
  void clearAnswer(int index) {
    if (ExamSession.getProfile(_type).isAdaptive) return;
    if (index < 0 || index >= _selectedAnswers.length) return;
    _selectedAnswers[index] = null;
    notifyListeners();
  }

  void _recordTime() {
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - _questionStartTime) ~/ 1000;
    if (_currentIndex < _timePerQuestion.length) {
      _timePerQuestion[_currentIndex] += elapsed;
    }
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  // ─── Exam-condition simulation ───
  void recordViolation() {
    if (!isReal) return;
    _violationCount++;
    notifyListeners();
    if (_violationCount >= 2) {
      _isTerminated = true;
      _endExam();
    }
  }

  void _endExam() {
    _timer?.cancel();
    _isActive = false;
    notifyListeners();
  }

  // ─── Finish & Analytics ───
  Future<ExamSession> finishExam() => _finishFuture ??= _finishExam();

  Future<ExamSession> _finishExam() async {
    if (_isActive) _recordTime();
    _timer?.cancel();
    _isActive = false;

    final profile = ExamSession.getProfile(_type);
    int correct = 0;
    int wrong = 0;
    int skipped = 0;
    double score = 0;
    final responses = <ExamResponse>[];

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _selectedAnswers[i];
      final isSkipped = selected == null;
      final isCorrect = !isSkipped && selected == q.correctIndex;

      if (isCorrect) {
        correct++;
        score += q.marks.toDouble();
      } else if (!isSkipped) {
        wrong++;
        if (profile.hasNegativeMarking && isReal) {
          score -= profile.negativePenalty * q.marks;
        }
      } else {
        skipped++;
      }

      final negMarks =
          (!isSkipped && !isCorrect && profile.hasNegativeMarking && isReal)
              ? profile.negativePenalty * q.marks
              : 0.0;

      responses.add(ExamResponse(
        questionId: q.id,
        questionText: q.text,
        studentAnswer: isSkipped ? null : q.options[selected],
        correctAnswer: q.options[q.correctIndex],
        isCorrect: isCorrect,
        isSkipped: isSkipped,
        timeTakenSeconds: i < _timePerQuestion.length ? _timePerQuestion[i] : 0,
        difficultyAtTime: q.difficulty,
        kuLevelAtTime: q.kuLevel,
        marksAwarded:
            isCorrect ? q.marks.toDouble() : (isSkipped ? 0.0 : -negMarks),
        negativeMarks: negMarks,
        topicId: q.topicId,
        subject: q.subject,
      ));
    }

    _session = ExamSession(
      examType: _type,
      startedAt: _session.startedAt,
      endedAt: DateTime.now(),
      totalQuestions: _questions.length,
      correctAnswers: correct,
      wrongAnswers: wrong,
      skipped: skipped,
      finalScore: score < 0 ? 0 : score,
      responses: responses,
      isProctored: isReal,
      violationCount: _violationCount,
      isTerminated: _isTerminated,
      selectedSubjects: _subjectFilter,
    );

    await DatabaseHelper.instance.saveSession(_session, _questions);
    return _session;
  }

  // ─── Weakness Report ───
  List<WeaknessReport> generateWeaknessReport() {
    final topicStats = <String, Map<String, dynamic>>{};

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _selectedAnswers[i];
      if (selected == null) continue;
      final isCorrect = selected == q.correctIndex;

      topicStats.putIfAbsent(
          q.topicId,
          () => {
                'topicName': q.topicName,
                'subject': q.subject,
                'attempts': 0,
                'correct': 0,
                'lastAttempt': DateTime.now(),
              });
      topicStats[q.topicId]!['attempts'] =
          (topicStats[q.topicId]!['attempts'] as int) + 1;
      if (isCorrect) {
        topicStats[q.topicId]!['correct'] =
            (topicStats[q.topicId]!['correct'] as int) + 1;
      }
    }

    return topicStats.entries.map((e) {
      final data = e.value;
      final attempts = data['attempts'] as int;
      final correct = data['correct'] as int;
      final accuracy = attempts > 0 ? correct / attempts : 0.0;
      final isCritical = accuracy < 0.4 && attempts >= 2;
      return WeaknessReport(
        subject: data['subject'] as SubjectDomain,
        topicId: e.key,
        topicName: data['topicName'] as String,
        totalAttempts: attempts,
        correctCount: correct,
        accuracy: accuracy,
        masteryScore: accuracy,
        isCritical: isCritical,
        recommendedActions:
            _getRecommendations(accuracy, data['topicName'] as String),
        lastAttempted: DateTime.now(),
      );
    }).toList();
  }

  List<String> _getRecommendations(double accuracy, String topic) {
    if (accuracy < 0.4) {
      return [
        'Review fundamental concepts of $topic',
        'Solve 10 basic level problems on $topic',
        'Use AI Tutor for step-by-step guidance',
        'Watch worked examples in AI Tutor',
      ];
    } else if (accuracy < 0.7) {
      return [
        'Practice intermediate problems on $topic',
        'Review common mistake patterns',
        'Attempt timed questions on $topic',
      ];
    }
    return ['Maintain proficiency with periodic revision'];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
