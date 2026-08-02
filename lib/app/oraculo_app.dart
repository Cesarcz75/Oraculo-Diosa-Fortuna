import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';

class OraculoApp extends StatelessWidget {
  const OraculoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color seed = Color(0xFF8F4DFF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oráculo Diosa Fortuna',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0610),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1022),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
