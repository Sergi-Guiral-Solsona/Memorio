import 'package:memorio/barrel_file.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => BottomNavScreenState();

  static BottomNavScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<BottomNavScreenState>();
}

class BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  void openDecks() {
    setState(() => _currentIndex = 0);
  }

  void openMemorize() {
    setState(() => _currentIndex = 1);
  }

  void openSettings() {
    setState(() => _currentIndex = 2);
  }

  final List<Widget> _screens = const [
    DecksScreen(),
    MemorizeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.style_outlined),
            activeIcon: const Icon(Icons.style),
            label: 'KEY_DECKS'.loc,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.psychology_outlined),
            activeIcon: const Icon(Icons.psychology),
            label: 'KEY_MEMORIZE'.loc,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: 'KEY_SETTINGS'.loc,
          ),
        ],
      ),
    );
  }
}