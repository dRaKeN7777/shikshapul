import 'package:flutter_test/flutter_test.dart';
import 'package:shikshapul/core/data/question_bank.dart';
import 'package:shikshapul/core/data/syllabus_tree.dart';
import 'package:shikshapul/main.dart';

void main() {
  testWidgets('app opens to course selection', (tester) async {
    SyllabusTree.init();
    QuestionEngine.init();
    await tester.pumpWidget(const ShikshaPulApp());
    await tester.pumpAndSettle();

    expect(find.text('ShikshaPul'), findsOneWidget);
    expect(find.text('SELECT YOUR EXAM'), findsOneWidget);
    expect(find.text('IOE BE'), findsOneWidget);
  });
}
