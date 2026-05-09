import 'package:flutter/material.dart';
import 'ui/tasks_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدير المهام',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF12121F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C6AF7),
        ),
      ),
      home: const TasksScreen(),
    );
  }
}
