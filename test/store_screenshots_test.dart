import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikshapul/main.dart';
import 'package:shikshapul/models/exam_models.dart';
import 'package:shikshapul/screens/course_selection_screen.dart';
import 'package:shikshapul/screens/dashboard_screen.dart';
import 'package:shikshapul/screens/preparation_guide_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 1920);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('store screenshot course selection', (tester) async {
    await tester.pumpWidget(const ShikshaPulApp());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CourseSelectionScreen),
      matchesGoldenFile('goldens/01_choose_exam.png'),
    );
  });

  testWidgets('store screenshot preparation dashboard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: DashboardScreen(course: courseProfiles.first),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/02_dashboard.png'),
    );
  });

  testWidgets('store screenshot study strategy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: PreparationGuideScreen(course: courseProfiles.first),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(PreparationGuideScreen),
      matchesGoldenFile('goldens/03_study_strategy.png'),
    );
  });
}
