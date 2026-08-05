// lib/models/exam_models.dart
// Nepal Entrance Exam Models — Enhanced for Real Exam Fidelity & Analytics

// ignore_for_file: unused_import

import 'dart:math';

// ─────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────

enum ExamType { ioe, ku, kuPcb, pu, pou, meceeBl }

enum VerificationStatus { verifiedOfficial, provisional }

enum QuestionOrigin {
  parameterizedPractice,
  syllabusKnowledge,
  expertAuthored,
  licensedPastPaper,
}

enum SubjectDomain {
  physics,
  chemistry,
  mathematics,
  biology,
  english,
  mat,
  healthKnowledge
}

// ─────────────────────────────────────────────────────────────
// COURSE PROFILE (Real Nepal Patterns)
// ─────────────────────────────────────────────────────────────

class CourseProfile {
  final ExamType type;
  final String name;
  final String fullName;
  final int durationMinutes;
  final int totalQuestions;
  final int totalMarks;
  final bool hasNegativeMarking;
  final double negativePenalty;
  final Map<SubjectDomain, int> subjectDistribution;
  final List<SubjectDomain> subjectOrder;
  final bool isAdaptive;
  final String description;
  final Map<SubjectDomain, int> marksPerSubject;
  final String blueprintVersion;
  final String? officialSourceUrl;
  final String? verifiedOn;
  final VerificationStatus verificationStatus;

  const CourseProfile({
    required this.type,
    required this.name,
    required this.fullName,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.totalMarks,
    required this.hasNegativeMarking,
    required this.negativePenalty,
    required this.subjectDistribution,
    required this.subjectOrder,
    required this.isAdaptive,
    required this.description,
    required this.marksPerSubject,
    this.blueprintVersion = 'Unversioned practice blueprint',
    this.officialSourceUrl,
    this.verifiedOn,
    this.verificationStatus = VerificationStatus.provisional,
  });

  int getQuestionCount(SubjectDomain s) => subjectDistribution[s] ?? 0;
  int getMarksForSubject(SubjectDomain s) => marksPerSubject[s] ?? 0;
  bool get isOfficiallyVerified =>
      verificationStatus == VerificationStatus.verifiedOfficial &&
      officialSourceUrl != null &&
      verifiedOn != null;
}

// ─────────────────────────────────────────────────────────────
// OFFICIAL NEPAL EXAM PROFILES
// ─────────────────────────────────────────────────────────────

