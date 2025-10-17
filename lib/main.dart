import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/story_screen.dart';
import 'screens/phrasebook_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/location_service.dart';
import 'services/api_service.dart';
import 'services/llm_service.dart';
import 'services/tts_service.dart';
import 'services/history_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final locationService = LocationService();
  final apiService = ApiService();
  final llmService = LlmService();
  final ttsService = TtsService();
  final historyService = HistoryService();

  await historyService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locationService),
        ChangeNotifierProvider(create: (_) => apiService),
        ChangeNotifierProvider(create: (_) => llmService),
        ChangeNotifierProvider(create: (_) => ttsService),
        ChangeNotifierProvider(create: (_) => historyService),
      ],
      child: const CulturaApp(),
    ),
  );
}

class CulturaApp extends StatelessWidget {
  const CulturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cultura - Cultural Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/stories': (context) => const StoryScreen(),
        '/phrases': (context) => const PhrasebookScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}