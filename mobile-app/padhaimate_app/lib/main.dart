import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PadhaiMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const HomeShell(),
    );
  }
}