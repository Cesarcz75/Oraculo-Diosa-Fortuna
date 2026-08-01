
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OraculoApp());
}

class OraculoApp extends StatelessWidget {
  const OraculoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF8F4DFF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oráculo Diosa Fortuna',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0610),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1022),
          elevation: 3,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
