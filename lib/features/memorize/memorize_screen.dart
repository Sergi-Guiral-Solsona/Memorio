import 'package:flutter/material.dart';
import 'package:memorio/barrel_file.dart';

class MemorizeScreen extends StatefulWidget {
  const MemorizeScreen({super.key});

  @override
  State<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends State<MemorizeScreen> {
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  // Carga de mazos para verificar disponibilidad
  Future<void> _fetchDecks() async {
    final loadedDecks = await DeckController.loadDecks();
    setState(() {
      _decks = loadedDecks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lista de métodos/modos de estudio disponibles
    final studyModes = [
      {
        'title': 'KEY_POMODORO'.loc,
        'subtitle': 'KEY_FOCUSED_STUDY'.loc,
        'icon': Icons.timer_outlined,
        'color': Colors.orange,
      },
      {
        'title': 'KEY_RANDOM'.loc,
        'subtitle': 'KEY_RANDOM_CARDS'.loc,
        'icon': Icons.shuffle,
        'color': Colors.purple,
      },
      {
        'title': 'Mi Filtro',
        'subtitle': 'Tus reglas personalizadas de repaso',
        'icon': Icons.filter_list,
        'color': Colors.indigo,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('KEY_MEMORIZE'.loc),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _decks.isEmpty
          ? EmptyDecksMemorizeView()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: studyModes.length,
        itemBuilder: (context, index) {
          final mode = studyModes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (mode['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  mode['icon'] as IconData,
                  color: mode['color'] as Color,
                  size: 28,
                ),
              ),
              title: Text(
                mode['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  mode['subtitle'] as String,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                // Navega a la selección de mazo para la técnica elegida
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectDeckForStudyScreen(
                      studyModeTitle: mode['title'] as String,
                      decks: _decks,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}