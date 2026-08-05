// lib/core/data/question_bank.dart
// INFINITE DYNAMIC QUESTION ENGINE — SCHOLARSHIP EDITION
// Generates algorithmic questions from syllabus formulas with smart distractors

// ignore_for_file: prefer_const_declarations, unused_local_variable

import 'dart:math';
import '../../models/exam_models.dart';
import 'syllabus_tree.dart';

/// Central engine for infinite question generation.
class QuestionEngine {
  static final QuestionEngine _instance = QuestionEngine._internal();
  factory QuestionEngine() => _instance;
  QuestionEngine._internal();

  static final Random _rng = Random();
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    _registerGenerators();
  }

  // ─────────────────────────────────────────
  // GENERATOR REGISTRY
  // ─────────────────────────────────────────
  static final Map<String, QuestionGenerator> _generators = {};

  static void _register(String topicId, QuestionGenerator gen) {
    _generators[topicId] = gen;
  }

  static void _registerGenerators() {
    // PHYSICS — 20 topics
    _register('PHYS_KIN', _genKinematics);
    _register('PHYS_NLM', _genNLM);
    _register('PHYS_WEP', _genWorkEnergy);
    _register('PHYS_EST', _genElectrostatics);
    _register('PHYS_DCC', _genDCCircuits);
    _register('PHYS_SEM', _genSemiconductors);
    _register('PHYS_CIR', _genCircular);
    _register('PHYS_GRA', _genGravitation);
    _register('PHYS_ELA', _genElasticity);
    _register('PHYS_FLU', _genFluid);
    _register('PHYS_TEM', _genHeat);
    _register('PHYS_KTG', _genKTG);
    _register('PHYS_LAW', _genThermo);
    _register('PHYS_REF', _genReflection);
    _register('PHYS_RFR', _genRefraction);
    _register('PHYS_INT', _genInterference);
    _register('PHYS_PHO', _genPhotoelectric);
    _register('PHYS_BOH', _genBohr);
    _register('PHYS_NUC', _genNuclear);
    _register('PHYS_EMI', _genEMI);
    _register('PHYS_AC', _genAC);
    _register('PHYS_MAG', _genMagnetic);

    // CHEMISTRY — 12 topics
    _register('CHEM_STO', _genStoichiometry);
    _register('CHEM_BON', _genBonding);
    _register('CHEM_ELE', _genElectrochemistry);
    _register('CHEM_EQU', _genEquilibrium);
    _register('CHEM_PER', _genPeriodic);
    _register('CHEM_PBL', _genPBlock);
    _register('CHEM_DBL', _genDBlock);
    _register('CHEM_MET', _genMetallurgy);
    _register('CHEM_IUP', _genIUPAC);
    _register('CHEM_HYD', _genHydrocarbons);
    _register('CHEM_ALD', _genAldehydes);
    _register('CHEM_THE', _genChemThermo);

    // MATHEMATICS — 14 topics
    _register('MATH_MAT', _genMatrices);
    _register('MATH_COM', _genPermutation);
    _register('MATH_SEQ', _genSequence);
    _register('MATH_TEQ', _genTrigEq);
    _register('MATH_LIN', _genStraightLine);
    _register('MATH_CIR', _genCircle);
    _register('MATH_CON', _genConic);
    _register('MATH_LIM', _genLimits);
    _register('MATH_DER', _genDifferentiation);
    _register('MATH_INT', _genIntegration);
    _register('MATH_DEQ', _genDiffEq);
    _register('MATH_VOP', _genVectors);
    _register('MATH_PROB', _genProbability);
    _register('MATH_SET', _genSets);

    // BIOLOGY — 10 topics (Zoology + Botany + Cell/Genetics/Eco)
    _register('BIO_ZOO', _genZoology);
    _register('BIO_BOT', _genBotany);
    _register('BIO_HUM', _genHumanPhysiology);
    _register('BIO_GEN', _genGenetics);
    _register('BIO_CEL', _genCellBiology);
    _register('BIO_EVO', _genEvolution);
    _register('BIO_ECO', _genEcology);
    _register('BIO_PHY', _genPlantPhysiology);
    _register('BIO_BIO', _genBiodiversity);
    _register('BIO_BTE', _genBiotechnology);

    // ENGLISH — 3 topics
    _register('ENG_GR1', _genEnglishGrammar);
    _register('ENG_VOC', _genVocabulary);
    _register('ENG_PHO', _genPhonetics);

    // MAT — 3 topics
    _register('MAT_VER', _genVerbalReasoning);
    _register('MAT_NUM', _genNumericalReasoning);
    _register('MAT_LOG', _genLogicalReasoning);
  }

  // ─────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────

  /// Generate a full practice paper. [difficulty] = easy | medium | hard.
  static List<DynamicQuestion> generateExam(
    ExamType type, {
    List<SubjectDomain>? subjectFilter,
    List<String>? weakTopics,
    int? totalQuestionCount,
    String difficulty = 'medium',
    Set<String> excludedQuestionTexts = const {},
  }) {
    init();
    final profile = ExamSession.getProfile(type);
    final questions = <DynamicQuestion>[];
    final usedIds = <String>{};

    final subjects = subjectFilter ?? profile.subjectOrder;
    final effectiveDifficulty =
        const {'easy', 'medium', 'hard'}.contains(difficulty)
            ? difficulty
            : 'medium';
    final unavailableTexts = <String>{...excludedQuestionTexts};
    final selectedTopics = (weakTopics ?? const <String>[])
        .map(SyllabusTree.findTopicById)
        .whereType<SyllabusNode>()
        .toList();

    final totalProfileQuestions = subjects.fold<int>(
      0,
      (sum, subject) => sum + profile.getQuestionCount(subject),
    );
    var allocated = 0;
    var cumulativeProfileQuestions = 0;

    for (var subjectIndex = 0; subjectIndex < subjects.length; subjectIndex++) {
      final subject = subjects[subjectIndex];
      cumulativeProfileQuestions += profile.getQuestionCount(subject);
      final count = totalQuestionCount == null
          ? profile.getQuestionCount(subject)
          : (totalQuestionCount *
                      cumulativeProfileQuestions /
                      totalProfileQuestions)
                  .round() -
              allocated;
      allocated += count;
      if (count <= 0) continue;
      final focused = selectedTopics
          .where((topic) => topic.subjectDomain == subject)
          .toList();
      final topics =
          focused.isNotEmpty ? focused : SyllabusTree.getAllTopics(subject);
      if (topics.isEmpty) continue;

      for (int i = 0; i < count; i++) {
        DynamicQuestion? question;
        final maximumAttempts = max(100, topics.length * 12);
        for (var paperAttempt = 0;
            paperAttempt < maximumAttempts;
            paperAttempt++) {
          final topic = _weightedTopicSelection(topics);
          try {
            final candidate = _generateUnseenQuestion(
              topic,
              type,
              usedIds,
              unavailableTexts,
              difficulty: effectiveDifficulty,
            );
            if (!unavailableTexts.contains(candidate.text)) {
              question = candidate;
              break;
            }
          } on StateError {
            // This topic's finite conceptual variants are exhausted. Select a
            // different syllabus topic rather than aborting the whole paper.
          }
        }
        if (question == null) {
          throw StateError(
            'Unique ${subject.name} question pool exhausted after '
            '$maximumAttempts attempts.',
          );
        }
        questions.add(question);
        unavailableTexts.add(question.text);
      }
    }
    return _applyOfficialMarking(type, questions);
  }

  static DynamicQuestion _generateUnseenQuestion(
    SyllabusNode topic,
    ExamType type,
    Set<String> usedIds,
    Set<String> unavailableTexts, {
    required String difficulty,
  }) {
    DynamicQuestion candidate =
        _generateForTopic(topic, type, usedIds, difficulty: difficulty);
    for (var attempt = 0;
        attempt < 8 && unavailableTexts.contains(candidate.text);
        attempt++) {
      candidate =
          _generateForTopic(topic, type, usedIds, difficulty: difficulty);
    }
    for (var attempt = 0;
        attempt < 100 && unavailableTexts.contains(candidate.text);
        attempt++) {
      candidate =
          _genericGenerator(topic, type, usedIds, difficulty: difficulty);
    }
    if (unavailableTexts.contains(candidate.text)) {
      throw StateError(
          'Unique question pool exhausted for ${topic.nameEn}. Choose more topics.');
    }
    return candidate;
  }

  static List<DynamicQuestion> _applyOfficialMarking(
      ExamType type, List<DynamicQuestion> questions) {
    if (type != ExamType.ioe ||
        questions.length != ExamSession.getProfile(type).totalQuestions) {
      return questions;
    }
    final profile = ExamSession.getProfile(type);
    final seenBySubject = <SubjectDomain, int>{};
    return questions.map((question) {
      final index = seenBySubject.update(
        question.subject,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final questionCount = profile.getQuestionCount(question.subject);
      final twoMarkCount =
          profile.getMarksForSubject(question.subject) - questionCount;
      final marks = index > questionCount - twoMarkCount ? 2 : 1;
      return DynamicQuestion(
        id: question.id,
        text: question.text,
        options: question.options,
        correctIndex: question.correctIndex,
        explanation: question.explanation,
        subject: question.subject,
        topicId: question.topicId,
        topicName: question.topicName,
        difficulty: question.difficulty,
        kuLevel: question.kuLevel,
        requiresCalculator: question.requiresCalculator,
        formula: question.formula,
        concepts: question.concepts,
        marks: marks,
        origin: question.origin,
        sourceLabel: question.sourceLabel,
        sourceUrl: question.sourceUrl,
        expertReviewed: question.expertReviewed,
      );
    }).toList();
  }

  static List<DynamicQuestion> generateForTopic(
      String topicId, ExamType type, int count,
      {String difficulty = 'medium'}) {
    init();
    final topic = SyllabusTree.findTopicById(topicId);
    if (topic == null) return [];
    final usedIds = <String>{};
    return List.generate(count,
        (_) => _generateForTopic(topic, type, usedIds, difficulty: difficulty));
  }

  static DynamicQuestion generateSingle(String topicId, ExamType type,
      {String difficulty = 'medium', int? forceLevel}) {
    init();
    final topic = SyllabusTree.findTopicById(topicId);
    if (topic == null) throw Exception('Topic not found: $topicId');
    return _generateForTopic(topic, type, <String>{},
        difficulty: difficulty, forceLevel: forceLevel);
  }

  // ─────────────────────────────────────────
  // INTERNAL GENERATION
  // ─────────────────────────────────────────

  static DynamicQuestion _generateForTopic(
    SyllabusNode topic,
    ExamType type,
    Set<String> usedIds, {
    int? forceLevel,
    String difficulty = 'medium',
  }) {
    final gen = _generators[topic.id];
    final question = gen != null
        ? gen(topic, type, usedIds,
            forceLevel: forceLevel, difficulty: difficulty)
        : _genericGenerator(topic, type, usedIds, difficulty: difficulty);
    final value = switch (difficulty) {
      'easy' => 0.3,
      'hard' => 0.9,
      _ => 0.6,
    };
    if (question.difficulty == value) return question;
    return DynamicQuestion(
      id: question.id,
      text: question.text,
      options: question.options,
      correctIndex: question.correctIndex,
      explanation: question.explanation,
      subject: question.subject,
      topicId: question.topicId,
      topicName: question.topicName,
      difficulty: value,
      kuLevel: question.kuLevel,
      requiresCalculator: question.requiresCalculator,
      formula: question.formula,
      concepts: question.concepts,
      marks: question.marks,
      origin: question.origin,
      sourceLabel: question.sourceLabel,
      sourceUrl: question.sourceUrl,
      expertReviewed: question.expertReviewed,
    );
  }

  static SyllabusNode _weightedTopicSelection(List<SyllabusNode> topics) {
    final withGen = topics.where((t) => _generators.containsKey(t.id)).toList();
    if (withGen.isNotEmpty && _rng.nextDouble() < 0.85) {
      return withGen[_rng.nextInt(withGen.length)];
    }
    return topics[_rng.nextInt(topics.length)];
  }

  static String _uniqueId(String prefix, Set<String> used) {
    String id;
    int safety = 0;
    do {
      id = '${prefix}_${_rng.nextInt(999999)}';
      safety++;
    } while (used.contains(id) && safety < 100);
    used.add(id);
    return id;
  }

  static int _kuLevel(SyllabusNode topic, ExamType type) {
    if (type != ExamType.ku && type != ExamType.kuPcb) return 1;
    return (topic.difficulty * 5).ceil().clamp(1, 5);
  }

  // ─────────────────────────────────────────
  //  DIFFICULTY MULTIPLIERS
  // ─────────────────────────────────────────
  static double _diffFactor(String d) {
    switch (d) {
      case 'easy':
        return 0.6;
      case 'hard':
        return 1.6;
      default:
        return 1.0;
    }
  }

  // ═════════════════════════════════════════════════════════════════
  //  PHYSICS — HARD MULTI-STEP PROBLEMS
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _genKinematics(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final u = (_rng.nextInt(15) + 5) * df; // 5-20 m/s scaled
    final a = ((_rng.nextInt(8) + 2) * 0.5) * df;
    final time = ((_rng.nextInt(8) + 3) * 1.0);
    final s = u * time + 0.5 * a * time * time;
    final v = u + a * time;
    final towerHeight = (5 * time * time - u * time).abs();

    final variants = [
      _Variant(
          'A particle starts at ${u.toStringAsFixed(1)} m/s with constant acceleration ${a.toStringAsFixed(1)} m/s². '
              'Find its displacement in ${time.toStringAsFixed(0)} s.',
          s,
          's = ut + ½at² = ${u.toStringAsFixed(1)}×${time.toStringAsFixed(0)} + ½×${a.toStringAsFixed(1)}×${time.toStringAsFixed(0)}² = ${s.toStringAsFixed(2)} m\n'
              'Check: v = u + at = ${v.toStringAsFixed(2)} m/s.'),
      _Variant(
          'A body projected upward at ${u.toStringAsFixed(1)} m/s from a tower. After ${time.toStringAsFixed(0)} s it strikes ground with g=10 m/s². '
              'Find tower height.',
          towerHeight,
          'Taking upward as positive: -h = ut - ½gt², so h = 5t² - ut = ${towerHeight.toStringAsFixed(2)} m.'),
    ];
    final vrt = variants[_rng.nextInt(variants.length)];
    return _buildMCQ(t, type, used, vrt.q, vrt.ans, vrt.exp,
        forceLevel: forceLevel, unit: 'm');
  }

  static DynamicQuestion _genNLM(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final m1 = ((_rng.nextInt(8) + 2) * 1.0);
    final m2 = ((_rng.nextInt(8) + 2) * 1.0);
    final f = ((_rng.nextInt(30) + 10) * 1.0) * df;
    final a = f / (m1 + m2);
    final contactForce = m2 * a;

    final q =
        'Two blocks of mass ${m1.toStringAsFixed(0)} kg and ${m2.toStringAsFixed(0)} kg in contact on frictionless surface. '
        'A force $f N pushes the ${m1.toStringAsFixed(0)} kg block. Find contact force between them.';
    final exp =
        'a = F/(m₁+m₂) = $f/(${m1.toStringAsFixed(0)}+${m2.toStringAsFixed(0)}) = ${a.toStringAsFixed(3)} m/s²\n'
        'Contact force on m₂ = m₂×a = ${m2.toStringAsFixed(0)}×${a.toStringAsFixed(3)} = ${contactForce.toStringAsFixed(2)} N';
    return _buildMCQ(t, type, used, q, contactForce, exp,
        forceLevel: forceLevel, unit: 'N');
  }

  static DynamicQuestion _genWorkEnergy(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final m = ((_rng.nextInt(10) + 2) * 1.0);
    final h = ((_rng.nextInt(20) + 5) * 1.0) * df;
    final k = ((_rng.nextInt(19) + 1) * 100.0);
    final x = sqrt(2 * m * 9.8 * h / k);
    final q =
        'A ${m.toStringAsFixed(0)} kg block slides frictionlessly through a vertical height ${h.toStringAsFixed(1)} m, then compresses a horizontal spring (k=${k.toStringAsFixed(0)} N/m). '
        'Find maximum compression (g=9.8 m/s²).';
    final exp =
        'Energy conservation gives mgh = ½kx². Thus x = √(2mgh/k) = ${x.toStringAsFixed(3)} m.';
    return _buildMCQ(t, type, used, q, x * 100, exp,
        forceLevel: forceLevel, unit: 'cm');
  }

  static DynamicQuestion _genElectrostatics(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final q1 = ((_rng.nextInt(5) + 1) * 1.0);
    final q2 = ((_rng.nextInt(5) + 1) * 1.0);
    final r = ((_rng.nextInt(9) + 1) * 1.0) * df;
    final f = (9.0e9 * q1 * q2 * 1e-12) / (r * r);
    final q =
        'Two charges ${q1.toStringAsFixed(0)} μC and ${q2.toStringAsFixed(0)} μC are placed ${r.toStringAsFixed(1)} m apart in vacuum. '
        'Calculate electrostatic force (k=9×10⁹).';
    final exp =
        'F = kq₁q₂/r² = 9×10⁹ × ${q1.toStringAsFixed(0)}×10⁻⁶ × ${q2.toStringAsFixed(0)}×10⁻⁶ / (${r.toStringAsFixed(1)})² = ${f.toStringAsFixed(3)} N';
    return _buildMCQ(t, type, used, q, f, exp,
        forceLevel: forceLevel, unit: 'N');
  }

  static DynamicQuestion _genDCCircuits(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final r1 = ((_rng.nextInt(10) + 1) * 2.0);
    final r2 = ((_rng.nextInt(10) + 1) * 3.0);
    final r3 = ((_rng.nextInt(10) + 1) * 4.0) * df;
    final rp = (r1 * r2) / (r1 + r2);
    final req = rp + r3;
    final q =
        'Resistors ${r1.toStringAsFixed(0)}Ω and ${r2.toStringAsFixed(0)}Ω in parallel, then in series with ${r3.toStringAsFixed(0)}Ω. '
        'Find equivalent resistance.';
    final exp =
        'R_parallel = (${r1.toStringAsFixed(0)}×${r2.toStringAsFixed(0)})/(${r1.toStringAsFixed(0)}+${r2.toStringAsFixed(0)}) = ${rp.toStringAsFixed(2)}Ω\n'
        'R_eq = R_p + ${r3.toStringAsFixed(0)} = ${req.toStringAsFixed(2)}Ω';
    return _buildMCQ(t, type, used, q, req, exp,
        forceLevel: forceLevel, unit: 'Ω');
  }

  static DynamicQuestion _genSemiconductors(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final beta = ((_rng.nextInt(20) + 5) * 10);
    final ib = ((_rng.nextInt(9) + 1) * 10.0);
    final ic = beta * ib;
    final ie = ic + ib;
    final q =
        'In a transistor, β = $beta and base current I_B = ${ib.toStringAsFixed(0)} μA. '
        'Find emitter current I_E.';
    final exp =
        'I_C = β×I_B = $beta × ${ib.toStringAsFixed(0)} = ${ic.toStringAsFixed(0)} μA\n'
        'I_E = I_C + I_B = ${ie.toStringAsFixed(0)} μA = ${(ie / 1000).toStringAsFixed(3)} mA';
    return _buildMCQ(t, type, used, q, ie / 1000, exp,
        forceLevel: forceLevel, unit: 'mA');
  }

  static DynamicQuestion _genCircular(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final v = ((_rng.nextInt(15) + 5) * 1.0) * df;
    final r = ((_rng.nextInt(10) + 5) * 1.0);
    final m = ((_rng.nextInt(5) + 1) * 1.0);
    final ac = (v * v) / r;
    final f = m * ac;
    final q =
        'A ${m.toStringAsFixed(0)} kg particle moves at ${v.toStringAsFixed(1)} m/s in a horizontal circle of radius ${r.toStringAsFixed(1)} m. '
        'Find centripetal force.';
    final exp =
        'a_c = v²/r = ${v.toStringAsFixed(1)}²/${r.toStringAsFixed(1)} = ${ac.toStringAsFixed(2)} m/s²\n'
        'F = ma = ${m.toStringAsFixed(0)} × ${ac.toStringAsFixed(2)} = ${f.toStringAsFixed(2)} N';
    return _buildMCQ(t, type, used, q, f, exp,
        forceLevel: forceLevel, unit: 'N');
  }

  static DynamicQuestion _genGravitation(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final h = ((_rng.nextInt(30) + 10) * 10.0) * df;
    final v = sqrt(2 * 9.8 * h);
    final fallTime = sqrt(2 * h / 9.8);
    final q = 'A body is dropped from a height of ${h.toStringAsFixed(0)} m. '
        'Find its speed just before striking the ground (g=9.8 m/s²).';
    final exp =
        'v = √(2gh) = √(2×9.8×${h.toStringAsFixed(0)}) = ${v.toStringAsFixed(1)} m/s. '
        'Check: t = √(2h/g) = ${fallTime.toStringAsFixed(2)} s.';
    return _buildMCQ(t, type, used, q, v, exp,
        forceLevel: forceLevel, unit: 'm/s');
  }

  static DynamicQuestion _genElasticity(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final l0 = ((_rng.nextInt(10) + 5) * 1.0);
    final dl = ((_rng.nextInt(5) + 1) * 0.1) * df;
    final y = ((_rng.nextInt(5) + 1) * 1e11);
    final strain = dl / l0;
    final stress = y * strain;
    final q =
        'A wire of length ${l0.toStringAsFixed(1)} m is stretched by ${dl.toStringAsFixed(2)} m. '
        'If Young\'s modulus is ${(y / 1e11).toStringAsFixed(0)}×10¹¹ Pa, find stress produced.';
    final exp =
        'Strain = ΔL/L = ${dl.toStringAsFixed(2)}/${l0.toStringAsFixed(1)} = ${strain.toStringAsFixed(4)}\n'
        'Stress = Y×strain = ${(y / 1e11).toStringAsFixed(0)}×10¹¹ × ${strain.toStringAsFixed(4)} = ${stress.toStringAsFixed(2)} N/m²';
    return _buildMCQ(t, type, used, q, stress, exp,
        forceLevel: forceLevel, unit: 'N/m²');
  }

  static DynamicQuestion _genFluid(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final v1 = ((_rng.nextInt(5) + 1) * 1.0) * df;
    final a1 = ((_rng.nextInt(5) + 1) * 1.0);
    final a2 = a1 / ((_rng.nextInt(3) + 2) * 1.0);
    final v2 = (a1 * v1) / a2;
    final q =
        'Fluid flows at ${v1.toStringAsFixed(1)} m/s through a pipe of area ${a1.toStringAsFixed(1)} m². '
        'If area reduces to ${a2.toStringAsFixed(2)} m², find new velocity.';
    final exp =
        'A₁v₁ = A₂v₂ → v₂ = ${a1.toStringAsFixed(1)}×${v1.toStringAsFixed(1)}/${a2.toStringAsFixed(2)} = ${v2.toStringAsFixed(2)} m/s';
    return _buildMCQ(t, type, used, q, v2, exp,
        forceLevel: forceLevel, unit: 'm/s');
  }

  static DynamicQuestion _genHeat(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final m = ((_rng.nextInt(10) + 1) * 100.0) * df;
    final c = 4200.0;
    final dt = ((_rng.nextInt(30) + 10) * 1.0);
    final q =
        '${m.toStringAsFixed(0)} g of water is heated from 20°C to ${(20 + dt).toStringAsFixed(0)}°C. '
        'Calculate heat required (c=4200 J/kg°C).';
    final exp =
        'Q = mcΔT = ${(m / 1000).toStringAsFixed(2)}×4200×${dt.toStringAsFixed(0)} = ${((m / 1000) * c * dt).toStringAsFixed(0)} J';
    return _buildMCQ(t, type, used, q, (m / 1000) * c * dt, exp,
        forceLevel: forceLevel, unit: 'J');
  }

  static DynamicQuestion _genKTG(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final tVal = ((_rng.nextInt(5) + 1) * 100.0) * df;
    final mMolar = 0.028; // N2
    final vRms = sqrt(3 * 8.314 * tVal / mMolar);
    final q =
        'Calculate RMS velocity of N₂ molecules at ${tVal.toStringAsFixed(0)} K (R=8.314, M=0.028 kg/mol).';
    final exp =
        'v_rms = √(3RT/M) = √(3×8.314×${tVal.toStringAsFixed(0)}/0.028) = ${vRms.toStringAsFixed(0)} m/s';
    return _buildMCQ(t, type, used, q, vRms, exp,
        forceLevel: forceLevel, unit: 'm/s');
  }

  static DynamicQuestion _genThermo(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final t1 = ((_rng.nextInt(3) + 3) * 100.0) * df;
    final t2 = t1 / ((_rng.nextInt(3) + 2) * 1.0);
    final eta = 1 - (t2 / t1);
    final q =
        'A Carnot engine operates between ${t1.toStringAsFixed(0)} K and ${t2.toStringAsFixed(0)} K. '
        'Find its efficiency.';
    final exp =
        'η = 1 - T₂/T₁ = 1 - ${t2.toStringAsFixed(0)}/${t1.toStringAsFixed(0)} = ${(eta * 100).toStringAsFixed(2)}%';
    return _buildMCQ(t, type, used, q, eta * 100, exp,
        forceLevel: forceLevel, unit: '%');
  }

  static DynamicQuestion _genReflection(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final u = ((_rng.nextInt(20) + 10) * 5.0) * df;
    final f = u / 2;
    final q =
        'An object is placed at ${u.toStringAsFixed(0)} cm from a concave mirror of focal length ${f.toStringAsFixed(0)} cm. '
        'Find image distance.';
    final exp =
        '1/f = 1/u + 1/v → 1/v = 1/${f.toStringAsFixed(0)} - 1/${u.toStringAsFixed(0)} → v = ${u.toStringAsFixed(0)} cm (since u=2f, image is same size at same distance)';
    return _buildMCQ(t, type, used, q, u, exp,
        forceLevel: forceLevel, unit: 'cm');
  }

  static DynamicQuestion _genRefraction(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final n = 1.25 + _rng.nextInt(4) * 0.25;
    final critical = asin(1 / n) * 180 / pi;
    final q =
        'Refractive index of a medium is ${n.toStringAsFixed(2)}. Calculate critical angle.';
    final exp =
        'sin C = 1/n = 1/${n.toStringAsFixed(2)} → C = arcsin(${(1 / n).toStringAsFixed(3)}) = ${critical.toStringAsFixed(1)}°';
    return _buildMCQ(t, type, used, q, critical, exp,
        forceLevel: forceLevel, unit: '°');
  }

  static DynamicQuestion _genInterference(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final d = ((_rng.nextInt(5) + 1) * 0.1) / df;
    final D = ((_rng.nextInt(5) + 1) * 1.0);
    final lam = 500 + _rng.nextInt(200);
    final beta = (lam * 1e-9 * D) / (d * 1e-3);
    final q =
        'In Young\'s double slit, d=${d.toStringAsFixed(2)} mm, D=${D.toStringAsFixed(0)} m, λ=${lam.toStringAsFixed(0)} nm. '
        'Find fringe width.';
    final exp =
        'β = λD/d = (${lam.toStringAsFixed(0)}×10⁻⁹×${D.toStringAsFixed(0)})/(${d.toStringAsFixed(3)}×10⁻³) = ${(beta * 1000).toStringAsFixed(3)} mm';
    return _buildMCQ(t, type, used, q, beta * 1000, exp,
        forceLevel: forceLevel, unit: 'mm');
  }

  static DynamicQuestion _genPhotoelectric(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final phi = ((_rng.nextInt(3) + 1) * 1.0) * df;
    final nu = ((_rng.nextInt(5) + 3) * 1e14);
    final h = 6.626e-34;
    final ke = max(0.0, (h * nu) - (phi * 1.6e-19));
    final keEv = ke / 1.6e-19;
    final q =
        'Work function of a metal is ${phi.toStringAsFixed(2)} eV. Light of frequency ${(nu / 1e14).toStringAsFixed(2)}×10¹⁴ Hz is incident. Find maximum KE of photoelectrons (h = 6.626×10⁻³⁴ J·s, 1 eV = 1.6×10⁻¹⁹ J).';
    final exp =
        'E_photon = hν = 6.626×10⁻³⁴ × ${nu.toStringAsExponential(2)} = ${(h * nu).toStringAsExponential(2)} J\n'
        'φ = ${phi.toStringAsFixed(2)} × 1.6×10⁻¹⁹ = ${(phi * 1.6e-19).toStringAsExponential(2)} J\n'
        '${ke == 0 ? 'hν ≤ φ, so no photoelectrons are emitted and KE_max = 0 eV.' : 'KE_max = hν − φ = ${ke.toStringAsExponential(2)} J = ${keEv.toStringAsFixed(3)} eV'}';
    return _buildMCQ(t, type, used, q, keEv, exp,
        forceLevel: forceLevel, unit: 'eV');
  }

  static DynamicQuestion _genBohr(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final n1 = _rng.nextInt(2) + 1;
    final n2 = n1 + _rng.nextInt(3) + 1;
    final e1 = -13.6 / (n1 * n1);
    final e2 = -13.6 / (n2 * n2);
    final deltaE = (e2 - e1).abs();
    final q =
        'An electron in hydrogen is initially at n=$n1. Find the energy required to excite it to n=$n2.';
    final exp = 'E_$n2 = -13.6/$n2² = ${e2.toStringAsFixed(3)} eV\n'
        'ΔE = ${deltaE.toStringAsFixed(3)} eV = ${(deltaE * 1.6e-19).toStringAsExponential(2)} J\n'
        'λ = hc/ΔE = ${((6.626e-34 * 3e8) / (deltaE * 1.6e-19) * 1e10).toStringAsFixed(1)} Å';
    return _buildMCQ(t, type, used, q, deltaE, exp,
        forceLevel: forceLevel, unit: 'eV');
  }

  static DynamicQuestion _genNuclear(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final tHalf = ((_rng.nextInt(10) + 1) * 100.0) * df;
    final n0 = 100.0;
    final time = tHalf * (_rng.nextInt(3) + 1);
    final n = n0 * pow(0.5, time / tHalf);
    final q =
        'A radioactive sample has half-life ${tHalf.toStringAsFixed(0)} years. '
        'If initial amount is ${n0.toStringAsFixed(0)} g, how much remains after ${time.toStringAsFixed(0)} years?';
    final exp =
        'N = N₀(½)^(t/T½) = $n0 × (½)^(${time.toStringAsFixed(0)}/${tHalf.toStringAsFixed(0)}) = ${n.toStringAsFixed(3)} g';
    return _buildMCQ(t, type, used, q, n, exp,
        forceLevel: forceLevel, unit: 'g');
  }

  static DynamicQuestion _genEMI(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final n = ((_rng.nextInt(20) + 5) * 10.0);
    final dPhi = ((_rng.nextInt(10) + 1) * 1e-3) * df;
    final dt = ((_rng.nextInt(5) + 1) * 1e-3);
    final eps = n * dPhi / dt;
    final q =
        'A coil of $n turns experiences a flux change of ${(dPhi * 1000).toStringAsFixed(1)} mWb in ${(dt * 1000).toStringAsFixed(0)} ms. '
        'Calculate average induced EMF.';
    final exp =
        'ε = -N ΔΦ/Δt = ${n.toStringAsFixed(0)} × ${(dPhi * 1000).toStringAsFixed(1)}×10⁻³ / ${(dt * 1000).toStringAsFixed(0)}×10⁻³ = ${eps.toStringAsFixed(2)} V';
    return _buildMCQ(t, type, used, q, eps, exp,
        forceLevel: forceLevel, unit: 'V');
  }

  static DynamicQuestion _genAC(SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final v0 = ((_rng.nextInt(20) + 5) * 1.0) * df;
    final vrms = v0 / sqrt(2);
    final q =
        'In an AC circuit, peak voltage is ${v0.toStringAsFixed(1)} V. Find the RMS voltage.';
    final exp =
        'V_rms = V₀/√2 = ${v0.toStringAsFixed(1)}/1.414 = ${vrms.toStringAsFixed(2)} V\n'
        'V_avg (full cycle) = 0';
    return _buildMCQ(t, type, used, q, vrms, exp,
        forceLevel: forceLevel, unit: 'V');
  }

  static DynamicQuestion _genMagnetic(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final n = ((_rng.nextInt(10) + 1) * 10.0);
    final i = ((_rng.nextInt(10) + 1) * 1.0) * df;
    final a = ((_rng.nextInt(10) + 1) * 1e-4);
    final b = ((_rng.nextInt(10) + 1) * 0.1);
    final theta = _rng.nextInt(60) + 30; // 30-90 degrees
    final tau = n * i * a * b * cos(theta * pi / 180);
    final q =
        'A rectangular coil ($n turns, area ${(a * 1e4).toStringAsFixed(1)}×10⁻⁴ m²) carries ${i.toStringAsFixed(1)} A in magnetic field ${b.toStringAsFixed(2)} T. '
        'If plane makes ${theta.toStringAsFixed(0)}° with B, find torque.';
    final exp =
        'The normal makes (90°−θ) with B, so τ = NIAB cosθ = ${tau.toStringAsFixed(4)} Nm.';
    return _buildMCQ(t, type, used, q, tau, exp,
        forceLevel: forceLevel, unit: 'Nm');
  }

  // ═════════════════════════════════════════════════════════════════
  //  CHEMISTRY — HARD NUMERICAL & CONCEPTUAL TRAPS
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _genStoichiometry(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final m1 = ((_rng.nextInt(10) + 1) * 10.0);
    final m2 = ((_rng.nextInt(10) + 1) * 5.0) * df;
    final eq1 = m1 / 40; // NaOH approx
    final eq2 = m2 / 36.5; // HCl approx
    final limiting = eq1 < eq2 ? 'NaOH' : 'HCl';
    final q =
        '${m1.toStringAsFixed(0)} g NaOH (M=40) reacts with ${m2.toStringAsFixed(0)} g HCl (M=36.5). '
        'Identify limiting reagent and mass of NaCl formed (M=58.5).';
    final moles = eq1 < eq2 ? eq1 : eq2;
    final massNaCl = moles * 58.5;
    final exp =
        'Moles NaOH = ${m1.toStringAsFixed(0)}/40 = ${eq1.toStringAsFixed(3)}\n'
        'Moles HCl = ${m2.toStringAsFixed(0)}/36.5 = ${eq2.toStringAsFixed(3)}\n'
        '$limiting is limiting. Moles NaCl = $moles → Mass = ${massNaCl.toStringAsFixed(1)} g';
    return _buildMCQ(t, type, used, q, massNaCl, exp,
        forceLevel: forceLevel, unit: 'g');
  }

  static DynamicQuestion _genBonding(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final hybrids = ['sp', 'sp²', 'sp³', 'sp³d', 'sp³d²'];
    final angles = ['180°', '120°', '109.5°', '90° & 120°', '90°'];
    final shapes = [
      'Linear',
      'Trigonal planar',
      'Tetrahedral',
      'Trigonal bipyramidal',
      'Octahedral'
    ];
    final idx = _rng.nextInt(5);
    final q =
        'Which geometry and bond angle correspond to ${hybrids[idx]} hybridization?';
    final exp = '${hybrids[idx]} → ${shapes[idx]} → ${angles[idx]}';
    return _buildMCQ(t, type, used, q, angles[idx], exp,
        forceLevel: forceLevel, isTextAnswer: true, textOptions: angles);
  }

  static DynamicQuestion _genElectrochemistry(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final eCath = ((_rng.nextInt(10) + 5) * 0.1 + 0.2) * df;
    final eAnod = eCath - ((_rng.nextInt(5) + 2) * 0.2);
    final n = _rng.nextInt(2) + 1;
    final eCell = eCath - eAnod;
    final q =
        'For a cell: E°_cathode = ${eCath.toStringAsFixed(2)} V, E°_anode = ${eAnod.toStringAsFixed(2)} V, n=$n. '
        'Calculate E°_cell.';
    final dg = -n * 96500 * eCell;
    final exp =
        'E°_cell = ${eCath.toStringAsFixed(2)} − (${eAnod.toStringAsFixed(2)}) = ${eCell.toStringAsFixed(2)} V\n'
        'ΔG° = -nFE° = -$n × 96500 × ${eCell.toStringAsFixed(2)} = ${dg.toStringAsFixed(0)} J/mol';
    return _buildMCQ(t, type, used, q, eCell, exp,
        forceLevel: forceLevel, unit: 'V');
  }

  static DynamicQuestion _genEquilibrium(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final ka = pow(10.0, -(_rng.nextInt(5) + 3) * df); // 10^-3 to 10^-7
    final c = pow(10.0, -(_rng.nextInt(3) + 1)); // 0.1 to 0.001 M
    final alpha = sqrt(ka / c);
    final h = c * alpha;
    final ph = -log(h) / log(10);
    final q =
        'Weak acid HA has Ka = ${ka.toStringAsExponential(1)} and concentration ${c.toStringAsExponential(0)} M. '
        'Using the weak-acid approximation, calculate its pH.';
    final exp =
        'α = √(Ka/C) = √(${ka.toStringAsExponential(1)}/${c.toStringAsExponential(0)}) = ${alpha.toStringAsFixed(4)}\n'
        '[H⁺] = Cα = ${h.toStringAsExponential(2)} → pH = ${ph.toStringAsFixed(2)}';
    return _buildMCQ(t, type, used, q, ph, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genPeriodic(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'Which of the following has the highest first ionization energy?';
    final exp =
        'Ionization energy generally increases across a period. N has a stable half-filled 2p³ configuration, so IE(N) > IE(O). For these options: F > N > O > Cl > C.';
    return _buildMCQ(t, type, used, q, 'F', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['O', 'F', 'Cl', 'N', 'C']);
  }

  static DynamicQuestion _genPBlock(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'Ammonia reacts with excess Cl₂ to give:';
    final exp =
        'With excess chlorine, NH₃ is chlorinated to NCl₃: NH₃ + 3Cl₂ → NCl₃ + 3HCl. Excess NH₃ instead gives N₂ and NH₄Cl.';
    return _buildMCQ(t, type, used, q, 'NCl₃ + HCl', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['NH₄Cl + HCl', 'N₂ + HCl', 'NCl₃ + HCl', 'NO₂ + H₂O']);
  }

  static DynamicQuestion _genDBlock(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'In [Cr(NH₃)₆]Cl₃, the oxidation state of Cr and primary valency are respectively:';
    final exp =
        '3Cl⁻ outside → primary valency = 3. NH₃ is neutral, so Cr must be +3 to balance. Answer: +3 and 3.';
    return _buildMCQ(t, type, used, q, '+3 and 3', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['+3 and 3', '+6 and 6', '+2 and 2', '+3 and 6']);
  }

  static DynamicQuestion _genMetallurgy(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'During extraction of iron in blast furnace, the reducing agent in the upper region is:';
    final exp =
        'Upper region (200-700°C): CO reduces Fe₂O₃ → Fe₃O₄ → FeO. Lower region (1200°C): C reduces FeO directly.';
    return _buildMCQ(t, type, used, q, 'CO', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['CO', 'C', 'CO₂', 'CaO']);
  }

  static DynamicQuestion _genIUPAC(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'IUPAC name of CH₃-CH(OH)-CH₂-CH₂-CHO is:';
    final exp =
        '5C chain = pentanal. OH at C4 → 4-hydroxypentanal. Aldehyde gets priority over alcohol.';
    return _buildMCQ(t, type, used, q, '4-hydroxypentanal', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          '4-hydroxypentanal',
          '1-oxo-4-pentanol',
          '4-hydroxypentan-1-one',
          'pentan-4-ol-1-al'
        ]);
  }

  static DynamicQuestion _genHydrocarbons(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'Toluene + Cl₂ (hv) → major product?';
    final exp =
        'Free radical substitution at benzylic position (most stable radical). Product: Benzyl chloride (C₆H₅CH₂Cl).';
    return _buildMCQ(t, type, used, q, 'C₆H₅CH₂Cl', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'o-chlorotoluene',
          'C₆H₅CH₂Cl',
          'p-chlorotoluene',
          'C₆H₅CCl₃'
        ]);
  }

  static DynamicQuestion _genAldehydes(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'Crossed Cannizzaro reaction between HCHO and PhCHO with conc. NaOH gives:';
    final exp =
        'HCHO (no α-H) is stronger reducing agent than PhCHO. HCHO oxidized to HCOONa, PhCHO reduced to PhCH₂OH.';
    return _buildMCQ(t, type, used, q, 'PhCH₂OH + HCOONa', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'PhCOONa + CH₃OH',
          'PhCH₂OH + HCOONa',
          'PhCH₂OH + CH₃OH',
          'No reaction'
        ]);
  }

  static DynamicQuestion _genChemThermo(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'For a reaction at 298 K, ΔH = -50 kJ/mol and ΔS = -100 J/K·mol. '
        'At what temperature does it become spontaneous?';
    final exp =
        'ΔG = ΔH - TΔS < 0 for spontaneity. T < ΔH/ΔS = 50000/100 = 500 K. Below 500 K, reaction is spontaneous.';
    return _buildMCQ(t, type, used, q, 'T < 500 K', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'T > 500 K',
          'T < 500 K',
          'Always spontaneous',
          'Never spontaneous'
        ]);
  }

  // ═════════════════════════════════════════════════════════════════
  //  MATHEMATICS — TRICKY, MULTI-STEP, SCHOLARSHIP LEVEL
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _genMatrices(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final n = _rng.nextInt(3) + 2;
    final k = _rng.nextInt(5) + 2;
    final det = ((_rng.nextInt(9) + 1) * 1.0) * df;
    final result = pow(k, n) * det;
    final q =
        'If A is a $n×$n matrix with |A| = ${det.toStringAsFixed(0)}, find |${k}A|.';
    final exp =
        '|kA| = kⁿ|A| = $k^$n × ${det.toStringAsFixed(0)} = ${result.toStringAsFixed(0)}';
    return _buildMCQ(t, type, used, q, result.toDouble(), exp,
        forceLevel: forceLevel);
  }

  static DynamicQuestion _genPermutation(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final n = _rng.nextInt(4) + 4;
    final r = _rng.nextInt(n - 1) + 1;
    final p = _factorial(n) / _factorial(n - r);
    final q =
        'Number of ways to arrange $n students in a row taking $r at a time is:';
    final exp = 'ⁿPᵣ = n!/(n-r)! = $n!/${n - r}! = ${p.toStringAsFixed(0)}';
    return _buildMCQ(t, type, used, q, p, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genSequence(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final a = (_rng.nextInt(10) + 1) * df;
    final d = (_rng.nextInt(5) + 1);
    final n = _rng.nextInt(10) + 10;
    final sum = (n / 2) * (2 * a + (n - 1) * d);
    final q =
        'In an AP, first term = ${a.toStringAsFixed(1)}, common difference = $d. '
        'Find sum of first $n terms.';
    final exp =
        'S_n = n/2 [2a + (n-1)d] = $n/2 [${(2 * a).toStringAsFixed(1)} + ${n - 1}×$d] = ${sum.toStringAsFixed(1)}';
    return _buildMCQ(t, type, used, q, sum, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genTrigEq(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'General solution of tan 3x = 1 is:';
    final exp =
        'tan θ = 1 → θ = nπ + π/4. So 3x = nπ + π/4 → x = nπ/3 + π/12, n ∈ ℤ';
    return _buildMCQ(t, type, used, q, 'x = nπ/3 + π/12', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'x = nπ/3 + π/12',
          'x = nπ + π/4',
          'x = nπ/3 + π/4',
          'x = (2n+1)π/12'
        ]);
  }

  static DynamicQuestion _genStraightLine(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final a1 = (_rng.nextInt(5) + 1) * 1.0;
    final b1 = (_rng.nextInt(5) + 1) * 1.0;
    final c1 = (_rng.nextInt(10) + 1) * 1.0;
    final a2 = a1 * df;
    final b2 = b1 * df;
    final c2 = c1 + (_rng.nextInt(5) + 1);
    final d = ((c2 / df - c1).abs()) / sqrt(a1 * a1 + b1 * b1);
    final q =
        'Distance between parallel lines ${a1.toStringAsFixed(0)}x + ${b1.toStringAsFixed(0)}y + $c1 = 0 and '
        '${a2.toStringAsFixed(0)}x + ${b2.toStringAsFixed(0)}y + $c2 = 0 is:';
    final exp =
        'Normalize the second equation first. Then d = |c₂/$df-c₁|/√(a²+b²) = ${d.toStringAsFixed(3)}.';
    return _buildMCQ(t, type, used, q, d, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genCircle(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final r = ((_rng.nextInt(10) + 1) * 1.0) * df;
    final q =
        'Equation of circle with centre (0,0) and radius ${r.toStringAsFixed(1)} is:';
    final exp =
        '(x-0)² + (y-0)² = ${r.toStringAsFixed(1)}² → x² + y² = ${(r * r).toStringAsFixed(2)}';
    return _buildMCQ(
        t, type, used, q, 'x²+y²=${(r * r).toStringAsFixed(2)}', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'x²+y²=${r.toStringAsFixed(1)}',
          'x²+y²=${(r * r).toStringAsFixed(2)}',
          'x²+y²=${(2 * r).toStringAsFixed(1)}',
          '(x-${r.toStringAsFixed(1)})²+(y-${r.toStringAsFixed(1)})²=${(r * r).toStringAsFixed(2)}'
        ]);
  }

  static DynamicQuestion _genConic(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final a = ((_rng.nextInt(5) + 1) * 1.0) * df;
    final b = ((_rng.nextInt(5) + 1) * 1.0);
    final e = sqrt(1 + (b * b) / (a * a));
    final q =
        'For hyperbola x²/${(a * a).toStringAsFixed(0)} - y²/${(b * b).toStringAsFixed(0)} = 1, find eccentricity.';
    final exp =
        'e = √(1 + b²/a²) = √(1 + ${(b * b).toStringAsFixed(0)}/${(a * a).toStringAsFixed(0)}) = ${e.toStringAsFixed(3)}';
    return _buildMCQ(t, type, used, q, e, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genLimits(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final a = (_rng.nextInt(5) + 1) * df;
    final q = 'lim(x→0) [sin($a x)] / x = ?';
    final exp = 'lim(x→0) sin(ax)/x = a × lim(x→0) sin(ax)/(ax) = $a × 1 = $a';
    return _buildMCQ(t, type, used, q, a.toDouble(), exp,
        forceLevel: forceLevel);
  }

  static DynamicQuestion _genDifferentiation(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final n = _rng.nextInt(4) + 2;
    final m = (_rng.nextInt(3) + 1) * df;
    final q2 = 'If y = x^$n · e^${m.toStringAsFixed(1)}x, find dy/dx.';
    final exp =
        'Using product rule: dy/dx = ${n}x^${n - 1}·e^${m.toStringAsFixed(1)}x + ${m.toStringAsFixed(1)}x^$n·e^${m.toStringAsFixed(1)}x\n'
        '= x^${n - 1}·e^${m.toStringAsFixed(1)}x ($n + ${m.toStringAsFixed(1)}x)';
    return _buildMCQ(
        t,
        type,
        used,
        q2,
        '${n}x^${n - 1}e^${m.toStringAsFixed(1)}x + ${m.toStringAsFixed(1)}x^$n e^${m.toStringAsFixed(1)}x',
        exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          '${n}x^${n - 1}e^${m.toStringAsFixed(1)}x + ${m.toStringAsFixed(1)}x^$n e^${m.toStringAsFixed(1)}x',
          '${n}x^${n + 1}e^${m.toStringAsFixed(1)}x',
          'x^$n e^${m.toStringAsFixed(1)}x',
          '${n}x^${n - 1} + ${m.toStringAsFixed(1)}e^${m.toStringAsFixed(1)}x'
        ]);
  }

  static DynamicQuestion _genIntegration(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final a = (_rng.nextInt(4) + 2) * df;
    final q = '∫ $a x · ln(x) dx = ?';
    final exp =
        'By parts: u=ln(x), dv=$a x dx → du=dx/x, v=${a ~/ 2 == a / 2 ? (a / 2).toStringAsFixed(0) : (a / 2).toStringAsFixed(1)}x²\n'
        'I = ${(a / 2).toStringAsFixed(1)}x² ln(x) - ∫ ${(a / 2).toStringAsFixed(1)}x dx = ${(a / 2).toStringAsFixed(1)}x² ln(x) - ${(a / 4).toStringAsFixed(2)}x² + C';
    return _buildMCQ(
        t,
        type,
        used,
        q,
        '${(a / 2).toStringAsFixed(1)}x² ln(x) - ${(a / 4).toStringAsFixed(2)}x² + C',
        exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          '${(a / 2).toStringAsFixed(1)}x² ln(x) - ${(a / 4).toStringAsFixed(2)}x² + C',
          '${(a / 2).toStringAsFixed(1)}x² ln(x) + C',
          '$a x² ln(x) + C',
          '${a.toStringAsFixed(0)}x ln(x) + C'
        ]);
  }

  static DynamicQuestion _genDiffEq(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'Degree of differential equation (d²y/dx²)³ + (dy/dx)² + sin(dy/dx) = 0 is:';
    final exp =
        'Degree is defined only when equation is polynomial in derivatives. sin(dy/dx) makes it non-polynomial. Hence degree is NOT defined.';
    return _buildMCQ(t, type, used, q, 'Not defined', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['2', '3', '1', 'Not defined']);
  }

  static DynamicQuestion _genVectors(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final a = ((_rng.nextInt(5) + 1) * 1.0) * df;
    final b = ((_rng.nextInt(5) + 1) * 1.0);
    final c = ((_rng.nextInt(5) + 1) * 1.0);
    final cross = a * b; // simplified |a×b| for perpendicular vectors
    final q = 'If |a| = $a, |b| = $b and a·b = 0, find |a × b|.';
    final exp =
        'Since a·b = 0, θ = 90°. |a × b| = |a||b|sin90° = $a × $b = $cross';
    return _buildMCQ(t, type, used, q, cross, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genProbability(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final df = _diffFactor(difficulty);
    final n = _rng.nextInt(4) + 3;
    final p = 1 / n;
    final q =
        'A fair die is rolled. What is probability of getting a factor of $n?';
    final factors = <int>[];
    for (int i = 1; i <= 6; i++) {
      if (n % i == 0) factors.add(i);
    }
    final prob = factors.length / 6;
    final exp =
        'Factors of $n in die: ${factors.join(', ')}. P = ${factors.length}/6 = ${prob.toStringAsFixed(3)}';
    return _buildMCQ(t, type, used, q, prob, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genSets(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final nA = _rng.nextInt(30) + 20;
    final nB = _rng.nextInt(30) + 20;
    final minUnion = max(nA, nB);
    final nAuB = minUnion + _rng.nextInt(nA + nB - minUnion + 1);
    final nAnB = nA + nB - nAuB;
    final q =
        'In a class of $nAuB students, $nA study Physics, $nB study Chemistry. '
        'How many study both?';
    final exp = 'n(A∩B) = n(A) + n(B) - n(A∪B) = $nA + $nB - $nAuB = $nAnB';
    return _buildMCQ(t, type, used, q, nAnB.toDouble(), exp,
        forceLevel: forceLevel);
  }

  // ═════════════════════════════════════════════════════════════════
  //  BIOLOGY — ZOOLOGY, BOTANY, HUMAN PHYSIOLOGY, BIOTECH
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _genZoology(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'In which phylum is the notochord present only in the larval tail?';
    final exp =
        'Urochordata (Tunicata): notochord is present only in larval tail, absent in adult.';
    return _buildMCQ(t, type, used, q, 'Urochordata', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'Cephalochordata',
          'Urochordata',
          'Vertebrata',
          'Hemichordata'
        ]);
  }

  static DynamicQuestion _genBotany(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'In angiosperms, functional megaspore develops into:';
    final exp =
        'Functional megaspore (1 of 4) undergoes 3 mitotic divisions to form embryo sac (female gametophyte).';
    return _buildMCQ(t, type, used, q, 'Embryo sac', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['Ovule', 'Embryo sac', 'Endosperm', 'Zygote']);
  }

  static DynamicQuestion _genHumanPhysiology(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'Which nephron segment continues dilution of tubular fluid by reabsorbing NaCl while remaining relatively impermeable to water in its early portion?';
    final exp =
        'The early distal convoluted tubule reabsorbs NaCl and has low water permeability, so it is part of the cortical diluting segment.';
    return _buildMCQ(t, type, used, q, 'Distal convoluted tubule', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'Proximal convoluted tubule',
          'Loop of Henle',
          'Distal convoluted tubule',
          'Collecting duct'
        ]);
  }

  static DynamicQuestion _genGenetics(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'In the cross AaBb × AaBb, 240 offspring are produced. How many are expected to be double recessive?';
    final exp = 'Dihybrid ratio 9:3:3:1. Double recessive = 1/16. 240/16 = 15.';
    return _buildMCQ(t, type, used, q, 15, exp, forceLevel: forceLevel);
  }

  static DynamicQuestion _genCellBiology(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'During which stage of prophase-I does crossing over occur?';
    final exp =
        'Pachytene: homologous chromosomes are closely paired (synapsis complete) and crossing over occurs via recombination nodules.';
    return _buildMCQ(t, type, used, q, 'Pachytene', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['Leptotene', 'Zygotene', 'Pachytene', 'Diplotene']);
  }

  static DynamicQuestion _genEvolution(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'Industrial melanism in Biston betularia is an example of:';
    final exp =
        'Directional selection: extreme phenotype (dark moth) favoured due to industrial pollution (predation by birds on light moths).';
    return _buildMCQ(t, type, used, q, 'Directional selection', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'Stabilizing selection',
          'Directional selection',
          'Disruptive selection',
          'Artificial selection'
        ]);
  }

  static DynamicQuestion _genEcology(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'In a food chain, only 10% energy is transferred to next trophic level (Lindeman). '
        'If producers have 10,000 J, how much reaches tertiary consumers?';
    final exp =
        'Producer → Primary (10%) → Secondary (10%) → Tertiary (10%). 10000 × 0.1³ = 10 J.';
    return _buildMCQ(t, type, used, q, 10, exp,
        forceLevel: forceLevel, unit: 'J');
  }

  static DynamicQuestion _genPlantPhysiology(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'Which pigment acts as reaction centre in Photosystem I?';
    final exp =
        'P700 chlorophyll a is the reaction centre of PS-I, absorbing light at 700 nm.';
    return _buildMCQ(t, type, used, q, 'P700', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['P680', 'P700', 'Chl b', 'Carotenoid']);
  }

  static DynamicQuestion _genBiodiversity(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q = 'Which biodiversity hotspot is located in Nepal?';
    final exp =
        'Himalaya is one of 36 biodiversity hotspots, covering parts of Nepal, Bhutan, and India.';
    return _buildMCQ(t, type, used, q, 'Himalaya', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['Western Ghats', 'Himalaya', 'Sundaland', 'Indo-Burma']);
  }

  static DynamicQuestion _genBiotechnology(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'In PCR, temperature required for annealing of primers is approximately:';
    final exp =
        'Annealing: 50-65°C (primer binding). Denaturation: 94-98°C. Extension: 72°C (Taq polymerase optimum).';
    return _buildMCQ(t, type, used, q, '50-65°C', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['72°C', '94°C', '50-65°C', '37°C']);
  }

  // ═════════════════════════════════════════════════════════════════
  //  ENGLISH — ADVANCED GRAMMAR & VOCABULARY
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _genEnglishGrammar(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final variants = [
      (
        q: 'Identify the error: "Neither the students nor the teacher were present."',
        answer: 'were → was',
        explanation:
            'With neither...nor, the verb agrees with the nearest subject. Teacher is singular, so use was.',
        options: [
          'Neither → Either',
          'were → was',
          'present → absent',
          'students → student'
        ]
      ),
      (
        q: 'Identify the error: "Each of the boys have submitted the form."',
        answer: 'have → has',
        explanation:
            'Each is singular and therefore takes the singular verb has.',
        options: ['Each → Every', 'boys → boy', 'have → has', 'the → a']
      ),
      (
        q: 'Identify the error: "One of my friends are preparing for IOE."',
        answer: 'are → is',
        explanation:
            'The head subject one is singular, so the correct verb is is.',
        options: ['friends → friend', 'are → is', 'my → mine', 'for → to']
      ),
      (
        q: 'Identify the error: "She is senior than her colleague."',
        answer: 'than → to',
        explanation:
            'Senior, junior, superior, and inferior take the preposition to.',
        options: [
          'She → Her',
          'is → was',
          'than → to',
          'colleague → colleagues'
        ]
      ),
      (
        q: 'Identify the error: "Hardly had I reached home than it started raining."',
        answer: 'than → when',
        explanation: 'The standard pair is hardly...when, not hardly...than.',
        options: [
          'Hardly → Scarcely',
          'had → have',
          'than → when',
          'raining → rained'
        ]
      ),
    ];
    final variant = variants[_rng.nextInt(variants.length)];
    return _buildMCQ(
        t, type, used, variant.q, variant.answer, variant.explanation,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: variant.options);
  }

  static DynamicQuestion _genVocabulary(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final variants = [
      (
        word: 'PERNICIOUS',
        answer: 'Benign',
        options: ['Toxic', 'Benign', 'Fatal', 'Malignant'],
        meaning: 'harmful'
      ),
      (
        word: 'LUCID',
        answer: 'Obscure',
        options: ['Clear', 'Obscure', 'Bright', 'Coherent'],
        meaning: 'clear'
      ),
      (
        word: 'ABUNDANT',
        answer: 'Scarce',
        options: ['Plentiful', 'Scarce', 'Enough', 'Ample'],
        meaning: 'plentiful'
      ),
      (
        word: 'MITIGATE',
        answer: 'Aggravate',
        options: ['Reduce', 'Relieve', 'Aggravate', 'Soothe'],
        meaning: 'make less severe'
      ),
      (
        word: 'TRANSIENT',
        answer: 'Permanent',
        options: ['Brief', 'Passing', 'Permanent', 'Temporary'],
        meaning: 'temporary'
      ),
      (
        word: 'DILIGENT',
        answer: 'Idle',
        options: ['Careful', 'Active', 'Idle', 'Persistent'],
        meaning: 'hard-working'
      ),
    ];
    final variant = variants[_rng.nextInt(variants.length)];
    final q =
        'Choose the word most nearly opposite in meaning to ${variant.word}:';
    final exp =
        '${variant.word} means ${variant.meaning}; ${variant.answer} is its opposite.';
    return _buildMCQ(t, type, used, q, variant.answer, exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: variant.options);
  }

  static DynamicQuestion _genPhonetics(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final variants = [
      (
        q: 'Which option is stressed on the first syllable?',
        answer: 'PHOtograph',
        options: ['PHOtograph', 'phoTOGraphy', 'photoGRAphic', 'ecoNOmic'],
        explanation: 'PHOtograph carries primary stress on its first syllable.'
      ),
      (
        q: 'Which option is stressed on the second syllable?',
        answer: 'phoTOGraphy',
        options: ['PHOtograph', 'phoTOGraphy', 'TElephone', 'BEAutiful'],
        explanation:
            'phoTOGraphy carries primary stress on its second syllable.'
      ),
      (
        q: 'Which word begins with a silent consonant?',
        answer: 'Knight',
        options: ['Knight', 'Garden', 'Table', 'River'],
        explanation: 'The initial k in knight is silent.'
      ),
      (
        q: 'Which word contains the /ʃ/ sound?',
        answer: 'Nation',
        options: ['Nation', 'Measure', 'Judge', 'Zero'],
        explanation: 'The letters ti in nation represent the /ʃ/ sound.'
      ),
      (
        q: 'Which pair has the same vowel sound?',
        answer: 'Sea – see',
        options: ['Sea – see', 'Put – cut', 'Food – good', 'Cat – cart'],
        explanation:
            'Sea and see are homophones and share the /iː/ vowel sound.'
      ),
    ];
    final variant = variants[_rng.nextInt(variants.length)];
    return _buildMCQ(
        t, type, used, variant.q, variant.answer, variant.explanation,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: variant.options);
  }

  // ═════════════════════════════════════════════════════════════════
  //  MAT — LOGICAL & NUMERICAL REASONING
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _genVerbalReasoning(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'Statement: All engineers are intelligent. Some intelligent people are creative. '
        'Conclusion: Some engineers are creative. Valid or Invalid?';
    final exp =
        'Invalid: middle term "intelligent" is not distributed. The intelligent people who are creative may not include engineers.';
    return _buildMCQ(t, type, used, q, 'Invalid', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: ['Valid', 'Invalid', 'Cannot say', 'Probably true']);
  }

  static DynamicQuestion _genNumericalReasoning(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final a = _rng.nextInt(5) + 2;
    final d = _rng.nextInt(5) + 2;
    final n = _rng.nextInt(4) + 4;
    final next = a + (n - 1) * d;
    final terms = List.generate(n - 1, (i) => a + i * d);
    final q = 'Find the next term: ${terms.join(', ')}, ...?';
    final exp = 'AP with a=$a, d=$d. T_$n = $a + ${n - 1}×$d = $next.';
    return _buildMCQ(t, type, used, q, next.toDouble(), exp,
        forceLevel: forceLevel);
  }

  static DynamicQuestion _genLogicalReasoning(
      SyllabusNode t, ExamType type, Set<String> used,
      {int? forceLevel, String difficulty = 'medium'}) {
    final q =
        'A is father of B, B is sister of C, C is mother of D. How is A related to D?';
    final exp =
        'A → B (father). B → C (sister), so A is father of C. C → D (mother). Therefore A is maternal grandfather of D.';
    return _buildMCQ(t, type, used, q, 'Maternal grandfather', exp,
        forceLevel: forceLevel,
        isTextAnswer: true,
        textOptions: [
          'Father',
          'Grandfather',
          'Maternal grandfather',
          'Uncle'
        ]);
  }

  // ═════════════════════════════════════════════════════════════════
  //  GENERIC FALLBACK
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _genericGenerator(
      SyllabusNode t, ExamType type, Set<String> used,
      {String difficulty = 'medium'}) {
    final concepts = t.keywords.isEmpty ? [t.nameEn] : t.keywords;
    final concept = concepts[_rng.nextInt(concepts.length)];
    final style = _rng.nextInt(4);
    late String q;
    late String correct;
    late List<String> opts;
    final otherTopics = SyllabusTree.getAllTopics(t.subjectDomain)
        .where((topic) => topic.id != t.id)
        .toList();

    if (style == 0 && t.definitions.isNotEmpty) {
      correct = t.definitions[_rng.nextInt(t.definitions.length)];
      final distractors = otherTopics
          .expand((topic) => topic.definitions)
          .where((value) => value != correct)
          .toSet()
          .toList()
        ..shuffle();
      q = 'Which statement about ${t.nameEn} is accurate when reviewing "$concept"?';
      opts = [correct, ...distractors.take(3)];
    } else if (style == 1 && t.formulas.isNotEmpty) {
      correct = t.formulas[_rng.nextInt(t.formulas.length)];
      final distractors = otherTopics
          .expand((topic) => topic.formulas)
          .where((value) => value != correct)
          .toSet()
          .toList()
        ..shuffle();
      q = 'Which relation is directly used in ${t.nameEn} for "$concept"?';
      opts = [correct, ...distractors.take(3)];
    } else if (style == 2 && t.examples.isNotEmpty) {
      final example = t.examples[_rng.nextInt(t.examples.length)];
      correct = example.finalAnswer;
      q = '${example.problem} Choose the verified worked-example result.';
      opts = [
        correct,
        'Insufficient information',
        'None of these',
        'The result cannot be determined',
      ];
    } else {
      final alternatives =
          otherTopics.map((topic) => topic.nameEn).toSet().toList()..shuffle();
      correct = t.nameEn;
      opts = [correct, ...alternatives.take(3)];
      q = 'The concept "$concept" is assessed most directly under which ${t.subject} topic?';
    }
    final fallbackOptions = [
      'None of the listed concepts',
      'Insufficient information',
      'All listed choices',
      'General ${t.subject} principles',
    ];
    for (final option in fallbackOptions) {
      if (opts.length >= 4) break;
      if (option != correct && !opts.contains(option)) opts.add(option);
    }
    opts = opts.toSet().take(4).toList()..shuffle();
    return DynamicQuestion(
      id: _uniqueId(t.id, used),
      text: q,
      options: opts..shuffle(),
      correctIndex: opts.indexOf(correct),
      explanation:
          '${t.nameEn}: ${t.definitions.isNotEmpty ? t.definitions.first : 'Study this topic thoroughly for entrance exams.'}',
      subject: t.subjectDomain,
      topicId: t.id,
      topicName: t.nameEn,
      difficulty: switch (difficulty) {
        'easy' => 0.3,
        'hard' => 0.9,
        _ => 0.6,
      },
      kuLevel: _kuLevel(t, type),
      requiresCalculator: false,
      formula: t.formulas.isNotEmpty ? t.formulas.first : null,
      concepts: t.keywords,
      origin: QuestionOrigin.syllabusKnowledge,
      sourceLabel: 'ShikshaPul syllabus practice — not a past paper',
      expertReviewed: false,
    );
  }

  // ═════════════════════════════════════════════════════════════════
  //  BUILDER UTILITIES
  // ═════════════════════════════════════════════════════════════════

  static DynamicQuestion _buildMCQ(
    SyllabusNode topic,
    ExamType type,
    Set<String> used,
    String question,
    dynamic correctAnswer,
    String explanation, {
    int? forceLevel,
    String unit = '',
    bool isTextAnswer = false,
    List<String>? textOptions,
    String difficulty = 'medium',
    QuestionOrigin origin = QuestionOrigin.parameterizedPractice,
    String sourceLabel = 'ShikshaPul generated practice — not a past paper',
    String? sourceUrl,
    bool expertReviewed = false,
  }) {
    final id = _uniqueId(topic.id, used);
    final kuLevel = forceLevel ?? _kuLevel(topic, type);
    final marks = type == ExamType.ku || type == ExamType.kuPcb
        ? 11 + (kuLevel - 1) * 2
        : 1;

    String correctStr;
    List<String> options;

    if (isTextAnswer || textOptions != null) {
      correctStr = correctAnswer.toString();
      if (textOptions != null) {
        options = textOptions.toSet().toList();
        if (!options.contains(correctStr)) options.insert(0, correctStr);
        if (options.length > 4) {
          final distractors = options.where((o) => o != correctStr).toList()
            ..shuffle();
          options = [correctStr, ...distractors.take(3)];
        }
      } else {
        options = [correctStr];
        while (options.length < 4 && options.length <= topic.keywords.length) {
          final kw = topic.keywords[_rng.nextInt(topic.keywords.length)];
          if (!options.contains(kw)) options.add(kw.capitalize());
        }
        for (final fallback in const [
          'None of these',
          'All of these',
          'Insufficient information'
        ]) {
          if (options.length >= 4) break;
          if (!options.contains(fallback)) options.add(fallback);
        }
      }
    } else {
      final numAns = (correctAnswer is int)
          ? correctAnswer.toDouble()
          : correctAnswer as double;
      if (!numAns.isFinite) {
        throw StateError(
            'Non-finite answer generated for ${topic.id}: $question');
      }
      correctStr = unit.isNotEmpty
          ? '${numAns.toStringAsFixed(2)} $unit'
          : numAns.toStringAsFixed(2);

      // Smart distractors based on common student mistakes
      final distractors = <double>[
        numAns * 2,
        numAns / 2,
        numAns + (_rng.nextInt(10) + 1),
        numAns * (_rng.nextBool() ? 10 : 0.1),
        -numAns,
        numAns + (_rng.nextInt(20) - 10),
        numAns * sqrt(2),
        numAns / sqrt(2),
      ];

      options = [correctStr];
      for (final d in distractors) {
        if (options.length >= 4) break;
        final ds = unit.isNotEmpty
            ? '${d.toStringAsFixed(2)} $unit'
            : d.toStringAsFixed(2);
        if (!options.contains(ds) && ds != correctStr) options.add(ds);
      }
      var fallbackIndex = 1;
      while (options.length < 4 && fallbackIndex <= 20) {
        final step = max(numAns.abs() * 0.1, 1.0);
        final fake = numAns + step * fallbackIndex;
        final fs = unit.isNotEmpty
            ? '${fake.toStringAsFixed(2)} $unit'
            : fake.toStringAsFixed(2);
        if (!options.contains(fs)) options.add(fs);
        fallbackIndex++;
      }
      if (options.length < 4) {
        throw StateError('Could not build unique options for ${topic.id}');
      }
    }

    options.shuffle();
    final correctIdx = options.indexOf(correctStr);

    return DynamicQuestion(
      id: id,
      text: question,
      options: options,
      correctIndex: correctIdx,
      explanation: explanation,
      subject: topic.subjectDomain,
      topicId: topic.id,
      topicName: topic.nameEn,
      difficulty: switch (difficulty) {
        'easy' => 0.3,
        'hard' => 0.9,
        _ => 0.6,
      },
      kuLevel: kuLevel,
      requiresCalculator: correctAnswer is double && correctAnswer.abs() > 100,
      formula: topic.formulas.isNotEmpty ? topic.formulas.first : null,
      concepts: topic.keywords,
      marks: marks,
      origin: origin,
      sourceLabel: sourceLabel,
      sourceUrl: sourceUrl,
      expertReviewed: expertReviewed,
    );
  }

  static double _factorial(int n) {
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }
}

// ═════════════════════════════════════════════════════════════════
//  TYPES & EXTENSIONS
// ═════════════════════════════════════════════════════════════════

typedef QuestionGenerator = DynamicQuestion Function(
  SyllabusNode topic,
  ExamType type,
  Set<String> usedIds, {
  int? forceLevel,
  String difficulty,
});

class _Variant {
  final String q;
  final double ans;
  final String exp;
  _Variant(this.q, this.ans, this.exp);
}

extension _StringExt on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
