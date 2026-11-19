import 'dart:ui' show ImageFilter;

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

  Future<void> _fetchDecks() async {
    final decks = await DeckController.loadDecks();
    if (!mounted) return;
    setState(() {
      _decks = decks;
      _isLoading = false;
    });
  }

  /// Recarga los mazos (por si cambiaron en la otra pestaña) y abre la selección.
  Future<void> _openMode(StudyMode mode) async {
    await _fetchDecks();
    if (!mounted || _decks.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectDecksForStudyScreen(mode: mode, decks: _decks),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KEY_MEMORIZE'.loc)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final modes = _buildModeList();
    if (_decks.isNotEmpty) return modes;

    // Sin mazos: se ve la misma pantalla de siempre, pero desenfocada y sin
    // poder usarse, con el aviso justo delante.
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: modes,
              ),
            ),
          ),
        ),
        Positioned.fill(child: _buildNoDecksNotice()),
      ],
    );
  }

  Widget _buildModeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: StudyMode.values.length,
      itemBuilder: (context, index) {
        final mode = StudyMode.values[index];
        return StudyModeTile(mode: mode, onTap: () => _openMode(mode));
      },
    );
  }

  /// Mensaje centrado de "no hay mazos" con el botón que lleva a crear uno.
  Widget _buildNoDecksNotice() {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280), // ancho máximo del cuadro
          child: Material(
            color: scheme.surface,
            elevation: 6,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20), // margen interior
              child: Column(
                mainAxisSize: MainAxisSize.min, // solo lo que ocupa el contenido
                children: [
                  Icon(Icons.folder_open_outlined, size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'KEY_NO_DECKS'.loc,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        BottomNavScreen.of(context)?.openDecks(createDeck: true),
                    icon: const Icon(Icons.add),
                    label: Text('KEY_GO_TO_CREATE_DECK'.loc),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
