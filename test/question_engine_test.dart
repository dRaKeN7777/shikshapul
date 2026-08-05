import 'package:flutter_test/flutter_test.dart';
import 'package:shikshapul/core/data/question_bank.dart';
import 'package:shikshapul/core/data/official_syllabus.dart';
import 'package:shikshapul/core/data/exam_resources.dart';
import 'package:shikshapul/core/data/syllabus_tree.dart';
import 'package:shikshapul/models/exam_models.dart';

void main() {
  setUpAll(() {
    SyllabusTree.init();
    QuestionEngine.init();
  });

  test('every official course blueprint is internally consistent', () {
    for (final profile in courseProfiles) {
      expect(profile.subjectDistribution.values.reduce((a, b) => a + b),
          profile.totalQuestions,
          reason: '${profile.name} question distribution');
      expect(profile.marksPerSubject.values.reduce((a, b) => a + b),
          profile.totalMarks,
          reason: '${profile.name} marks distribution');
      expect(profile.subjectOrder.toSet(),
          profile.subjectDistribution.keys.toSet());
    }
  });

  test('syllabus topics are assigned to their owning subject', () {
    for (final subject in SubjectDomain.values) {
      final misplaced = SyllabusTree.getAllTopics(subject)
          .where((topic) => topic.subjectDomain != subject)
          .map((topic) => '${topic.id}:${topic.subject}')
          .toList();
      expect(misplaced, isEmpty, reason: '${subject.name}: $misplaced');
    }
  });

  test('full papers match course counts and contain valid MCQs', () {
    for (final profile in courseProfiles) {
      final questions = QuestionEngine.generateExam(
        profile.type,
        difficulty: 'hard',
      );
      expect(questions, hasLength(profile.totalQuestions),
          reason: profile.name);
      final textCounts = <String, int>{};
      for (final question in questions) {
        textCounts.update(question.text, (count) => count + 1,
            ifAbsent: () => 1);
      }
      final duplicates = textCounts.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key)
          .toList();
      expect(questions.map((q) => q.text).toSet(),
          hasLength(profile.totalQuestions),
          reason:
              '${profile.name} should not repeat within one paper: $duplicates');

      for (final subject in profile.subjectOrder) {
        expect(questions.where((q) => q.subject == subject),
            hasLength(profile.getQuestionCount(subject)),
            reason: '${profile.name} ${subject.name} distribution');
      }
      for (final question in questions) {
        expect(question.options, hasLength(4));
        expect(question.options.toSet(), hasLength(4));
        expect(question.correctIndex, inInclusiveRange(0, 3));
        expect(question.explanation.trim(), isNotEmpty);
        expect(question.topicId.trim(), isNotEmpty);
      }
    }
  });

  test('IOE paper applies its exact 140-mark blueprint', () {
    final questions = QuestionEngine.generateExam(
      ExamType.ioe,
      difficulty: 'hard',
    );
    expect(questions.fold<int>(0, (sum, q) => sum + q.marks), 140);
    final profile = ExamSession.getProfile(ExamType.ioe);
    for (final subject in profile.subjectOrder) {
      expect(
        questions
            .where((q) => q.subject == subject)
            .fold<int>(0, (sum, q) => sum + q.marks),
        profile.getMarksForSubject(subject),
      );
    }
  });

  test('current IOE and MECEE subject allocations are represented', () {
    final ioe = ExamSession.getProfile(ExamType.ioe);
    expect(ioe.subjectDistribution, {
      SubjectDomain.physics: 30,
      SubjectDomain.chemistry: 20,
      SubjectDomain.mathematics: 40,
      SubjectDomain.english: 10,
    });
    final mec = ExamSession.getProfile(ExamType.meceeBl);
    expect(mec.getQuestionCount(SubjectDomain.healthKnowledge), 20);
    expect(mec.getQuestionCount(SubjectDomain.chemistry), 40);
    expect(mec.getQuestionCount(SubjectDomain.physics), 40);
  });

  test('KU adaptive levels use the official 11 to 19 mark ladder', () {
    for (var level = 1; level <= 5; level++) {
      final question = QuestionEngine.generateSingle(
        'PHYS_KIN',
        ExamType.ku,
        forceLevel: level,
      );
      expect(question.kuLevel, level);
      expect(question.marks, 11 + (level - 1) * 2);
    }
  });

  test('KU PCB uses the verified 40/40/40 adaptive blueprint', () {
    final profile = ExamSession.getProfile(ExamType.kuPcb);
    expect(profile.isOfficiallyVerified, isTrue);
    expect(profile.totalQuestions, 120);
    expect(profile.subjectDistribution, {
      SubjectDomain.physics: 40,
      SubjectDomain.chemistry: 40,
      SubjectDomain.biology: 40,
    });
    expect(profile.totalMarks, 2220);
  });

  test('official KU subject lists contain exactly forty unique topics', () {
    for (final subject in const [
      SubjectDomain.physics,
      SubjectDomain.chemistry,
      SubjectDomain.mathematics,
      SubjectDomain.biology,
    ]) {
      final topics = OfficialSyllabus.kucat2026[subject]!;
      expect(topics, hasLength(40), reason: subject.name);
      expect(topics.toSet(), hasLength(40), reason: subject.name);
    }
  });

  test('resource library keeps model sets distinct from past papers', () {
    for (final resource in ExamResources.all) {
      expect(resource.url, startsWith('https://'));
      expect(resource.kind.toLowerCase(), isNot(contains('past paper')));
      expect(resource.exams, isNotEmpty);
    }
    for (final exam in ExamType.values) {
      expect(ExamResources.forExam(exam), isNotEmpty, reason: exam.name);
    }
  });

  test('course subject order contains each configured subject exactly once',
      () {
    for (final profile in courseProfiles) {
      expect(
          profile.subjectOrder.toSet(), hasLength(profile.subjectOrder.length),
          reason: profile.name);
      expect(profile.subjectOrder.toSet(),
          equals(profile.subjectDistribution.keys.toSet()),
          reason: profile.name);
    }
  });

  test('mock difficulty and rapid paper size are honored', () {
    final easy = QuestionEngine.generateForTopic('PHYS_KIN', ExamType.ioe, 5,
        difficulty: 'easy');
    final hard = QuestionEngine.generateForTopic('PHYS_KIN', ExamType.ioe, 5,
        difficulty: 'hard');
    expect(easy.every((q) => q.difficulty == 0.3), isTrue);
    expect(hard.every((q) => q.difficulty == 0.9), isTrue);

    final rapid = QuestionEngine.generateExam(
      ExamType.ioe,
      totalQuestionCount: 10,
      difficulty: 'medium',
    );
    expect(rapid, hasLength(10));
    expect(
        rapid.where((q) => q.subject == SubjectDomain.physics), hasLength(3));
    expect(
        rapid.where((q) => q.subject == SubjectDomain.chemistry), hasLength(2));
    expect(rapid.where((q) => q.subject == SubjectDomain.mathematics),
        hasLength(4));
    expect(
        rapid.where((q) => q.subject == SubjectDomain.english), hasLength(1));
  });

  test('a later paper excludes previously seen wording', () {
    final first = QuestionEngine.generateExam(
      ExamType.ioe,
      subjectFilter: const [SubjectDomain.physics],
      totalQuestionCount: 12,
    );
    final seen = first.map((q) => q.text).toSet();
    final second = QuestionEngine.generateExam(
      ExamType.ioe,
      subjectFilter: const [SubjectDomain.physics],
      totalQuestionCount: 12,
      excludedQuestionTexts: seen,
    );
    expect(second.map((q) => q.text).toSet().intersection(seen), isEmpty);
  });

  test('topic-focused mock stays on the requested topic', () {
    final questions = QuestionEngine.generateExam(
      ExamType.ioe,
      subjectFilter: const [SubjectDomain.physics],
      weakTopics: const ['PHYS_KIN'],
      totalQuestionCount: 8,
    );
    expect(questions.every((q) => q.topicId == 'PHYS_KIN'), isTrue);
  });

  test('every question exposes honest provenance', () {
    final questions = QuestionEngine.generateExam(
      ExamType.meceeBl,
      totalQuestionCount: 40,
    );
    for (final question in questions) {
      expect(question.sourceLabel.trim(), isNotEmpty);
      if (question.isPastPaper) {
        expect(question.expertReviewed, isTrue);
        expect(question.sourceUrl, isNotNull);
      } else {
        expect(question.sourceLabel.toLowerCase(), contains('practice'));
      }
    }
  });

  test('fallback questions test knowledge rather than fake exam claims', () {
    final questions = QuestionEngine.generateForTopic(
      'HLTH_EPI',
      ExamType.meceeBl,
      8,
    );
    expect(questions, hasLength(8));
    for (final question in questions) {
      expect(question.origin, QuestionOrigin.syllabusKnowledge);
      expect(question.text, isNot(contains('outside the entrance syllabus')));
      expect(question.text, isNot(contains('can be ignored')));
      expect(question.options, hasLength(4));
    }
  });
}
