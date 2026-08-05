// lib/screens/ai_tutor_screen.dart
import 'dart:async';
import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import '../core/ai/agent_swarm.dart';
import '../core/data/question_bank.dart';
import '../core/data/syllabus_tree.dart';
import '../models/exam_models.dart';

class AiTutorScreen extends StatefulWidget {
  final CourseProfile course;
  final String? initialQuery;
  final String? focusTopicId;

  const AiTutorScreen({
    super.key,
    required this.course,
    this.initialQuery,
    this.focusTopicId,
  });

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  SubjectDomain? _currentSubject;
  String? _currentTopicId;
  String _searchQuery = '';
  bool _showSearch = false;
  bool _modelLoading = false;
  bool _modelAttempted = false;
  bool _modelLoaded = false;
  bool _advancedAvailable = true;
  String _modelError = '';

  late final AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _currentSubject = widget.course.subjectDistribution.keys.first;
    _currentTopicId = widget.focusTopicId;
    final focusTopic = widget.focusTopicId == null
        ? null
        : SyllabusTree.findTopicById(widget.focusTopicId!);
    if (focusTopic != null) _currentSubject = focusTopic.subjectDomain;

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _addWelcomeMessage();
    _modelLoaded = ShikshaPulSwarm.instance.isRealModelLoaded;
    _modelAttempted = _modelLoaded;
    unawaited(_checkDeviceMode());

