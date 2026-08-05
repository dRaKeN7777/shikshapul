import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/data/exam_resources.dart';
import '../models/exam_models.dart';

class ResourceLibraryScreen extends StatelessWidget {
  final CourseProfile course;

  const ResourceLibraryScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final resources = ExamResources.forExam(course.type);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(title: const Text('Trusted Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _IntegrityNotice(),
          const SizedBox(height: 16),
          for (final resource in resources) _ResourceCard(resource: resource),
          const _EpcmNotice(),
        ],
      ),
    );
  }
}

class _IntegrityNotice extends StatelessWidget {
  const _IntegrityNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: const Text(
          'Official syllabi and institutional model sets are labelled separately. A model set is not called a past paper unless the exam authority authenticates it and reuse permission is recorded.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
      );
}

class _ResourceCard extends StatelessWidget {
  final ExamResource resource;

  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.kind,
                style: TextStyle(
                  color: resource.official
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                resource.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(resource.publisher,
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 10),
              Text(resource.note,
                  style: const TextStyle(color: Colors.white70, height: 1.4)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(resource.url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('OPEN SOURCE'),
              ),
            ],
          ),
        ),
      );
}

class _EpcmNotice extends StatelessWidget {
  const _EpcmNotice();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF451A03).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'About EPCM: use a purchased or otherwise authorized copy. Solve it as an external practice source, record every mistake here, and verify disputed answers with a teacher. This app does not reproduce the copyrighted book or promise repeated exam questions.',
          style: TextStyle(color: Color(0xFFFCD34D), height: 1.45),
        ),
      );
}
