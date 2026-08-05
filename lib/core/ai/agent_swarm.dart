// lib/core/ai/agent_swarm.dart
// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import '../../models/exam_models.dart';
import '../data/question_bank.dart';
import '../data/syllabus_tree.dart';

// ================================================================
//  CHAT MESSAGE MODEL (unchanged)
// ================================================================
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final SubjectDomain? subject;
  final String? topicId;
  final List<FormulaCard>? formulas;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.subject,
    this.topicId,
    this.formulas,
    this.isStreaming = false,
  });

  ChatMessage copyWith(
      {String? text, bool? isStreaming, List<FormulaCard>? formulas}) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      subject: subject,
      topicId: topicId,
      formulas: formulas ?? this.formulas,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class FormulaCard {
  final String name;
  final String formula;
  final String? description;
  FormulaCard({required this.name, required this.formula, this.description});
}

class AiMemoryPolicy {
  static const minimumFreeBytes = 1400 * 1024 * 1024;
  static const minimumTotalBytes = 2200 * 1024 * 1024;

  static bool supportsAdvancedModel({
    required int availableBytes,
    required int totalBytes,
    required bool lowMemory,
    required bool lowRamDevice,
  }) {
    if (lowMemory || lowRamDevice) return false;
    if (totalBytes > 0 && totalBytes < minimumTotalBytes) return false;
    if (availableBytes > 0 && availableBytes < minimumFreeBytes) return false;
    return true;
  }
}

// ================================================================
//  LOCAL LLAMA ENGINE (GGUF) — REAL IMPLEMENTATION
// ================================================================
class LocalLlamaEngine {
  static const _modelAssets = MethodChannel(
    'com.shikshapul.app/model_assets',
  );
  static const _bundledModelSha256 =
      '590d2479d401db206fe12a4562294d2de6211e06338a6e34fbad64b32f1469d0';
  static final LocalLlamaEngine _instance = LocalLlamaEngine._internal();
  factory LocalLlamaEngine() => _instance;
  LocalLlamaEngine._internal();

  LlamaController? _controller;
  bool _isLoaded = false;
  String _lastError = '';

  bool get isLoaded => _isLoaded;
  String get lastError => _lastError;

  Future<bool> supportsAdvancedModel() async {
    if (Platform.isIOS) {
      _lastError =
          'This build uses Lite Tutor; the Full AI model pack is Android-only';
      return false;
    }
    if (!Platform.isAndroid) {
      _lastError = 'Advanced local AI is available only on mobile devices';
      return false;
    }
    try {
      final capacity = await _modelAssets.invokeMapMethod<String, dynamic>(
        'deviceCapacity',
      );
      final available = capacity?['availableBytes'] as int? ?? -1;
      final total = capacity?['totalBytes'] as int? ?? -1;
      final lowMemory = capacity?['lowMemory'] as bool? ?? false;
      final lowRamDevice = capacity?['lowRamDevice'] as bool? ?? false;
      final modelBundled = capacity?['modelBundled'] as bool? ?? false;
      if (!modelBundled) {
        _lastError =
            'Lite Tutor is active; install the optional Full AI edition on a high-memory phone';
        return false;
      }
      if (!AiMemoryPolicy.supportsAdvancedModel(
        availableBytes: available,
        totalBytes: total,
        lowMemory: lowMemory,
        lowRamDevice: lowRamDevice,
      )) {
        _lastError =
            'Lite Tutor mode is active to protect this low-memory device';
        return false;
      }
      return true;
    } catch (error) {
      _lastError = 'Could not safely verify memory capacity: $error';
      return false;
    }
  }

