import '../../models/exam_models.dart';

class ExamResource {
  final String title;
  final String publisher;
  final String kind;
  final String url;
  final String note;
  final bool official;
  final Set<ExamType> exams;

  const ExamResource({
    required this.title,
    required this.publisher,
    required this.kind,
    required this.url,
    required this.note,
    required this.official,
    required this.exams,
  });
}

class ExamResources {
  static const all = <ExamResource>[
    ExamResource(
      title: 'BE/B.Arch Entrance 2083 Downloads',
      publisher: 'Institute of Engineering, Tribhuvan University',
      kind: 'OFFICIAL SYLLABUS & NOTICES',
      url: 'https://ioe.tu.edu.np/downloads',
      note:
          'Use the updated 2083 detailed syllabus and latest notices. The page does not certify third-party EPCM sets as past papers.',
      official: true,
      exams: {ExamType.ioe},
    ),
    ExamResource(
      title: 'KUCAT-CBT Test Syllabus 2026',
      publisher: 'Kathmandu University',
      kind: 'OFFICIAL SYLLABUS',
      url: 'https://apply.ku.edu.np/syllabi/2026/Test_Syllabus_2026.pdf',
      note:
          'Authoritative subject list and adaptive-test blueprint for KUCAT PCM/PCB.',
      official: true,
      exams: {ExamType.ku, ExamType.kuPcb},
    ),
    ExamResource(
      title: 'Bachelor Programme Revised Syllabus',
      publisher: 'Medical Education Commission',
      kind: 'OFFICIAL SYLLABUS',
      url:
          'https://mec.gov.np/uploads/shares/curriculumn/syllabus_bachelor_program_revised_final_2082-05-02.pdf',
      note:
          'Check the exact programme mapping and current admission notice before using any practice blueprint.',
      official: true,
      exams: {ExamType.meceeBl},
    ),
    ExamResource(
      title: 'School of Engineering Entrance Portal',
      publisher: 'Pokhara University',
      kind: 'OFFICIAL PORTAL & MODEL QUESTION',
      url: 'https://soeentrance.pu.edu.np/',
      note:
          'The official portal publishes the current syllabus and its Model Question for Entrance.',
      official: true,
      exams: {ExamType.pu},
    ),
    ExamResource(
      title: 'nET Model Question',
      publisher: 'Nepal Engineering College',
      kind: 'INSTITUTIONAL MODEL QUESTION',
      url: 'https://entrance.nec.edu.np/',
      note:
          'A college-published model set. It is useful practice, but it is not an IOE or KU past paper.',
      official: false,
      exams: {ExamType.ioe, ExamType.pu, ExamType.pou},
    ),
    ExamResource(
      title: 'BE/B.Arch Entrance Model Question 2026',
      publisher: 'Purbanchal University',
      kind: 'OFFICIAL PORTAL & MODEL QUESTION',
      url: 'https://entrance.puexam.edu.np/',
      note:
          'The university entrance portal lists the 2026 syllabus, model question, notices, and scholarship procedure.',
      official: true,
      exams: {ExamType.pou},
    ),
    ExamResource(
      title: 'IOE Entrance Model Sets',
      publisher: 'National College of Engineering',
      kind: 'COLLEGE PRACTICE SETS',
      url: 'https://nce.edu.np/nce-mock-test/',
      note:
          'Dated practice sets with answer keys from a TU-affiliated college. Do not treat them as authenticated past IOE papers.',
      official: false,
      exams: {ExamType.ioe},
    ),
  ];

  static List<ExamResource> forExam(ExamType exam) =>
      all.where((resource) => resource.exams.contains(exam)).toList();
}
