import 'package:flutter/material.dart';
import 'screens/movie_list_screen.dart';
import 'services/theme_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeController _themeController = ThemeController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Cinema Scraper',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: _themeController.appTheme == AppTheme.neon
              ? ThemeData(
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: const Color(0xFF050505), // Deep Atmospheric Black
                  primaryColor: const Color(0xFFFF6EC7), // Neon Pink
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFFFF6EC7), // Neon Pink
                    secondary: Color(0xFFFFFF33), // Electric Yellow
                    tertiary: Color(0xFF00FFFF), // Bright Cyan Blue
                    surface: Color(0xFF050505),
                    background: Color(0xFF050505),
                    onPrimary: Colors.black,
                    onSecondary: Colors.black,
                    onSurface: Color(0xFFE0E0E0), // Slightly off-white for readability
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF050505),
                    foregroundColor: Color(0xFFFF6EC7), // Neon Pink text
                    elevation: 0,
                    titleTextStyle: TextStyle(
                      color: Color(0xFFFF6EC7),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier', // Monospace for retro feel (if available, or default)
                      letterSpacing: 1.5,
                    ),
                    iconTheme: IconThemeData(color: Color(0xFFFFFF33)), // Yellow icons
                  ),
                  textTheme: const TextTheme(
                    headlineLarge: TextStyle(
                      color: Color(0xFFFF6EC7), // Pink
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    headlineMedium: TextStyle(
                      color: Color(0xFFFFFF33), // Yellow
                      fontWeight: FontWeight.bold,
                    ),
                    bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
                    bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
                  ),
                  dividerTheme: const DividerThemeData(
                    color: Color(0xFF00FFFF), // Cyan dividers
                    thickness: 1.5,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFFFF6EC7), // Pink text
                      shadowColor: const Color(0xFFFF6EC7),
                      elevation: 5,
                      side: const BorderSide(color: Color(0xFFFF6EC7), width: 2), // Pink neon border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00FFFF), // Cyan text
                      side: const BorderSide(color: Color(0xFF00FFFF), width: 2), // Cyan border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  iconTheme: const IconThemeData(
                    color: Color(0xFFFFFF33), // Yellow icons
                    size: 26,
                  ),
                  cardTheme: CardThemeData(
                    color: const Color(0xFF121212), // Slightly lighter black for cards
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF00FFFF), width: 1), // Cyan border for cards
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF00FFFF).withOpacity(0.4), // Cyan glow
                  ),
                  useMaterial3: true,
                )
              : ThemeData(
                  primarySwatch: Colors.blue,
                  useMaterial3: true,
                  brightness: Brightness.dark,
                ),
          themeMode: _themeController.themeMode,
          home: MovieListScreen(themeController: _themeController),
        );
      },
    );
  }
}