  Future<bool> loadModel(String assetPath) async {
    try {
      if (!Platform.isAndroid) {
        _lastError = 'Advanced local Qwen inference is Android-only';
        return false;
      }
      if (!await supportsAdvancedModel()) return false;
      // Native streaming avoids holding the complete 400+ MB model in Dart
      // memory. The Android side also verifies SHA-256 before llama loads it.
      final modelPath = await _modelAssets.invokeMethod<String>(
        'prepareModel',
        {'assetPath': assetPath, 'sha256': _bundledModelSha256},
      );
      if (modelPath == null || modelPath.isEmpty) {
        throw const FileSystemException('Native model extraction failed');
      }
      return await _loadController(modelPath);
    } catch (e, st) {
      _lastError = 'Failed to load model: $e';
      _isLoaded = false;
      try {
        await _controller?.dispose();
      } catch (_) {}
      _controller = null;
      debugPrint('[ShikshaPul AI] ERROR: $_lastError');
      debugPrint('$st');
      return false;
    }
  }

  Future<bool> _loadController(String modelPath) async {
    _controller = LlamaController();
    var gpuLayers = Platform.isIOS ? 99 : 0;
    if (Platform.isAndroid) {
      try {
        final gpu = await _controller!.detectGpu();
        if (gpu.freeRamBytes > 0 &&
            gpu.freeRamBytes < AiMemoryPolicy.minimumFreeBytes) {
          final availableMb = gpu.freeRamBytes ~/ (1024 * 1024);
          throw StateError(
            'Advanced model needs about 1.4 GB free RAM; '
            '$availableMb MB is currently available',
          );
        }
        // Vulkan driver failures can terminate Android before Dart receives an
        // exception. CPU inference is slower but stable across older devices.
        gpuLayers = 0;
        debugPrint(
          '[ShikshaPul AI] ${gpu.gpuName}: ${gpu.freeRamBytes} bytes free; '
          'safe CPU mode',
        );
      } on StateError {
        rethrow;
      } catch (error) {
        debugPrint('[ShikshaPul AI] GPU detection unavailable: $error');
      }
    }
    await _controller!.loadModel(
      modelPath: modelPath,
      threads: 2,
      contextSize: 1024,
      gpuLayers: gpuLayers,
    );

    _isLoaded = true;
    _lastError = '';
    debugPrint('[ShikshaPul AI] Qwen GGUF active');
    return true;
  }

  /// Streams real tokens from the GGUF model.
  Stream<String> generate(String prompt, {int maxTokens = 512}) async* {
    if (!_isLoaded || _controller == null) {
      yield '[AI offline — using knowledge fallback]';
      return;
    }
    try {
      // Every prompt contains a bounded transcript, so native KV state must not
      // also retain the preceding prompt.
      await _controller!.clearContext();
      yield* _controller!
          .generate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: LlmConfig.temperature,
            topK: 24,
            topP: 0.8,
            repeatPenalty: 1.12,
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      await _controller?.stop();
      rethrow;
    }
  }

  Future<void> stop() async => _controller?.stop();

  Future<void> unload() async {
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    _isLoaded = false;
  }
}

// ================================================================
//  CONVERSATIONAL AI SWARM
// ================================================================
class ShikshaPulSwarm {
  static final ShikshaPulSwarm instance = ShikshaPulSwarm._internal();
  ShikshaPulSwarm._internal();

  final LocalLlamaEngine _llama = LocalLlamaEngine();
  final Random _random = Random();
  bool _initialized = false;
  Future<void>? _initialization;

  final List<ChatMessage> _chatHistory = [];
  static const int _maxHistory = 8;

  static const String defaultModelAsset = 'assets/models/qwen-0.5b-q3_k_m.gguf';

