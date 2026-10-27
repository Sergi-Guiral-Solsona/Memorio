import 'package:memorio/barrel_file.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;
  final VoidCallback onDeckUpdated;

  const DeckDetailScreen({
    super.key,
    required this.deck,
    required this.onDeckUpdated,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  late Deck _currentDeck;

  @override
  void initState() {
    super.initState();
    _currentDeck = widget.deck;
  }

  Future<void> _addCard(String front, String hint, String back) async {
    final newCard = CardModel(
      id: "0000",
      front: front,
      hint: hint,
      back: back,
    );
    await DeckController.addCardToDeck(_currentDeck, newCard);
    setState(() {});
    widget.onDeckUpdated();
  }

  Future<void> _deleteCard(int index) async {
    await DeckController.deleteCardFromDeck(_currentDeck, index);
    setState(() {});
    widget.onDeckUpdated();
  }
  Future<void> _editCard(int index, String front, String hint, String back) async {
    final cardId = _currentDeck.cards[index].id;
    final updatedCard = CardModel(
      id: cardId,
      front: front,
      hint: hint,
      back: back,
    );

    await DeckController.updateCardInDeck(_currentDeck, updatedCard);

    setState(() {});
    widget.onDeckUpdated();
  }

  void _showAddCardDialog() {
    final frontController = TextEditingController();
    final hintController = TextEditingController();
    final backController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('KEY_CREATE_CARD'.loc),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'KEY_WORD_OR_PHRASE'.loc,
                  hintText: '${'KEY_EXAMPLE_SHORT'.loc} ${'KEY_OCEAN'.loc}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hintController,
                decoration:  InputDecoration(
                  labelText: 'KEY_HINT'.loc,
                  hintText: '${'KEY_EXAMPLE_SHORT'.loc} ${'KEY_BEACH_THING'.loc}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: backController,
                decoration:  InputDecoration(
                  labelText: 'KEY_ANSWER'.loc,
                  hintText: '${'KEY_EXAMPLE_SHORT'.loc} ${'KEY_ANSWER_DEFAULT'.loc}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('KEY_CANCEL'.loc),
          ),
          ElevatedButton(
            onPressed: () {
              final front = frontController.text.trim();
              final hint = hintController.text.trim();
              final back = backController.text.trim();

              if (front.isNotEmpty && back.isNotEmpty) {
                _addCard(front, hint, back);
                Navigator.pop(context);
              }
            },
            child: Text('KEY_SAVE'.loc),
          ),
        ],
      ),
    );
  }

  // --- MÉTODO PARA EDITAR O CREAR TARJETA ---
  void _showCardDialog({dynamic cardToEdit, int? index}) {
    final frontController = TextEditingController(text: cardToEdit?.front ?? '');
    final hintController = TextEditingController(text: cardToEdit?.hint ?? '');
    final backController = TextEditingController(text: cardToEdit?.back ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cardToEdit == null ? 'KEY_CREATE_CARD'.loc : 'KEY_EDIT_CARD'.loc),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'KEY_WORD_OR_PHRASE'.loc,
                  hintText: '${'KEY_EXAMPLE_SHORT'.loc} ${'KEY_OCEAN'.loc}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hintController,
                decoration: InputDecoration(
                  labelText: 'KEY_HINT'.loc,
                  hintText: '${'KEY_EXAMPLE_SHORT'.loc} ${'KEY_BEACH_THING'.loc}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: backController,
                decoration: InputDecoration(
                  labelText: 'KEY_ANSWER'.loc,
                  hintText: '${'KEY_EXAMPLE_SHORT'.loc} ${'KEY_ANSWER_DEFAULT'.loc}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('KEY_CANCEL'.loc),
          ),
          ElevatedButton(
            onPressed: () {
              final front = frontController.text.trim();
              final hint = hintController.text.trim();
              final back = backController.text.trim();

              if (front.isNotEmpty && back.isNotEmpty) {
                if (cardToEdit == null) {
                  _addCard(front, hint, back);
                } else if (index != null) {
                  _editCard(index, front, hint, back);
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
        title: Text('${_currentDeck.title} (${_currentDeck.cards.length})'),
      ),
      body: _currentDeck.cards.isEmpty
          ? Center(
        child: Text('KEY_NO_CARDS'.loc),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentDeck.cards.length,
        itemBuilder: (context, index) {
          final card = _currentDeck.cards[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.front,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (card.hint.isNotEmpty)
                              Text(
                                '💡 ${'KEY_HINT'.loc}: ${card.hint}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '🗣️ ${'KEY_ANSWER'.loc}: ${card.back}',
                              style: const TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                        onPressed: () => _showCardDialog(cardToEdit: card, index: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteCard(index),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 0.5),
                  // --- ESTADÍSTICAS VISUALES DE LA TARJETA ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${card.correctCount}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${card.incorrectCount}',
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}