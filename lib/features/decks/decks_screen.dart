import 'package:flutter/material.dart';
import 'package:memorio/barrel_file.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  Future<void> _fetchDecks() async {
    final loadedDecks = await DeckController.loadDecks();
    setState(() {
      _decks = loadedDecks;
      _isLoading = false;
    });
  }

  Future<void> _addDeck(String title) async {
    final updatedDecks = await DeckController.addDeck(_decks, title);
    setState(() {
      _decks = updatedDecks;
    });
  }

  Future<void> _editDeck(int index, String newTitle) async {
    final updatedDecks = await DeckController.editDeck(_decks, index, newTitle);
    setState(() {
      _decks = updatedDecks;
    });
  }

  Future<void> _deleteDeck(int index) async {
    final updatedDecks = await DeckController.deleteDeck(_decks, index);
    setState(() {
      _decks = updatedDecks;
    });
  }

  void _showDeckDialog({Deck? deckToEdit, int? index}) {
    final controller = TextEditingController(text: deckToEdit?.title ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deckToEdit == null ? 'KEY_CREATE_DECK'.loc : 'KEY_EDIT_DECK'.loc),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'KEY_DECK_NAME'.loc),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('KEY_CANCEL'.loc),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                if (deckToEdit == null) {
                  _addDeck(text);
                } else if (index != null) {
                  _editDeck(index, text);
                }
                Navigator.pop(context);
              }
            },
            child: Text('KEY_SAVE'.loc),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${'KEY_DECKS'.loc} (${_decks.length})'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _decks.isEmpty
          ? EmptyDecksView(onCreateDeckPressed: () => _showDeckDialog())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _decks.length,
        itemBuilder: (context, index) {
          final deck = _decks[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeckDetailScreen(
                      deck: deck,
                      onDeckUpdated: _fetchDecks,
                    ),
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.style, color: Colors.indigo),
              ),
              title: Text(
                deck.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                    onPressed: () => _showDeckDialog(deckToEdit: deck, index: index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteDeck(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDeckDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}