  Future<void> initializeBaseModel() async {
    if (_llama.isLoaded) return;
    if (_initialization != null) return _initialization!;
    final operation = _initialize();
    _initialization = operation;
    try {
      await operation;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initialize() async {
    final loaded = await _llama.loadModel(defaultModelAsset);
    _initialized = loaded;
    debugPrint(loaded
        ? '[ShikshaPul AI] Local Qwen engine active'
        : '[ShikshaPul AI] Knowledge engine active (${_llama.lastError})');
  }

  bool get isRealModelLoaded => _llama.isLoaded;
  bool get isInitializing => _initialization != null;
  bool get isReady => _initialized;
  String get modelError => _llama.lastError;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  void clearHistory() => _chatHistory.clear();
  Future<void> stopGeneration() => _llama.stop();
  Future<bool> checkAdvancedModelSupport() => _llama.supportsAdvancedModel();

  Future<void> releaseModel() async {
    final loading = _initialization;
    if (loading != null) {
      try {
        await loading;
      } catch (_) {}
    }
    await _llama.stop();
    await _llama.unload();
    _initialized = false;
  }

  Stream<ChatMessage> chat(
    String userMessage, {
    SubjectDomain? subject,
    String? topicId,
    CourseProfile? course,
  }) async* {
    // 1. User message
    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      subject: subject,
      topicId: topicId,
    );
    _chatHistory.add(userMsg);
    _trimHistory();

    // 2. Initial streaming message
    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    var aiMsg = ChatMessage(
      id: aiMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      subject: subject,
      topicId: topicId,
      isStreaming: true,
    );
    yield aiMsg;

    // 3. Stream native tokens immediately. The deterministic knowledge engine
    // remains available if the model cannot load or generation fails.
    var buffer = _studyStrategyResponse(userMessage, course);
    if (buffer.isEmpty && _llama.isLoaded) {
      try {
        final prompt = _buildChatMLPrompt(
          userMessage,
          subject,
          topicId,
          course,
        );
        await for (final chunk in _llama.generate(prompt, maxTokens: 256)) {
          buffer += chunk;
          aiMsg = aiMsg.copyWith(text: buffer, isStreaming: true);
          yield aiMsg;
        }
      } catch (error) {
        debugPrint('[ShikshaPul AI] Generation failed: $error');
        await _llama.stop();
        buffer = '';
      }
    }
    if (buffer.trim().isEmpty) {
      buffer = _generateKnowledgeResponse(
        userMessage,
        subject,
        topicId,
        course,
      );
      aiMsg = aiMsg.copyWith(text: buffer, isStreaming: true);
      yield aiMsg;
    }
    final stopIdx = buffer.indexOf('<|im_start|>');
    if (stopIdx > 0) buffer = buffer.substring(0, stopIdx).trim();
    final formulas = _extractFormulas(buffer);

    // 5. Final
    aiMsg = aiMsg.copyWith(
      text: buffer,
      isStreaming: false,
      formulas: formulas.isNotEmpty ? formulas : null,
    );
    _chatHistory.add(aiMsg);
    _trimHistory();
    yield aiMsg;
  }

  void _trimHistory() {
    if (_chatHistory.length > _maxHistory * 2) {
      _chatHistory.removeRange(0, _chatHistory.length - _maxHistory * 2);
    }
  }

  /// Builds a ChatML prompt (Qwen-native) with history + syllabus context.
  String _buildChatMLPrompt(
    String query,
    SubjectDomain? subject,
    String? topicId,
    CourseProfile? course,
  ) {
    final context = _buildHistoryContext();
    final topicInfo = topicId != null ? _getTopicInfo(topicId) : '';
    const sys =
        'You are ShikshaPul, a careful offline study assistant for Nepal entrance preparation. '
        'Use only the supplied syllabus context and the mathematics you can verify step by step. '
        'Never claim that generated material is an official or past-paper question. '
        'Never invent an exam rule, source, statistic, medical fact, or formula. '
        'If context is insufficient, say exactly what is missing and advise checking the official syllabus or a teacher. '
        'For calculations: list givens, select the formula, substitute with units, compute, and sanity-check. '
        'Keep answers concise and exam-focused; use Nepali examples only when they improve understanding.';

    final buffer = StringBuffer()
      ..writeln('<|im_start|>system')
      ..writeln(sys)
      ..writeln('<|im_end|>');

    if (context.isNotEmpty) {
      buffer.writeln('<|im_start|>user');
      buffer.writeln('Previous conversation:\n$context');
      buffer.writeln('<|im_end|>');
    }

    buffer.writeln('<|im_start|>user');
    buffer.writeln('Subject: ${subject?.name ?? 'General'}');
    if (course != null) {
      buffer.writeln(
        'Exam: ${course.name}; ${course.totalQuestions} questions; '
        '${course.durationMinutes} minutes; negative marking: '
        '${course.hasNegativeMarking}; adaptive: ${course.isAdaptive}; '
        'blueprint: ${course.blueprintVersion}.',
      );
    }
    if (topicInfo.isNotEmpty) buffer.writeln(topicInfo);
    buffer.writeln('Question: $query');
    buffer.writeln('<|im_end|>');

    buffer.writeln('<|im_start|>assistant');

    return buffer.toString();
  }

  String _buildHistoryContext() {
    if (_chatHistory.isEmpty) return '';
    return _chatHistory
        .where((m) => m.text.isNotEmpty)
        .toList()
        .reversed
        .skip(1) // the current user message is written separately in the prompt
        .take(_maxHistory)
        .toList()
        .reversed
        .map((m) => '${m.isUser ? 'Student' : 'Teacher'}: ${m.text}')
        .join('\n');
  }

  String _getTopicInfo(String topicId) {
    final topic = SyllabusTree.findTopicById(topicId);
    if (topic == null) return '';
    final examples = topic.examples.take(2).map((example) =>
        'Problem: ${example.problem}\nSteps: ${example.steps.join(' -> ')}\nAnswer: ${example.finalAnswer}');
    return 'VERIFIED LOCAL STUDY CONTEXT\n'
        'Topic: ${topic.nameEn}\n'
        'Definitions: ${topic.definitions.take(4).join(' | ')}\n'
        'Formulas: ${topic.formulas.take(6).join(' | ')}\n'
        'Keywords: ${topic.keywords.take(8).join(', ')}\n'
        'Worked examples: ${examples.join(' | ')}\n'
        'END STUDY CONTEXT';
  }

  String _studyStrategyResponse(String query, CourseProfile? course) {
    final normalized = query.toLowerCase();
    final strategyQuery = RegExp(
      r'\b(pass|scholarship|rank|strategy|study plan|seven-day|7-day|epcm|tip|trick|configure|configuration)\b',
    ).hasMatch(normalized);
    if (!strategyQuery) return '';

    final examName = course?.name ?? 'your entrance exam';
    final markingAdvice = course == null
        ? 'Check the latest official marking and navigation rules before exam day.'
        : course.isAdaptive
            ? 'Accuracy early in each subject matters in this adaptive simulator. Read every option before committing.'
            : course.hasNegativeMarking
                ? 'Use a confidence-first first pass. Attempt uncertain items only after eliminating options; avoid blind guessing under negative marking.'
                : 'Complete confident questions first, then use elimination so answerable items are not left blank when navigation permits.';

    return '''**A serious $examName preparation system**

No tutor can honestly guarantee a pass, rank, or scholarship. What I can give you is a high-discipline process that makes improvement measurable.

**Daily loop**
1. Active recall: reproduce formulas, definitions, reactions, or biological processes without notes.
2. Weak-topic repair: learn one concept and solve 15–25 focused questions.
3. Timed mixed practice: work under a fixed clock without checking answers midway.
4. Mistake notebook: classify every error as concept, calculation, memory, or rushed reading.
5. Spaced retest: re-solve errors after 24 hours and 7 days.

**Weekly configuration**
• Take one full Simulator paper and review it for at least as long as you attempted it.
• Use Mock Exam for learning; use Simulator for measurement.
• Do not increase difficulty until you can explain why each corrected answer is right.
• Track accuracy by topic, not only total score.

**Exam decision rule**
$markingAdvice

**Using EPCM or another book**
Use a purchased or authorized copy. Attempt sets before reading keys, enter mistakes into this app, and verify disputed answers with a qualified teacher. Do not memorize answer letters or assume exact questions will repeat.

Consistency with this process can improve your probability of passing and competing for merit, but the result still depends on prior knowledge, time, health, exam difficulty, and execution.''';
  }

  // ──────────────────── KNOWLEDGE FALLBACK ────────────────────
  String _generateKnowledgeResponse(
    String query,
    SubjectDomain? subject,
    String? topicId,
    CourseProfile? course,
  ) {
    final lowerQuery = query.toLowerCase();

    if (_isGreeting(lowerQuery)) return _greetingResponse(subject);

    var searchSubject = subject ?? SubjectDomain.physics;
    SyllabusNode? matchedTopic;
    int bestScore = 0;

    // Lite Tutor searches the complete local syllabus, not only the currently
    // selected chip. This keeps Physics, Chemistry, Mathematics and Biology
    // useful without loading a language model or requiring internet access.
    for (final candidateSubject in SubjectDomain.values) {
      for (final topic in SyllabusTree.getAllTopics(candidateSubject)) {
        var score = 0;
        if (lowerQuery.contains(topic.nameEn.toLowerCase())) score += 80;
        for (final keyword in topic.keywords) {
          if (lowerQuery.contains(keyword.toLowerCase())) {
            score += keyword.length * 2;
          }
        }
        if (topic.id == topicId) score += 100;
        if (score > 0 && candidateSubject == subject) score += 3;
        if (score > bestScore) {
          bestScore = score;
          matchedTopic = topic;
          searchSubject = candidateSubject;
        }
      }
    }

    if (matchedTopic != null && bestScore > 0) {
      if (RegExp(r'\b(practice|quiz|mcq|question)\b').hasMatch(lowerQuery)) {
        final question = QuestionEngine.generateSingle(
          matchedTopic.id,
          course?.type ?? ExamType.ioe,
        );
        final options = question.options
            .asMap()
            .entries
            .map((entry) =>
                '${String.fromCharCode(65 + entry.key)}. ${entry.value}')
            .join('\n');
        final correctLetter = String.fromCharCode(65 + question.correctIndex);
        return '''**${question.trustLabel} — ${question.topicName}**

${question.text}

$options

**Answer:** $correctLetter. ${question.options[question.correctIndex]}

**Why:** ${question.explanation}

Source label: ${question.sourceLabel}''';
      }
      return _buildConversationalExplanation(
          matchedTopic, searchSubject, query);
    }
    return _buildConversationalGeneric(searchSubject, query);
  }

  bool _isGreeting(String text) {
    final greetings = [
      'hi',
      'hello',
      'hey',
      'namaste',
      'hola',
      'good morning',
      'good afternoon',
      'good evening',
      'sup'
    ];
    final normalized = text.trim().replaceAll(RegExp(r'[^a-z\s]'), '');
    return greetings.contains(normalized);
  }

  String _greetingResponse(SubjectDomain? subject) {
    final responses = [
      "Hey there! 👋 I'm ShikshaPul, your AI tutor for Nepal entrance exams. Ready to crush some concepts today?",
      "Namaste! 🙏 Ready to level up your ${subject?.name ?? 'entrance exam'} prep? Ask me anything!",
      "Hello! I'm here to help you master IOE, KU, PU, PoU, and MECEE-BL. What topic should we tackle?",
    ];
    return responses[_random.nextInt(responses.length)];
  }

  String _buildConversationalExplanation(
      SyllabusNode topic, SubjectDomain subject, String query) {
    final explanations = <String, String>{
      'PHYS_KIN':
          """Great question on Kinematics! Let me break this down step by step.

**The Core Idea:**
Kinematics is all about describing motion — where things are, how fast they're going, and how that changes — without worrying about WHY they're moving.

**The Three Magic Equations you MUST memorize:**
1. **v = u + at** — connects velocity, acceleration, and time
2. **s = ut + ½at²** — connects displacement, initial velocity, and time
3. **v² = u² + 2as** — connects velocity and displacement without time

**My Problem-Solving Strategy:**
→ Step 1: List what you know (u, v, a, t, s)
→ Step 2: Find what's missing — pick the equation that doesn't have that variable
→ Step 3: Plug in numbers with consistent units (always use SI: m, m/s, m/s², s)

**Quick Example:**
If a ball is dropped from height h, u = 0 and a = g = 9.8 m/s².
Using equation 2: h = ½gt², so t = √(2h/g)

**Useful check:** Relative velocity is vector subtraction: **v_rel = v₁ - v₂**. Confirm the chosen direction before assigning signs.

Want me to walk through a specific problem, or should we try some practice questions?"""
    };

    String? explanation = explanations[topic.id];
    if (explanation != null) return explanation;

    return """Great question about **${topic.nameEn}**!

This is a ${topic.difficulty < 0.5 ? 'fundamental' : topic.difficulty < 0.7 ? 'intermediate' : 'advanced'} topic for Nepal entrance exams.

**Key Concepts:**
${topic.keywords.take(5).map((k) => '• $k').join('\n')}

**Formulas to Remember:**
${topic.formulas.take(3).map((f) => '• $f').join('\n')}

**Study Strategy:**
1. Read the theory thoroughly
2. Memorize all formulas with conditions
3. Solve 10 numerical problems
4. Attempt separately sourced and verified past questions

${topic.definitions.isNotEmpty ? '**Core definition:**\n${topic.definitions.first}\n' : ''}
${topic.examples.isNotEmpty ? '**Worked example:**\n${topic.examples.first.problem}\n${topic.examples.first.steps.map((step) => '• $step').join('\n')}\nAnswer: ${topic.examples.first.finalAnswer}\n' : ''}

Would you like me to:
• Explain a specific concept deeper?
• Show a worked example?
• Generate practice questions on this topic?""";
  }

  String _buildConversationalGeneric(SubjectDomain subject, String query) {
    final topics = SyllabusTree.getAllTopics(subject).take(5).toList();
    return """I see you're asking about "$query" in ${subject.name}.

Since this is a broad topic, let me point you to some key areas:

${topics.asMap().entries.map((e) => '${e.key + 1}. **${e.value.nameEn}**').join('\n')}

**My Advice:**
• Break the topic into smaller sub-topics
• Master the formulas first, then apply them
• Use the Mock Exam module to test yourself
• Time yourself — aim for ${subject == SubjectDomain.mathematics ? '2-3' : '1.5-2'} minutes per question

**Subject-safe habits:**
${subject == SubjectDomain.physics ? '• Draw the situation and preserve units\n• Check signs and limiting cases' : subject == SubjectDomain.chemistry ? '• Balance equations before calculating\n• Record reaction conditions and mole ratios' : subject == SubjectDomain.mathematics ? '• State the identity or theorem first\n• Check domain, signs, and endpoints' : subject == SubjectDomain.biology ? '• Use exact textbook terminology\n• Compare every option before selecting' : '• Identify the tested rule first\n• Read option wording carefully'}

Which specific sub-topic would you like to explore? Or should I generate some practice questions for you?""";
  }

  List<FormulaCard> _extractFormulas(String text) {
    final formulas = <FormulaCard>[];
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('•') &&
          (trimmed.contains('=') ||
              trimmed.contains('∫') ||
              trimmed.contains('d/dx'))) {
        final parts = trimmed.substring(1).trim().split('—');
        if (parts.length >= 2) {
          formulas.add(FormulaCard(
            name: parts[0].trim(),
            formula: parts[1].trim(),
          ));
        } else if (trimmed.contains('=')) {
          final eqParts = trimmed.substring(1).trim().split('=');
          if (eqParts.length == 2) {
            formulas.add(FormulaCard(
              name: eqParts[0].trim(),
              formula: '= ${eqParts[1].trim()}',
            ));
          }
        }
      }
    }
    return formulas;
  }
}
