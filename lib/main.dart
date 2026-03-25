import 'package:flutter/material.dart';
import 'pages/dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // ── Index de la page active ──────────────────────────────────────────────
  int _index = 0;

  // ── Liste des pages ──────────────────────────────────────────────────────
  final List<Widget> _pages = [
    const DashboardPage(), // index 0
    const Center(
      child: Text('Page Citoyens', style: TextStyle(color: Colors.white)),
    ), // index 1
    const Center(
      child: Text('Page Candidats', style: TextStyle(color: Colors.white)),
    ), // index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),

      // ── Affiche la page active ───────────────────────────────────────────
      body: _pages[_index],

      // ── Navbar en bas ────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF111F2E),
        selectedItemColor: const Color(0xFF4FC3F7),
        unselectedItemColor: Colors.white30,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Citoyens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote_rounded),
            label: 'Candidats',
          ),
        ],
      ),
    );
  }
}
