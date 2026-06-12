import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'device_provider.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/song_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(450, 900));
    await windowManager.setMinimumSize(const Size(450, 500));
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => DeviceProvider(),
      child: const StompboxApp(),
    ),
  );
}

class StompboxApp extends StatelessWidget {
  const StompboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stompbox Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1c56f3),
          surface: Color(0xFF1a1a1a),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1c56f3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1a1a1a),
          selectedItemColor: Color(0xFF1c56f3),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const _MainShell(),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _tab = 0;
  int _lastSongLoadCount = 0;

  static const _screens = [
    ScanScreen(),
    SettingsScreen(),
    SongScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<DeviceProvider>().addListener(_onProviderChange);
  }

  @override
  void dispose() {
    context.read<DeviceProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    final p = context.read<DeviceProvider>();
    if (p.songLoadCount != _lastSongLoadCount) {
      _lastSongLoadCount = p.songLoadCount;
      setState(() => _tab = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bluetooth), label: 'Connect'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note), label: 'Song'),
        ],
      ),
    );
  }
}
