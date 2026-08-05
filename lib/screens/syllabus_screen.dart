import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/data/official_syllabus.dart';
import '../core/data/syllabus_tree.dart';
import '../models/exam_models.dart';

class SyllabusScreen extends StatelessWidget {
  final CourseProfile course;

  const SyllabusScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final official = OfficialSyllabus.supports(course);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(title: Text('${course.name} Syllabus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: official
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  official
                      ? 'SOURCE-VERIFIED TOPIC LIST'
                      : 'PRACTICE TOPIC MAP',
                  style: TextStyle(
                    color: official
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  official
                      ? '${course.blueprintVersion} • 40 topics per subject'
                      : 'This outline must be checked against the latest official notice before exam day.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                if (official) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(OfficialSyllabus.sourceUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('OPEN OFFICIAL SOURCE'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...course.subjectOrder.map((subject) {
            final officialTopics = OfficialSyllabus.topicsFor(course, subject);
            final topics = officialTopics.isNotEmpty
                ? officialTopics
                : SyllabusTree.getAllTopics(subject)
                    .map((topic) => topic.nameEn)
                    .toList();
            return Card(
              color: const Color(0xFF1E293B),
              child: ExpansionTile(
                iconColor: const Color(0xFF38BDF8),
                collapsedIconColor: Colors.white54,
                title: Text(
                  subject.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${topics.length} topics',
                  style: const TextStyle(color: Colors.white54),
                ),
                children: [
                  for (var index = 0; index < topics.length; index++)
                    ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF334155),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ),
                      title: Text(
                        topics[index],
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