final List<CourseProfile> courseProfiles = [
  // IOE BE — 100 questions, 140 marks, 120 min
  // Pattern: Physics → Chemistry → Mathematics → English
  const CourseProfile(
    type: ExamType.ioe,
    name: "IOE BE",
    fullName: "Institute of Engineering (TU)",
    durationMinutes: 120,
    totalQuestions: 100,
    totalMarks: 140,
    hasNegativeMarking: true,
    negativePenalty: 0.10,
    subjectDistribution: {
      SubjectDomain.physics: 30,
      SubjectDomain.chemistry: 20,
      SubjectDomain.mathematics: 40,
      SubjectDomain.english: 10,
    },
    subjectOrder: [
      SubjectDomain.physics,
      SubjectDomain.chemistry,
      SubjectDomain.mathematics,
      SubjectDomain.english,
    ],
    isAdaptive: false,
    description:
        "100 MCQs (60×1 + 40×2 marks). 10% negative marking. Physics→Chem→Math→English sequence.",
    marksPerSubject: {
      SubjectDomain.physics: 40,
      SubjectDomain.chemistry: 30,
      SubjectDomain.mathematics: 50,
      SubjectDomain.english: 20,
    },
    blueprintVersion:
        'IOE BE practice blueprint — reconcile with updated 2083 syllabus',
    officialSourceUrl: 'https://ioe.tu.edu.np/downloads',
  ),

  // KU KUCAT — 120 questions, 120 min, Adaptive
  // Pattern: Physics → Chemistry → Mathematics
  const CourseProfile(
    type: ExamType.ku,
    name: "KU KUCAT PCM",
    fullName: "Kathmandu University KUCAT-CBT (PCM)",
    durationMinutes: 120,
    totalQuestions: 120,
    totalMarks: 2220,
    hasNegativeMarking: false,
    negativePenalty: 0.0,
    subjectDistribution: {
      SubjectDomain.physics: 40,
      SubjectDomain.chemistry: 40,
      SubjectDomain.mathematics: 40,
    },
    subjectOrder: [
      SubjectDomain.physics,
      SubjectDomain.chemistry,
      SubjectDomain.mathematics,
    ],
    isAdaptive: true,
    description:
        "120 MCQs (40 per subject). Adaptive difficulty Level 1-5. Physics→Chem→Math sequence.",
    marksPerSubject: {
      SubjectDomain.physics: 740,
      SubjectDomain.chemistry: 740,
      SubjectDomain.mathematics: 740,
    },
    blueprintVersion: 'KUCAT-CBT 2026',
    officialSourceUrl:
        'https://apply.ku.edu.np/syllabi/2026/Test_Syllabus_2026.pdf',
    verifiedOn: '2026-08-05',
    verificationStatus: VerificationStatus.verifiedOfficial,
  ),

  const CourseProfile(
    type: ExamType.kuPcb,
    name: "KU KUCAT PCB",
    fullName: "Kathmandu University KUCAT-CBT (PCB)",
    durationMinutes: 120,
    totalQuestions: 120,
    totalMarks: 2220,
    hasNegativeMarking: false,
    negativePenalty: 0.0,
    subjectDistribution: {
      SubjectDomain.physics: 40,
      SubjectDomain.chemistry: 40,
      SubjectDomain.biology: 40,
    },
    subjectOrder: [
      SubjectDomain.physics,
      SubjectDomain.chemistry,
      SubjectDomain.biology,
    ],
    isAdaptive: true,
    description:
        "120 MCQs (40 per subject). Adaptive levels 1–5. Practice questions are transparently generated.",
    marksPerSubject: {
      SubjectDomain.physics: 740,
      SubjectDomain.chemistry: 740,
      SubjectDomain.biology: 740,
    },
    blueprintVersion: 'KUCAT-CBT 2026',
    officialSourceUrl:
        'https://apply.ku.edu.np/syllabi/2026/Test_Syllabus_2026.pdf',
    verifiedOn: '2026-08-05',
    verificationStatus: VerificationStatus.verifiedOfficial,
  ),

  // PU Engineering — 100 questions, 100 marks, 120 min
  const CourseProfile(
    type: ExamType.pu,
    name: "PU Engineering",
    fullName: "Pokhara University Entrance",
    durationMinutes: 120,
    totalQuestions: 100,
    totalMarks: 100,
    hasNegativeMarking: false,
    negativePenalty: 0.0,
    subjectDistribution: {
      SubjectDomain.mathematics: 40,
      SubjectDomain.physics: 25,
      SubjectDomain.chemistry: 15,
      SubjectDomain.english: 20,
    },
    subjectOrder: [
      SubjectDomain.physics,
      SubjectDomain.chemistry,
      SubjectDomain.mathematics,
      SubjectDomain.english,
    ],
    isAdaptive: false,
    description: "100 MCQs, 1 mark each. No negative marking. 2 hours.",
    marksPerSubject: {
      SubjectDomain.mathematics: 40,
      SubjectDomain.physics: 25,
      SubjectDomain.chemistry: 15,
      SubjectDomain.english: 20,
    },
  ),

  // PoU BE/B.Arch — 100 questions, 100 marks, 120 min
  const CourseProfile(
    type: ExamType.pou,
    name: "PoU BE",
    fullName: "Purbanchal University BE/B.Arch",
    durationMinutes: 120,
    totalQuestions: 100,
    totalMarks: 100,
    hasNegativeMarking: false,
    negativePenalty: 0.0,
    subjectDistribution: {
      SubjectDomain.mathematics: 40,
      SubjectDomain.physics: 30,
      SubjectDomain.chemistry: 20,
      SubjectDomain.english: 10,
    },
    subjectOrder: [
      SubjectDomain.physics,
      SubjectDomain.chemistry,
      SubjectDomain.mathematics,
      SubjectDomain.english,
    ],
    isAdaptive: false,
    description: "100 MCQs. Pass mark 33. No negative marking. 2 hours.",
    marksPerSubject: {
      SubjectDomain.mathematics: 40,
      SubjectDomain.physics: 30,
      SubjectDomain.chemistry: 20,
      SubjectDomain.english: 10,
    },
  ),

  // MECEE-BL — 200 questions, 200 marks, 180 min
  // Pattern: Biology → Chemistry → Physics → MAT
  const CourseProfile(
    type: ExamType.meceeBl,
    name: "MECEE-BL",
    fullName: "Medical Common Entrance Exam",
    durationMinutes: 180,
    totalQuestions: 200,
    totalMarks: 200,
    hasNegativeMarking: true,
    negativePenalty: 0.25,
    subjectDistribution: {
      SubjectDomain.biology: 80,
      SubjectDomain.chemistry: 40,
      SubjectDomain.physics: 40,
      SubjectDomain.healthKnowledge: 20,
      SubjectDomain.mat: 20,
    },
    subjectOrder: [
      SubjectDomain.biology,
      SubjectDomain.chemistry,
      SubjectDomain.physics,
      SubjectDomain.healthKnowledge,
      SubjectDomain.mat,
    ],
    isAdaptive: false,
    description:
        "200 MCQs. Biology 80, Chemistry 40, Physics 40, Health Knowledge 20, MAT 20. -0.25 wrong. 3 hours.",
    marksPerSubject: {
      SubjectDomain.biology: 80,
      SubjectDomain.chemistry: 40,
      SubjectDomain.physics: 40,
      SubjectDomain.healthKnowledge: 20,
      SubjectDomain.mat: 20,
    },
    blueprintVersion:
        'MEC Bachelor syllabus revised 2082/05/02 — program mapping review required',
    officialSourceUrl:
        'https://mec.gov.np/uploads/shares/curriculumn/syllabus_bachelor_program_revised_final_2082-05-02.pdf',
  ),
];

