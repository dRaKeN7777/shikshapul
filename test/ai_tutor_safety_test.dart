import 'package:flutter_test/flutter_test.dart';
import 'package:shikshapul/core/ai/agent_swarm.dart';
import 'package:shikshapul/core/data/syllabus_tree.dart';
import 'package:shikshapul/models/exam_models.dart';

void main() {
  setUpAll(SyllabusTree.init);

  test('one-gigabyte phones remain in lite tutor mode', () {
    expect(
      AiMemoryPolicy.supportsAdvancedModel(
        availableBytes: 700 * 1024 * 1024,
        totalBytes: 1024 * 1024 * 1024,
        lowMemory: false,
        lowRamDevice: true,
      ),
      isFalse,
    );
    expect(
      AiMemoryPolicy.supportsAdvancedModel(
        availableBytes: 2 * 1024 * 1024 * 1024,
        totalBytes: 4 * 1024 * 1024 * 1024,
        lowMemory: false,
        lowRamDevice: false,
      ),
      isTrue,
    );
  });

  test('chat uses deterministic tutor without auto-loading native model',
      () async {
    final swarm = ShikshaPulSwarm.instance;
    await swarm.releaseModel();

    final messages = await swarm
        .chat(
          'Explain kinematics',
          subject: SubjectDomain.physics,
          topicId: 'PHYS_KIN',
          course: ExamSession.getProfile(ExamType.ioe),
        )
        .toList();

    expect(swarm.isRealModelLoaded, isFalse);
    expect(messages.last.isStreaming, isFalse);
    expect(messages.last.text, contains('Kinematics'));
  });

  test('rank request receives guarded study strategy', () async {
    final messages = await ShikshaPulSwarm.instance
        .chat(
          'Give me scholarship rank strategy',
          course: ExamSession.getProfile(ExamType.ku),
        )
        .toList();

    expect(messages.last.text, contains('Daily loop'));
    expect(messages.last.text, contains('No tutor can honestly guarantee'));
    expect(messages.last.text, contains('Mistake notebook'));
  });

  test('lite tutor can produce labelled syllabus practice', () async {
    final messages = await ShikshaPulSwarm.instance
        .chat(
          'Give me a practice MCQ on kinematics',
          subject: SubjectDomain.physics,
          topicId: 'PHYS_KIN',
          course: ExamSession.getProfile(ExamType.ioe),
        )
        .toList();

    expect(messages.last.text, contains('GENERATED PRACTICE'));
    expect(messages.last.text, contains('Answer:'));
    expect(messages.last.text, isNot(contains('LICENSED PAST PAPER')));
  });

  test('lite tutor searches knowledge across subject chips', () async {
    final messages = await ShikshaPulSwarm.instance
        .chat(
          'Explain the mole and Avogadro concept',
          subject: SubjectDomain.physics,
          course: ExamSession.getProfile(ExamType.ioe),
        )
        .toList();

    expect(messages.last.text, contains('Stoichiometry'));
    expect(messages.last.text, contains('n = w/M'));
  });
}
