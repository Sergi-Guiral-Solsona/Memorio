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
    if (_decks.isEmpty) {
      return EmptyStateView(
        icon: Icons.folder_open_outlined,
        title: 'KEY_NO_DECKS'.loc,
        actionLabel: 'KEY_GO_TO_CREATE_DECK'.loc,
        actionIcon: Icons.arrow_back,
        onAction: () => BottomNavScreen.of(context)?.openDecks(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: StudyMode.values.length,
      itemBuilder: (context, index) {
        final mode = StudyMode.values[index];
        return StudyModeTile(mode: mode, onTap: () => _openMode(mode));
      },
    );
  }
}