// ─────────────────────────────────────────────────────────────
// SYLLABUS NODE (Tree Structure)
// ─────────────────────────────────────────────────────────────

class SyllabusNode {
  final String id;
  final String nameEn;
  final String? nameNe;
  final String subject;
  final String topic;
  final double difficulty; // 0.0 - 1.0
  final List<String> keywords;
  final List<SyllabusNode> children;
  SyllabusNode? parent;

  // Rich content for AI Tutor & Question Engine
  final List<String> formulas;
  final List<String> definitions;
  final List<WorkedExample> examples;

  SyllabusNode({
    required this.id,
    required this.nameEn,
    this.nameNe,
    required this.subject,
    required this.topic,
    this.difficulty = 0.5,
    List<String>? keywords,
    List<SyllabusNode>? children,
    this.parent,
    List<String>? formulas,
    List<String>? definitions,
    List<WorkedExample>? examples,
  })  : keywords = keywords ?? [],
        children = children ?? [],
        formulas = formulas ?? [],
        definitions = definitions ?? [],
        examples = examples ?? [];

  List<SyllabusNode> get flattened {
    final list = <SyllabusNode>[this];
    for (final child in children) {
      list.addAll(child.flattened);
    }
    return list;
  }

  SubjectDomain get subjectDomain {
    switch (subject.toLowerCase()) {
      case 'physics':
        return SubjectDomain.physics;
      case 'chemistry':
        return SubjectDomain.chemistry;
      case 'mathematics':
        return SubjectDomain.mathematics;
      case 'biology':
        return SubjectDomain.biology;
      case 'english':
        return SubjectDomain.english;
      case 'mat':
        return SubjectDomain.mat;
      case 'health knowledge':
        return SubjectDomain.healthKnowledge;
      default:
        return SubjectDomain.mathematics;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// WORKED EXAMPLE (For AI Tutor)
// ─────────────────────────────────────────────────────────────

class WorkedExample {
  final String problem;
  final List<String> steps;
  final String finalAnswer;
  final String explanation;

  const WorkedExample({
    required this.problem,
    required this.steps,
    required this.finalAnswer,
    required this.explanation,
  });
}

// ─────────────────────────────────────────────────────────────
// DYNAMIC QUESTION
// ─────────────────────────────────────────────────────────────

class DynamicQuestion {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final SubjectDomain subject;
  final String topicId;
  final String topicName;
  final double difficulty;
  final int kuLevel;
  final bool requiresCalculator;
  final String? formula;
  final List<String> concepts;
  final int marks;
  final QuestionOrigin origin;
  final String sourceLabel;
  final String? sourceUrl;
  final bool expertReviewed;

  DynamicQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.subject,
    required this.topicId,
    required this.topicName,
    required this.difficulty,
    this.kuLevel = 1,
    this.requiresCalculator = false,
    this.formula,
    this.concepts = const [],
    this.marks = 1,
    this.origin = QuestionOrigin.parameterizedPractice,
    this.sourceLabel = 'ShikshaPul generated practice',
    this.sourceUrl,
    this.expertReviewed = false,
  })  : assert(options.length == 4, 'Every MCQ must have exactly four options'),
        assert(correctIndex >= 0 && correctIndex < options.length),
        assert(
          origin != QuestionOrigin.licensedPastPaper ||
              (expertReviewed && sourceUrl != null),
          'Past-paper questions require expert review and a source URL',
        );

  bool get isPastPaper => origin == QuestionOrigin.licensedPastPaper;

  String get trustLabel => switch (origin) {
        QuestionOrigin.licensedPastPaper => 'LICENSED PAST PAPER',
        QuestionOrigin.expertAuthored => 'EXPERT AUTHORED',
        QuestionOrigin.parameterizedPractice => 'GENERATED PRACTICE',
        QuestionOrigin.syllabusKnowledge => 'SYLLABUS PRACTICE',
      };
}

// ─────────────────────────────────────────────────────────────
// EXAM SESSION
// ─────────────────────────────────────────────────────────────

class ExamSession {
  final int? id;
  final ExamType examType;
  final DateTime startedAt;
  DateTime? endedAt;
  int totalQuestions;
  int correctAnswers;
  int wrongAnswers;
  int skipped;
  double finalScore;
  int? predictedRank;
  final List<ExamResponse> responses;
  final bool isProctored;
  int violationCount;
  bool isTerminated;
  final List<SubjectDomain>? selectedSubjects; // For subject-wise mock

