import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/album_screen.dart';
import 'screens/community_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/weather_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(TravelDiaryApp(firebaseReady: firebaseReady));
}

class TravelDiaryApp extends StatelessWidget {
  final bool firebaseReady;

  const TravelDiaryApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    const mintPastel = Color(0xFF48A999);
    const rosePastel = Color(0xFFF497B6);
    const bgMintTint = Color(0xFFF2FBF7);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel Diary & Photo Memories',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: mintPastel,
          primary: mintPastel,
          secondary: rosePastel,
          surface: const Color(0xFFFFF8FA),
        ),
        scaffoldBackgroundColor: bgMintTint,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFE4EC),
          foregroundColor: Color(0xFF5A2338),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A2338),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFAF9),
          elevation: 2,
          shadowColor: const Color(0x33F497B6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFF7DCE4), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCDEEE3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF48A999), width: 1.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF48A999),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF48FB1),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: MainNavigationPage(firebaseReady: firebaseReady),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final bool firebaseReady;

  const MainNavigationPage({super.key, required this.firebaseReady});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const TripsScreen(),
      const AlbumScreen(),
      const WeatherScreen(),
      CommunityScreen(firebaseReady: widget.firebaseReady),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF3F7),
              Color(0xFFF1FBF6),
              Color(0xFFE7F7F0),
            ],
          ),
        ),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFFFECF2),
        indicatorColor: const Color(0xFFC8EFE2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Chuyến đi',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Album',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Thời tiết',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Cộng đồng',
          ),
        ],
      ),
    );
  }
}