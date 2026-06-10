import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'device_provider.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/song_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  static const _screens = [
    ScanScreen(),
    SettingsScreen(),
    SongScreen(),
  ];

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
