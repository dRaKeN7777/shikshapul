import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/data/syllabus_tree.dart';
import 'core/data/question_bank.dart';
import 'screens/course_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyllabusTree.init();
  QuestionEngine.init();
  runApp(const ProviderScope(child: ShikshaPulApp()));
}

class ShikshaPulApp extends StatelessWidget {
  const ShikshaPulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShikshaPul: Nepal Entrance AI',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        primaryColor: const Color(0xFF38BDF8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1020),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        useMaterial3: true,
      ),
      home: const CourseSelectionScreen(),
    );
  }
}
