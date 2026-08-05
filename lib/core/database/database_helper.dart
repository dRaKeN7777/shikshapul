// lib/core/database/database_helper.dart
// ignore_for_file: unused_import

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/exam_models.dart';
import '../data/syllabus_tree.dart';

/// Comprehensive SQLite persistence for exam history, weakness analytics,
/// mastery trends, and per-exam snapshots.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;
  static const int _dbVersion = 3;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shikshapul_v2.db');

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute("""
      CREATE TABLE exam_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_type TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        total_questions INTEGER DEFAULT 0,
        correct_answers INTEGER DEFAULT 0,
        wrong_answers INTEGER DEFAULT 0,
        skipped INTEGER DEFAULT 0,
        final_score REAL DEFAULT 0,
        percentage REAL DEFAULT 0,
        is_proctored INTEGER DEFAULT 0,
        violation_count INTEGER DEFAULT 0,
        is_terminated INTEGER DEFAULT 0,
        subjects_tested TEXT,
        duration_minutes INTEGER DEFAULT 0
      )
    """);

    await db.execute("""
      CREATE TABLE exam_responses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        question_id TEXT NOT NULL,
        question_text TEXT NOT NULL,
        student_answer TEXT,
        correct_answer TEXT NOT NULL,
        is_correct INTEGER DEFAULT 0,
        is_skipped INTEGER DEFAULT 0,
        time_taken_seconds INTEGER DEFAULT 0,
        difficulty_at_time REAL DEFAULT 0,
        ku_level_at_time INTEGER DEFAULT 1,
        marks_awarded REAL DEFAULT 0,
        negative_marks REAL DEFAULT 0,
        topic_id TEXT NOT NULL,
        subject TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE mastery(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        total_attempts INTEGER DEFAULT 0,
        correct_count INTEGER DEFAULT 0,
        avg_mastery REAL DEFAULT 0,
        streak INTEGER DEFAULT 0,
        best_streak INTEGER DEFAULT 0,
        last_updated TEXT,
        UNIQUE(subject, topic_id)
      )
    """);

    await db.execute("""
      CREATE TABLE mastery_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        topic_name TEXT NOT NULL,
        mastery_value REAL DEFAULT 0,
        exam_count INTEGER DEFAULT 0,
        session_id INTEGER NOT NULL,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE exam_weakness_snapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        topic_name TEXT NOT NULL,
        questions_attempted INTEGER DEFAULT 0,
        questions_correct INTEGER DEFAULT 0,
        mastery_at_exam REAL DEFAULT 0,
        is_weak INTEGER DEFAULT 0,
        recommendation TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE exam_subject_stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        subject TEXT NOT NULL,
        total_questions INTEGER DEFAULT 0,
        correct INTEGER DEFAULT 0,
        wrong INTEGER DEFAULT 0,
        skipped INTEGER DEFAULT 0,
        score REAL DEFAULT 0,
        percentage REAL DEFAULT 0,
        avg_time_seconds INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE
      )
    """);
    await _createIndexes(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("""
        CREATE TABLE IF NOT EXISTS exam_subject_stats(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          subject TEXT NOT NULL,
          total_questions INTEGER DEFAULT 0,
          correct INTEGER DEFAULT 0,
          wrong INTEGER DEFAULT 0,
          skipped INTEGER DEFAULT 0,
          score REAL DEFAULT 0,
          percentage REAL DEFAULT 0,
          avg_time_seconds INTEGER DEFAULT 0,
          FOREIGN KEY (session_id) REFERENCES exam_sessions(id) ON DELETE CASCADE
        )
      """);
    }
    if (oldVersion < 3) await _createIndexes(db);
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_type ON exam_sessions(exam_type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_responses_session ON exam_responses(session_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_responses_topic ON exam_responses(subject, topic_id, is_skipped)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_weakness_session ON exam_weakness_snapshots(session_id)');
  }

  // ================================================================
  //  SESSION OPERATIONS (matches your controller call)
  // ================================================================

  /// Saves full exam session + responses + updates mastery + records history
  /// Signature matches: await DatabaseHelper.instance.saveSession(_session, _questions);
  Future<int> saveSession(
    ExamSession session,
    List<DynamicQuestion> questions,
  ) async {
    final db = await database;
    return db.transaction((txn) async {
      // Derive subjects from session.selectedSubjects or from questions
      final subjectsTested =
          session.selectedSubjects?.map((s) => s.name).toList() ??
              questions.map((q) => q.subject.name).toSet().toList();

      final sessionId = await txn.insert('exam_sessions', {
        'exam_type': session.examType.name,
        'started_at': session.startedAt.toIso8601String(),
        'ended_at': session.endedAt?.toIso8601String(),
        'total_questions': session.totalQuestions,
        'correct_answers': session.correctAnswers,
        'wrong_answers': session.wrongAnswers,
        'skipped': session.skipped,
        'final_score': session.finalScore,
        'percentage': questions.isNotEmpty
            ? (session.finalScore /
                    questions.fold<double>(0, (sum, q) => sum + q.marks)) *
                100
            : 0.0,
        'is_proctored': session.isProctored ? 1 : 0,
        'violation_count': session.violationCount,
        'is_terminated': session.isTerminated ? 1 : 0,
        'subjects_tested': subjectsTested.join(','),
        'duration_minutes': session.endedAt != null
            ? session.endedAt!.difference(session.startedAt).inMinutes
            : 0,
      });

      final topicNameMap = <String, String>{};
      for (final q in questions) {
        topicNameMap[q.topicId] = q.topicName;
      }

      final subjectStats = <String, Map<String, dynamic>>{};
      final questionById = {for (final q in questions) q.id: q};

      for (final resp in session.responses) {
        await txn.insert('exam_responses', {
          'session_id': sessionId,
          'question_id': resp.questionId,
          'question_text': resp.questionText,
          'student_answer': resp.studentAnswer,
          'correct_answer': resp.correctAnswer,
          'is_correct': resp.isCorrect ? 1 : 0,
          'is_skipped': resp.isSkipped ? 1 : 0,
          'time_taken_seconds': resp.timeTakenSeconds,
          'difficulty_at_time': resp.difficultyAtTime,
          'ku_level_at_time': resp.kuLevelAtTime,
          'marks_awarded': resp.marksAwarded,
          'negative_marks': resp.negativeMarks,
          'topic_id': resp.topicId,
          'subject': resp.subject.name,
        });

        subjectStats.putIfAbsent(
          resp.subject.name,
          () => {
            'total': 0,
            'correct': 0,
            'wrong': 0,
            'skipped': 0,
            'timeSum': 0,
            'score': 0.0,
            'maxScore': 0.0,
          },
        );
        subjectStats[resp.subject.name]!['total']++;
        subjectStats[resp.subject.name]!['timeSum'] += resp.timeTakenSeconds;
        subjectStats[resp.subject.name]!['score'] += resp.marksAwarded;
        subjectStats[resp.subject.name]!['maxScore'] +=
            questionById[resp.questionId]?.marks ?? 0;
        if (resp.isCorrect) {
          subjectStats[resp.subject.name]!['correct']++;
        } else if (resp.isSkipped) {
          subjectStats[resp.subject.name]!['skipped']++;
        } else {
          subjectStats[resp.subject.name]!['wrong']++;
        }

        if (!resp.isSkipped) {
          await _updateMastery(
            txn,
            resp.subject.name,
            resp.topicId,
            topicNameMap[resp.topicId] ?? resp.topicId,
            resp.isCorrect,
          );
        }
      }

      for (final entry in subjectStats.entries) {
        final stats = entry.value;
        final total = stats['total'] as int;
        await txn.insert('exam_subject_stats', {
          'session_id': sessionId,
          'subject': entry.key,
          'total_questions': total,
          'correct': stats['correct'],
          'wrong': stats['wrong'],
          'skipped': stats['skipped'],
          'score': stats['score'],
          'percentage': (stats['maxScore'] as double) > 0
              ? ((stats['score'] as double) / (stats['maxScore'] as double)) *
                  100
              : 0.0,
          'avg_time_seconds': total > 0 ? (stats['timeSum'] ~/ total) : 0,
        });
      }

      final currentMastery = await txn.query('mastery');
      for (final row in currentMastery) {
        await txn.insert('mastery_history', {
          'subject': row['subject'],
          'topic_id': row['topic_id'],
          'topic_name': row['topic'],
          'mastery_value': row['avg_mastery'],
          'exam_count': row['total_attempts'],
          'session_id': sessionId,
          'recorded_at': DateTime.now().toIso8601String(),
        });
      }

      await _createWeaknessSnapshot(txn, sessionId, session, topicNameMap);
      return sessionId;
    });
  }

  Future<void> _updateMastery(
    DatabaseExecutor db,
    String subject,
    String topicId,
    String topicName,
    bool isCorrect,
  ) async {
    final existing = await db.query(
      'mastery',
      where: 'subject = ? AND topic_id = ?',
      whereArgs: [subject, topicId],
    );

    if (existing.isEmpty) {
      await db.insert('mastery', {
        'subject': subject,
        'topic': topicName,
        'topic_id': topicId,
        'total_attempts': 1,
        'correct_count': isCorrect ? 1 : 0,
        'avg_mastery': isCorrect ? 1.0 : 0.0,
        'streak': isCorrect ? 1 : 0,
        'best_streak': isCorrect ? 1 : 0,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } else {
      final row = existing.first;
      final attempts = (row['total_attempts'] as int) + 1;
      final correct = (row['correct_count'] as int) + (isCorrect ? 1 : 0);
      final mastery = correct / attempts;
      final currentStreak = (row['streak'] as int);
      final newStreak = isCorrect ? currentStreak + 1 : 0;
      final bestStreak = (row['best_streak'] as int);

      await db.update(
        'mastery',
        {
          'total_attempts': attempts,
          'correct_count': correct,
          'avg_mastery': mastery,
          'streak': newStreak,
          'best_streak': newStreak > bestStreak ? newStreak : bestStreak,
          'last_updated': DateTime.now().toIso8601String(),
        },
        where: 'subject = ? AND topic_id = ?',
        whereArgs: [subject, topicId],
      );
    }
  }

  Future<void> _createWeaknessSnapshot(
    DatabaseExecutor db,
    int sessionId,
    ExamSession session,
    Map<String, String> topicNameMap,
  ) async {
    final topicPerformance = <String, Map<String, dynamic>>{};

    for (final resp in session.responses) {
      if (resp.isSkipped) continue;
      final key = '${resp.subject.name}|${resp.topicId}';
      topicPerformance.putIfAbsent(
        key,
        () => {
          'subject': resp.subject.name,
          'topicId': resp.topicId,
          'attempted': 0,
          'correct': 0
        },
      );
      topicPerformance[key]!['attempted']++;
      if (resp.isCorrect) topicPerformance[key]!['correct']++;
    }

    for (final entry in topicPerformance.entries) {
      final data = entry.value;
      final attempted = data['attempted'] as int;
      final correct = data['correct'] as int;
      final mastery = attempted > 0 ? correct / attempted : 0.0;
      final isWeak = mastery < 0.6;

      String recommendation;
      if (mastery < 0.4) {
        recommendation =
            'Critical weakness. Study fundamentals with AI Tutor, then practice 10+ questions.';
      } else if (mastery < 0.6) {
        recommendation =
            'Weak area. Review concepts and practice similar problems.';
      } else if (mastery < 0.8) {
        recommendation = 'Moderate. Keep practicing to build consistency.';
      } else {
        recommendation = 'Strong. Maintain with occasional revision.';
      }

      await db.insert('exam_weakness_snapshots', {
        'session_id': sessionId,
        'subject': data['subject'],
        'topic_id': data['topicId'],
        'topic_name': topicNameMap[data['topicId']] ?? data['topicId'],
        'questions_attempted': attempted,
        'questions_correct': correct,
        'mastery_at_exam': mastery,
        'is_weak': isWeak ? 1 : 0,
        'recommendation': recommendation,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ================================================================
  //  QUERY METHODS
  // ================================================================

  Future<List<Map<String, dynamic>>> getMasterySummary() async {
    final db = await database;
    return db.query('mastery', orderBy: 'avg_mastery ASC, total_attempts DESC');
  }

  Future<List<Map<String, dynamic>>> getSubjectWiseSummary() async {
    final db = await database;
    return db.rawQuery("""
      SELECT 
        subject,
        COUNT(*) as topic_count,
        AVG(avg_mastery) as overall_mastery,
        SUM(CASE WHEN avg_mastery < 0.6 THEN 1 ELSE 0 END) as weak_count,
        SUM(total_attempts) as total_attempts,
        SUM(correct_count) as total_correct
      FROM mastery
      GROUP BY subject
      ORDER BY overall_mastery ASC
    """);
  }

  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    final db = await database;
    return db.query('exam_sessions', orderBy: 'started_at DESC');
  }

  Future<Map<String, dynamic>?> getSessionDetail(int sessionId) async {
    final db = await database;
    final sessions = await db
        .query('exam_sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (sessions.isEmpty) return null;

    final session = Map<String, dynamic>.from(sessions.first);
    session['subject_stats'] = await db.query(
      'exam_subject_stats',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    session['weakness_snapshot'] = await db.query(
      'exam_weakness_snapshots',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'mastery_at_exam ASC',
    );
    return session;
  }

  Future<List<Map<String, dynamic>>> getExamWeaknessSnapshot(
      int sessionId) async {
    final db = await database;
    return db.query(
      'exam_weakness_snapshots',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'mastery_at_exam ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllExamsWithWeakness() async {
    final db = await database;
    final exams = await db.query('exam_sessions', orderBy: 'started_at DESC');
    final result = <Map<String, dynamic>>[];

    for (final exam in exams) {
      final id = exam['id'] as int;
      final snapshot = await db.query(
        'exam_weakness_snapshots',
        where: 'session_id = ? AND is_weak = 1',
        whereArgs: [id],
        orderBy: 'mastery_at_exam ASC',
      );
      final examMap = Map<String, dynamic>.from(exam);
      examMap['weak_topics'] = snapshot;
      examMap['weak_count'] = snapshot.length;
      result.add(examMap);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getTopicMasteryHistory(
      String topicId) async {
    final db = await database;
    return db.query(
      'mastery_history',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'recorded_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentlyImprovedTopics() async {
    final db = await database;
    return db.rawQuery("""
      SELECT 
        h1.topic_id,
        h1.topic_name,
        h1.subject,
        h1.mastery_value as latest_mastery,
        h2.mastery_value as previous_mastery,
        (h1.mastery_value - h2.mastery_value) as improvement
      FROM mastery_history h1
      JOIN (
        SELECT topic_id, MAX(recorded_at) as max_date
        FROM mastery_history
        GROUP BY topic_id
      ) latest ON h1.topic_id = latest.topic_id AND h1.recorded_at = latest.max_date
      LEFT JOIN mastery_history h2 ON h1.topic_id = h2.topic_id
      WHERE h2.recorded_at < latest.max_date
      GROUP BY h1.topic_id
      HAVING improvement > 0.1
      ORDER BY improvement DESC
      LIMIT 20
    """);
  }

  Future<List<Map<String, dynamic>>> getPersistentWeakness() async {
    final db = await database;
    return db.rawQuery("""
      SELECT 
        subject,
        topic_id,
        topic,
        avg_mastery,
        total_attempts,
        streak,
        CASE 
          WHEN avg_mastery < 0.4 THEN 'Critical'
          WHEN avg_mastery < 0.6 THEN 'Weak'
          WHEN avg_mastery < 0.8 THEN 'Moderate'
          ELSE 'Strong'
        END as status
      FROM mastery
      WHERE avg_mastery < 0.6
      ORDER BY avg_mastery ASC, total_attempts DESC
    """);
  }

  Future<List<Map<String, dynamic>>> getWeakTopicsBySubject(
      String subject) async {
    final db = await database;
    return db.query(
      'mastery',
      where: 'subject = ? AND avg_mastery < 0.6',
      whereArgs: [subject],
      orderBy: 'avg_mastery ASC',
    );
  }

  Future<void> resetAllData() async {
    final db = await database;
    await db.delete('exam_sessions');
    await db.delete('exam_responses');
    await db.delete('mastery');
    await db.delete('mastery_history');
    await db.delete('exam_weakness_snapshots');
    await db.delete('exam_subject_stats');
  }

  // ================================================================
  //  EXAM-TYPE FILTERED QUERIES (for course-specific weakness)
  // ================================================================

  Future<List<Map<String, dynamic>>> getSessionHistoryByType(
      String examType) async {
    final db = await database;
    return db.query(
      'exam_sessions',
      where: 'exam_type = ?',
      whereArgs: [examType],
      orderBy: 'started_at DESC',
    );
  }

  /// Question wording from the five most recent papers for this course. A
  /// bounded window avoids immediate repetition without permanently exhausting
  /// parameterized topic pools after long-term use.
  Future<Set<String>> getUsedQuestionTexts(String examType) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT er.question_text
      FROM exam_responses er
      INNER JOIN exam_sessions es ON es.id = er.session_id
      WHERE es.id IN (
        SELECT id
        FROM exam_sessions
        WHERE exam_type = ?
        ORDER BY started_at DESC
        LIMIT 5
      )
    ''', [examType]);
    return rows
        .map((row) => row['question_text'] as String?)
        .whereType<String>()
        .toSet();
  }

  Future<List<Map<String, dynamic>>> getRecentMistakesByType(
      String examType) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        er.question_text,
        er.student_answer,
        er.correct_answer,
        er.topic_id,
        er.subject,
        er.time_taken_seconds,
        MAX(es.started_at) AS attempted_at
      FROM exam_responses er
      INNER JOIN exam_sessions es ON es.id = er.session_id
      WHERE es.exam_type = ?
        AND er.is_correct = 0
        AND er.is_skipped = 0
      GROUP BY er.question_text, er.student_answer, er.correct_answer,
               er.topic_id, er.subject, er.time_taken_seconds
      ORDER BY attempted_at DESC
      LIMIT 100
    ''', [examType]);
  }

  Future<List<Map<String, dynamic>>> getAllExamsWithWeaknessByType(
      String examType) async {
    final db = await database;
    final exams = await db.query(
      'exam_sessions',
      where: 'exam_type = ?',
      whereArgs: [examType],
      orderBy: 'started_at DESC',
    );
    final result = <Map<String, dynamic>>[];

    for (final exam in exams) {
      final id = exam['id'] as int;
      final snapshot = await db.query(
        'exam_weakness_snapshots',
        where: 'session_id = ? AND is_weak = 1',
        whereArgs: [id],
        orderBy: 'mastery_at_exam ASC',
      );
      final examMap = Map<String, dynamic>.from(exam);
      examMap['weak_topics'] = snapshot;
      examMap['weak_count'] = snapshot.length;
      result.add(examMap);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getSubjectWiseSummaryByType(
      String examType) async {
    final db = await database;
    return db.rawQuery("""
      SELECT
        subject,
        COUNT(*) as topic_count,
        AVG(avg_mastery) as overall_mastery,
        SUM(CASE WHEN avg_mastery < 0.6 THEN 1 ELSE 0 END) as weak_count,
        SUM(total_attempts) as total_attempts,
        SUM(correct_count) as total_correct
      FROM (
        SELECT er.subject, er.topic_id,
          COUNT(*) as total_attempts,
          SUM(er.is_correct) as correct_count,
          1.0 * SUM(er.is_correct) / COUNT(*) as avg_mastery
        FROM exam_responses er
        INNER JOIN exam_sessions es ON es.id = er.session_id
        WHERE es.exam_type = ? AND er.is_skipped = 0
        GROUP BY er.subject, er.topic_id
      ) course_mastery
      GROUP BY subject
      ORDER BY overall_mastery ASC
    """, [examType]);
  }

  Future<List<Map<String, dynamic>>> getMasterySummaryByType(
      String examType) async {
    final db = await database;
    return db.rawQuery('''
      SELECT er.subject, er.topic_id,
        COALESCE(
          (SELECT ws.topic_name FROM exam_weakness_snapshots ws
           WHERE ws.topic_id = er.topic_id AND ws.session_id = er.session_id
           LIMIT 1), er.topic_id
        ) as topic,
        COUNT(*) as total_attempts,
        SUM(er.is_correct) as correct_count,
        1.0 * SUM(er.is_correct) / COUNT(*) as avg_mastery,
        0 as streak,
        ? as exam_type
      FROM exam_responses er
      INNER JOIN exam_sessions es ON es.id = er.session_id
      WHERE es.exam_type = ? AND er.is_skipped = 0
      GROUP BY er.subject, er.topic_id
      ORDER BY avg_mastery ASC, total_attempts DESC
    ''', [examType, examType]);
  }

  Future<List<Map<String, dynamic>>> getPersistentWeaknessByType(
      String examType) async {
    final rows = await getMasterySummaryByType(examType);
    return rows
        .where((row) =>
            (row['total_attempts'] as num) >= 2 &&
            (row['avg_mastery'] as num) < 0.6)
        .map((row) {
      final mastery = (row['avg_mastery'] as num).toDouble();
      return {
        ...row,
        'status': mastery < 0.4 ? 'Critical' : 'Weak',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getWeakTopicsBySubjectAndType(
      String subject, String examType) async {
    final rows = await getMasterySummaryByType(examType);
    return rows
        .where((row) =>
            row['subject'] == subject && (row['avg_mastery'] as num) < 0.6)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTopicMasteryHistoryByType(
      String topicId, String examType) async {
    final db = await database;
    return db.rawQuery('''
      SELECT es.id as session_id, es.started_at as recorded_at,
        es.exam_type,
        1.0 * SUM(er.is_correct) / COUNT(*) as mastery_value,
        COUNT(*) as exam_count
      FROM exam_responses er
      INNER JOIN exam_sessions es ON es.id = er.session_id
      WHERE er.topic_id = ? AND es.exam_type = ? AND er.is_skipped = 0
      GROUP BY es.id, es.started_at, es.exam_type
      ORDER BY es.started_at ASC
    ''', [topicId, examType]);
  }

  Future<List<Map<String, dynamic>>> getRecentlyImprovedTopicsByType(
      String examType) async {
    final mastery = await getMasterySummaryByType(examType);
    final improved = <Map<String, dynamic>>[];
    for (final topic in mastery) {
      final history = await getTopicMasteryHistoryByType(
        topic['topic_id'] as String,
        examType,
      );
      if (history.length < 2) continue;
      final latest = (history.last['mastery_value'] as num).toDouble();
      final previous =
          (history[history.length - 2]['mastery_value'] as num).toDouble();
      if (latest - previous <= 0.1) continue;
      improved.add({
        'topic_id': topic['topic_id'],
        'topic_name': topic['topic'],
        'subject': topic['subject'],
        'latest_mastery': latest,
        'previous_mastery': previous,
        'improvement': latest - previous,
        'exam_type': examType,
      });
    }
    improved.sort(
        (a, b) => (b['improvement'] as num).compareTo(a['improvement'] as num));
    return improved.take(20).toList();
  }
}
