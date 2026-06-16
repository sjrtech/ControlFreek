import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_provider.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/song_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterBluePlus.setLogLevel(LogLevel.none, color: false);
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
      title: 'Control Freek',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1c56f3),
          surface: Color(0xFF1a1a1a),
        ),
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        canvasColor: const Color(0xFF0D1B3E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A3A7A),
          foregroundColor: Color(0xFFBCC8DC),
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
  int _tab = 2;
  int _lastSongLoadCount = 0;
  late final PageController _pageController;
  bool _providerListening = false;

  static const _screens = [
    ScanScreen(),
    SettingsScreen(),
    SongScreen(),
  ];

  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providerListening) {
      _providerListening = true;
      context.read<DeviceProvider>().addListener(_onProviderChange);
    }
  }

  @override
  void dispose() {
    context.read<DeviceProvider>().removeListener(_onProviderChange);
    _pageController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final p = context.read<DeviceProvider>();
    if (p.songLoadCount != _lastSongLoadCount) {
      _lastSongLoadCount = p.songLoadCount;
      _setTab(2);
    }
  }

  void _setTab(int index) {
    setState(() => _tab = index);
    if (_isMobile && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _tab = i),
            children: _screens,
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: _setTab,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bluetooth), label: 'Connect'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Setup'),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note), label: 'Song'),
        ],
      ),
    );
  }
}