    if (widget.initialQuery != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _sendMessage(widget.initialQuery!);
      });
    }
  }

  Future<void> _enableAdvancedAi() async {
    if (_modelLoading || _modelLoaded || !_advancedAvailable) return;
    setState(() {
      _modelLoading = true;
      _modelAttempted = true;
      _modelError = '';
    });
    try {
      await ShikshaPulSwarm.instance.initializeBaseModel();
    } catch (error) {
      _modelError = '$error';
    }
    if (!mounted) return;
    setState(() {
      _modelLoading = false;
      _modelLoaded = ShikshaPulSwarm.instance.isRealModelLoaded;
      if (!_modelLoaded && _modelError.isEmpty) {
        _modelError = ShikshaPulSwarm.instance.modelError;
      }
    });
  }

  Future<void> _checkDeviceMode() async {
    final supported =
        await ShikshaPulSwarm.instance.checkAdvancedModelSupport();
    if (!mounted) return;
    setState(() {
      _advancedAvailable = supported;
      if (!supported) {
        _modelError = ShikshaPulSwarm.instance.modelError;
      }
    });
  }

  void _addWelcomeMessage() {
    final welcome = ChatMessage(
      id: 'welcome',
      text:
          """Hey there! 👋 I'm **ShikshaPul AI**, your personal tutor for Nepal entrance exams.

I can help you with:
• 📚 Concept explanations with formulas
• 🔢 Step-by-step worked examples
• 📝 Practice question generation
• 📊 Weak topic analysis

The local AI is a study aid, not an official answer key. Verify important or
high-stakes answers against the linked syllabus and a qualified teacher.

What would you like to learn today?""",
      isUser: false,
      timestamp: DateTime.now(),
      subject: _currentSubject,
    );
    setState(() => _messages.add(welcome));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      subject: _currentSubject,
      topicId: _currentTopicId,
    );

    setState(() {
      _messages.add(userMsg);
      _trimUiMessages();
      _isTyping = true;
      _textController.clear();
    });

    _scrollToBottom();

    try {
      await for (final aiMsg in ShikshaPulSwarm.instance.chat(
        text.trim(),
        subject: _currentSubject,
        topicId: _currentTopicId,
        course: widget.course,
      )) {
        if (!mounted) break;
        setState(() {
          final existingIndex = _messages.indexWhere((m) => m.id == aiMsg.id);
          if (existingIndex >= 0) {
            _messages[existingIndex] = aiMsg;
          } else {
            _messages.add(aiMsg);
          }
          _trimUiMessages();
          _isTyping = aiMsg.isStreaming;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addSystemMessage(
        "⚠️ Sorry, I ran into an error. Please try again in a moment.",
      );
    }
  }

  void _addSystemMessage(String text) {
    final msg = ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      subject: _currentSubject,
    );
    setState(() {
      _messages.add(msg);
      _trimUiMessages();
    });
    _scrollToBottom();
  }

  void _trimUiMessages() {
    const maximumMessages = 60;
    if (_messages.length <= maximumMessages) return;
    final preserveWelcome = _messages.first.id == 'welcome';
    final removeFrom = preserveWelcome ? 1 : 0;
    final removeCount = _messages.length - maximumMessages;
    _messages.removeRange(removeFrom, removeFrom + removeCount);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      ShikshaPulSwarm.instance.clearHistory();
    });
    _addWelcomeMessage();
  }

  List<SyllabusNode> _getSearchResults() {
    if (_searchQuery.isEmpty) return [];
    return SyllabusTree.searchTopics(_searchQuery);
  }

  /// Safely converts a dynamic subject value (String or enum) into [SubjectDomain].
  SubjectDomain? _parseSubject(dynamic value) {
    if (value == null) return null;
    if (value is SubjectDomain) return value;
    if (value is String) {
      try {
        return SubjectDomain.values.byName(value);
      } catch (_) {
        final lowered = value.toLowerCase();
        for (final s in SubjectDomain.values) {
          if (s.name.toLowerCase() == lowered) return s;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _getSearchResults();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1020),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("AI Tutor", style: TextStyle(fontSize: 18)),
            Text(
              (_currentSubject?.name ?? "general").toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: _subjectColor(_currentSubject).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: const Color(0xFF38BDF8),
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          if (_showSearch && searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              color: const Color(0xFF1E293B),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, i) {
                  final topic = searchResults[i];
                  final subject = _parseSubject(topic.subject);
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _subjectColor(subject),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      topic.nameEn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      (subject?.name ?? topic.subject.toString()).toUpperCase(),
                      style: TextStyle(
                        color: _subjectColor(subject),
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _currentSubject = subject;
                        _currentTopicId = topic.id;
                        _searchQuery = '';
                        _showSearch = false;
                      });
                      _sendMessage("Explain ${topic.nameEn}");
                    },
                  );
                },
              ),
            ),
          _buildSubjectChips(),
          _buildEngineStatus(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          if (!_isTyping) _buildQuickActions(),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildEngineStatus() {
    final active = _modelLoaded;
    final failed = _modelAttempted && !_modelLoading && !active;
    final color = active
        ? const Color(0xFF10B981)
        : _modelLoading
            ? const Color(0xFFF59E0B)
            : const Color(0xFF38BDF8);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (_modelLoading)
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(active ? Icons.memory : Icons.shield_outlined,
                size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _modelLoading
                  ? 'Checking memory and preparing local AI…'
                  : active
                      ? 'Advanced local AI active • verify important answers'
                      : !_advancedAvailable
                          ? 'Lite Tutor active • optimized for low-memory phones'
                          : failed
                              ? 'Safe tutor active • local model unavailable${_modelError.isEmpty ? '' : ': ${_shortModelError()}'}'
                              : 'Safe tutor ready • advanced model is optional',
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
          if (!active && !_modelLoading && _advancedAvailable) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: _enableAdvancedAi,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(failed ? 'RETRY' : 'ENABLE'),
            ),
          ],
        ],
      ),
    );
  }

  String _shortModelError() {
    final error = _modelError
        .replaceFirst('Failed to load model: ', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return error.length <= 70 ? error : '${error.substring(0, 67)}…';
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E293B),
      child: TextField(
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search topics, formulas, concepts...",
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF0B1020),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildSubjectChips() {
    final subjects = widget.course.subjectDistribution.keys.toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: subjects.map((subject) {
            final isSelected = _currentSubject == subject;
            final color = _subjectColor(subject);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSelected,
                showCheckmark: false,
                backgroundColor: const Color(0xFF1E293B),
                selectedColor: color.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected ? color : const Color(0xFF334155),
                  width: isSelected ? 2 : 1,
                ),
                label: Text(
                  subject.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? color : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
                onSelected: (_) {
                  setState(() {
                    _currentSubject = subject;
                    _currentTopicId = null;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final color = isUser ? const Color(0xFF38BDF8) : const Color(0xFF1E293B);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF38BDF8),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "ShikshaPul AI",
                            style: TextStyle(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildRichText(msg.text),
                ],
              ),
            ),
            if (!isUser && msg.formulas != null && msg.formulas!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children:
                      msg.formulas!.map((f) => _buildFormulaCard(f)).toList(),
                ),
              ),
            if (!isUser && !msg.isStreaming && msg.topicId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton(
                      "Test Me",
                      Icons.quiz,
                      const Color(0xFF10B981),
                      () => _generatePracticeQuestions(msg.topicId!),
                    ),
                    _actionButton(
                      "Example",
                      Icons.calculate,
                      const Color(0xFFF59E0B),
                      () => _sendMessage("Show me a worked example on this"),
                    ),
                    _actionButton(
                      "Visualize",
                      Icons.insights,
                      const Color(0xFFA855F7),
                      () => _showVisualizer(msg.topicId),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      if (line.contains('**')) {
        final parts = line.split('**');
        for (int j = 0; j < parts.length; j++) {
          spans.add(TextSpan(
            text: parts[j],
            style: TextStyle(
              color: Colors.white,
              fontWeight: j.isOdd ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              height: 1.5,
            ),
          ));
        }
        spans.add(const TextSpan(text: '\n'));
      } else if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ));
      } else if (line.trim().startsWith('#')) {
        spans.add(TextSpan(
          text: '${line.replaceAll('#', '').trim()}\n',
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            height: 1.5,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildFormulaCard(FormulaCard formula) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formula.name,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            formula.formula,
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (context, child) {
                    final offset = index * 0.3;
                    final value = sin(
                      (_typingController.value * 2 * 3.1416) + offset,
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6 + (value * 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(
                          alpha: 0.6 + (value * 0.3),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final allActions = [
      _QuickAction("7-Day Study Plan"),
      _QuickAction("Exam Strategy"),
      _QuickAction("Explain Kinematics", "PHYS_KIN"),
      _QuickAction("Newton's Laws", "PHYS_NLM"),
      _QuickAction("Integration", "MATH_INT"),
      _QuickAction("Stoichiometry", "CHEM_STO"),
      _QuickAction("Cell Biology", "BIO_CEL"),
    ];
    final courseSubjects = widget.course.subjectDistribution.keys.toSet();
    final actions = allActions.where((action) {
      final topicId = action.topicId;
      if (topicId == null) return true;
      final topic = SyllabusTree.findTopicById(topicId);
      return topic != null && courseSubjects.contains(topic.subjectDomain);
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions.map((a) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                side: const BorderSide(color: Color(0xFF334155)),
                label: Text(
                  a.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                onPressed: () {
                  final topic = a.topicId == null
                      ? null
                      : SyllabusTree.findTopicById(a.topicId!);
                  if (topic != null) {
                    setState(() {
                      _currentSubject = topic.subjectDomain;
                      _currentTopicId = topic.id;
                    });
                  }
                  _sendMessage(a.label);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showVisualizer(String? topicId) {
    final topic = topicId == null ? null : SyllabusTree.findTopicById(topicId);
    final subject = topic?.subjectDomain ?? _currentSubject;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights, color: Color(0xFFA855F7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(topic?.nameEn ?? '${subject?.name} concept',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1.45,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: CustomPaint(
                    painter: _ConceptPainter(
                      subject: subject ?? SubjectDomain.mathematics,
                      animation: _typingController,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(_visualizerHint(subject),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }

  String _visualizerHint(SubjectDomain? subject) => switch (subject) {
        SubjectDomain.physics =>
          'Watch the object move along its trajectory. Relate position, velocity, and time before substituting values.',
        SubjectDomain.chemistry =>
          'Use the shells to reason about valence electrons, bonding, and periodic trends.',
        SubjectDomain.biology =>
          'Build a mental map from the cell boundary to organelles and then to their functions.',
        SubjectDomain.english =>
          'Connect the prompt, grammar rule, and final choice as a reasoning chain.',
        SubjectDomain.mat =>
          'Follow each connection as one step in the logical reasoning chain.',
        _ =>
          'Observe how changing x changes y. Identify intercepts, slope, and turning points before calculating.',
      };

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                textInputAction: TextInputAction.send,
                enabled: !_isTyping,
                onSubmitted: _isTyping ? null : (text) => _sendMessage(text),
                decoration: InputDecoration(
                  hintText:
                      "Ask me anything about ${_currentSubject?.name ?? 'entrance exams'}...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap:
                  _isTyping ? null : () => _sendMessage(_textController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF38BDF8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePracticeQuestions(String topicId) async {
    final topic = SyllabusTree.findTopicById(topicId);
    if (topic == null) return;

    try {
      final questions = QuestionEngine.generateForTopic(
        topicId,
        widget.course.type,
        3,
      );

      final subject = _parseSubject(topic.subject);

      final msg = ChatMessage(
        id: 'practice_${DateTime.now().millisecondsSinceEpoch}',
        text: """Here are **3 practice questions** on **${topic.nameEn}**:

${questions.asMap().entries.map((e) => "**Q${e.key + 1}.** ${e.value.text}\n").join('\n')}

Want me to solve any of these step by step? Just say "Solve Q1" or "Explain Q3"!""",
        isUser: false,
        timestamp: DateTime.now(),
        subject: subject,
        topicId: topicId,
      );

      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (e) {
      _addSystemMessage("⚠️ Couldn't generate questions right now.");
    }
  }

  Color _subjectColor(SubjectDomain? subject) {
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
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  void dispose() {
    unawaited(ShikshaPulSwarm.instance.releaseModel());
    _typingController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _QuickAction {
  final String label;
  final String? topicId;
  _QuickAction(this.label, [this.topicId]);
}

class _ConceptPainter extends CustomPainter {
  final SubjectDomain subject;
  final Animation<double> animation;

  _ConceptPainter({required this.subject, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    switch (subject) {
      case SubjectDomain.physics:
        _paintTrajectory(canvas, size);
        break;
      case SubjectDomain.chemistry:
        _paintAtom(canvas, size);
        break;
      case SubjectDomain.biology:
        _paintCell(canvas, size);
        break;
      case SubjectDomain.mathematics:
        _paintGraph(canvas, size);
        break;
      case SubjectDomain.english:
      case SubjectDomain.mat:
      case SubjectDomain.healthKnowledge:
        _paintReasoning(canvas, size);
        break;
    }
  }

  void _paintAxes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(24, size.height - 24),
        Offset(size.width - 16, size.height - 24), paint);
    canvas.drawLine(const Offset(24, 16), Offset(24, size.height - 24), paint);
  }

  void _paintTrajectory(Canvas canvas, Size size) {
    _paintAxes(canvas, size);
    final path = Path();
    for (var i = 0; i <= 80; i++) {
      final t = i / 80;
      final x = 28 + t * (size.width - 48);
      final y = size.height - 28 - (4 * t * (1 - t)) * (size.height - 60);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF38BDF8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final t = animation.value;
    final point = Offset(
      28 + t * (size.width - 48),
      size.height - 28 - (4 * t * (1 - t)) * (size.height - 60),
    );
    canvas.drawCircle(point, 7, Paint()..color = const Color(0xFFF59E0B));
  }

  void _paintGraph(Canvas canvas, Size size) {
    _paintAxes(canvas, size);
    final path = Path();
    for (var i = 0; i <= 100; i++) {
      final t = i / 100;
      final x = 24 + t * (size.width - 40);
      final y = size.height / 2 - sin(t * 2 * 3.14159265) * (size.height * 0.3);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF59E0B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final t = animation.value;
    canvas.drawCircle(
      Offset(24 + t * (size.width - 40),
          size.height / 2 - sin(t * 2 * 3.14159265) * (size.height * 0.3)),
      6,
      Paint()..color = const Color(0xFF38BDF8),
    );
  }

  void _paintAtom(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbit = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final rotation in [0.0, 1.047, -1.047]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero,
              width: size.width * 0.72,
              height: size.height * 0.34),
          orbit);
      final angle = animation.value * 2 * 3.14159265;
      canvas.drawCircle(
        Offset(cos(angle) * size.width * 0.36, sin(angle) * size.height * 0.17),
        5,
        Paint()..color = const Color(0xFF38BDF8),
      );
      canvas.restore();
    }
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFFF43F5E));
  }

  void _paintCell(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
        center: center, width: size.width * 0.76, height: size.height * 0.72);
    canvas.drawOval(rect, Paint()..color = const Color(0x3322C55E));
    canvas.drawOval(
        rect,
        Paint()
          ..color = const Color(0xFF10B981)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(center, size.shortestSide * 0.14,
        Paint()..color = const Color(0xFFA855F7));
    for (var i = 0; i < 7; i++) {
      final angle = i * 2 * 3.14159265 / 7 + animation.value * 0.3;
      canvas.drawOval(
        Rect.fromCenter(
          center: center +
              Offset(cos(angle) * size.width * 0.27,
                  sin(angle) * size.height * 0.24),
          width: 18,
          height: 9,
        ),
        Paint()..color = const Color(0xFFF59E0B),
      );
    }
  }

  void _paintReasoning(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * 0.18, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.25),
      Offset(size.width * 0.82, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.78),
    ];
    final line = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], line);
    }
    for (var i = 0; i < points.length; i++) {
      final active = (animation.value * points.length).floor() == i;
      canvas.drawCircle(
          points[i],
          active ? 15 : 11,
          Paint()
            ..color =
                active ? const Color(0xFFF59E0B) : const Color(0xFFA855F7));
    }
  }

  @override
  bool shouldRepaint(covariant _ConceptPainter oldDelegate) =>
      oldDelegate.subject != subject;
}
