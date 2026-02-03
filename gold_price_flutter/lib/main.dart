import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_provider.dart';
import 'services/gold_provider.dart';
import 'services/portfolio_provider.dart';
import 'services/diary_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GoldProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Gold Price Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            
            // LIGHT THEME
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFf8fafc),
              cardColor: Colors.white,
              primaryColor: const Color(0xFFfbbf24),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFfbbf24),
                secondary: Color(0xFFfbbf24),
                surface: Colors.white,
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Color(0xFF0f172a),
                onSurface: Color(0xFF0f172a),
              ),
              textTheme: GoogleFonts.outfitTextTheme(
                ThemeData.light().textTheme,
              ).apply(
                bodyColor: const Color(0xFF0f172a),
                displayColor: const Color(0xFF0f172a),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: Color(0xFF0f172a),
                centerTitle: true,
                elevation: 0,
              ),
            ),

            // DARK THEME
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0f172a),
              cardColor: const Color(0xFF1e293b),
              primaryColor: const Color(0xFFfbbf24),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFfbbf24),
                secondary: Color(0xFFfbbf24),
                surface: Color(0xFF1e293b),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Color(0xFFf8fafc),
                onSurface: Color(0xFFf8fafc),
              ),
              textTheme: GoogleFonts.outfitTextTheme(
                ThemeData.dark().textTheme,
              ).apply(
                bodyColor: const Color(0xFFf8fafc),
                displayColor: const Color(0xFFf8fafc),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: Color(0xFFf8fafc),
                centerTitle: true,
                elevation: 0,
              ),
            ),
            home: const MainNavigationScreen(),
          );
        }
      ),
    );
  }
}
