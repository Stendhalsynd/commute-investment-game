import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/game_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CommuteInvestmentApp(),
    ),
  );
}

class CommuteInvestmentApp extends StatelessWidget {
  const CommuteInvestmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '출퇴근길 재테크',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E88E5),
        useMaterial3: true,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