  ExamSession({
    this.id,
    required this.examType,
    required this.startedAt,
    this.endedAt,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.skipped = 0,
    this.finalScore = 0.0,
    this.predictedRank,
    this.responses = const [],
    this.isProctored = false,
    this.violationCount = 0,
    this.isTerminated = false,
    this.selectedSubjects,
  });

  double get accuracy =>
      totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
  double get percentage => totalQuestions == 0
      ? 0
      : (finalScore / getProfile(examType).totalMarks) * 100;

  static CourseProfile getProfile(ExamType type) =>
      courseProfiles.firstWhere((p) => p.type == type);
}

// ─────────────────────────────────────────────────────────────
// EXAM RESPONSE
// ─────────────────────────────────────────────────────────────

class ExamResponse {
  final int? id;
  final int? sessionId;
  final String questionId;
  final String questionText;
  final String? studentAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final bool isSkipped;
  final int timeTakenSeconds;
  final double difficultyAtTime;
  final int kuLevelAtTime;
  final double marksAwarded;
  final double negativeMarks;
  final String topicId;
  final SubjectDomain subject;

  ExamResponse({
    this.id,
    this.sessionId,
    required this.questionId,
    required this.questionText,
    this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.isSkipped = false,
    required this.timeTakenSeconds,
    required this.difficultyAtTime,
    this.kuLevelAtTime = 1,
    required this.marksAwarded,
    this.negativeMarks = 0.0,
    required this.topicId,
    required this.subject,
  });
}

// ─────────────────────────────────────────────────────────────
// WEAKNESS REPORT (Enhanced)
// ─────────────────────────────────────────────────────────────

class WeaknessReport {
  final SubjectDomain subject;
  final String topicId;
  final String topicName;
  final int totalAttempts;
  final int correctCount;
  final double accuracy;
  final double masteryScore;
  final bool isCritical;
  final List<String> recommendedActions;
  final DateTime lastAttempted;
  final double? previousAccuracy; // For trend tracking
  final bool isImproving;

  WeaknessReport({
    required this.subject,
    required this.topicId,
    required this.topicName,
    required this.totalAttempts,
    required this.correctCount,
    required this.accuracy,
    required this.masteryScore,
    this.isCritical = false,
    this.recommendedActions = const [],
    required this.lastAttempted,
    this.previousAccuracy,
    this.isImproving = false,
  });
}

// ─────────────────────────────────────────────────────────────
// MASTERY TREND (For Weakness Screen Graphs)
// ─────────────────────────────────────────────────────────────

class MasteryTrend {
  final String topicId;
  final String topicName;
  final SubjectDomain subject;
  final List<MasteryPoint> history;

  MasteryTrend({
    required this.topicId,
    required this.topicName,
    required this.subject,
    required this.history,
  });

  double get currentMastery => history.isEmpty ? 0.0 : history.last.accuracy;

  double? get improvementRate {
    if (history.length < 2) return null;
    final first = history.first.accuracy;
    final last = history.last.accuracy;
    return last - first;
  }
}

class MasteryPoint {
  final DateTime timestamp;
  final double accuracy;
  final int attempts;
  final String examType;

  MasteryPoint({
    required this.timestamp,
    required this.accuracy,
    required this.attempts,
    required this.examType,
  });
}

// ─────────────────────────────────────────────────────────────
// LLM CONFIG (For Local GGUF Integration)
// ─────────────────────────────────────────────────────────────

class LlmConfig {
  static const String modelAsset = 'assets/models/qwen-0.5b-q3_k_m.gguf';
  static const int contextSize = 2048;
  static const int maxTokens = 512;
  static const double temperature = 0.2;
}

// ─────────────────────────────────────────────────────────────
// EXTENSIONS
// ─────────────────────────────────────────────────────────────

extension ExamTypeName on ExamType {
  List<SubjectDomain> get subjects {
    return ExamSession.getProfile(this).subjectDistribution.keys.toList();
  }
}

extension CourseIndex on CourseProfile {
  int get index => courseProfiles.indexOf(this);
}
