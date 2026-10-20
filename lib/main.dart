import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/study_screen.dart';
import 'screens/work_screen.dart';
import 'services/app_state.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final appState = AppState(LocalStorageService(preferences));
  await appState.initialize();
  runApp(LifeManagerApp(appState: appState));
}

class LifeManagerApp extends StatefulWidget {
  const LifeManagerApp({super.key, this.appState});

  final AppState? appState;

  @override
  State<LifeManagerApp> createState() => _LifeManagerAppState();
}

class _LifeManagerAppState extends State<LifeManagerApp> {
  late final AppState _appState = widget.appState ?? AppState.inMemory();

  static const Color _seedColor = Color(0xFF9AE66E);
  static const Color _accentColor = Color(0xFFB39DFF);

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
      secondary: _accentColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _appState,
      child: MaterialApp(
        title: 'Life Manager',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const MainNavigationScreen(),
          '/home': (context) => const HomeScreen(),
          '/study': (context) => const StudyScreen(),
          '/work': (context) => const WorkScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }

  @override
  void dispose() {
    if (widget.appState == null) _appState.dispose();
    super.dispose();
  }
}
