import 'dart:math' as math;
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
  static const int _minColumns = 2;
  static const double _targetCardWidth = 190;

  String _query = '';

  Deck get _deck => widget.deck;

  /// Busca en el nombre (front) y en la respuesta (back).
  List<CardModel> get _visibleCards => _deck.cards
      .where((c) => matchesSearch(_query, [c.front, c.back]))
      .toList();

  /// Abre el editor de tarjeta: crea si [card] es null, edita si no.
  Future<void> _openCardEditor({CardModel? card}) async {
    final result = await Navigator.push<CardModel>(
      context,
      MaterialPageRoute(builder: (_) => CardEditScreen(card: card)),
    );
    if (result == null) return;

    if (card == null) {
      await DeckController.addCardToDeck(_deck, result);
    } else {
      await DeckController.updateCardInDeck(_deck, result);
    }
    _refresh();
  }

  Future<void> _deleteCard(CardModel card) async {
    await DeckController.deleteCardFromDeck(_deck, card.id);
    _refresh();
  }

  void _refresh() {
    if (mounted) setState(() {});
    widget.onDeckUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_deck.title} (${_deck.cards.length})'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCardEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_deck.cards.isEmpty) {
      return EmptyStateView(
        icon: Icons.style_outlined,
        title: 'KEY_NO_CARDS'.loc,
        subtitle: 'KEY_CREATE_FIRST_CARD'.loc,
        actionLabel: 'KEY_CREATE_CARD'.loc,
        onAction: () => _openCardEditor(),
      );
    }

    final visible = _visibleCards;
    return Column(
      children: [
        AppSearchBar(onChanged: (value) => setState(() => _query = value)),
        Expanded(
          child: visible.isEmpty
              ? EmptyStateView(
                  icon: Icons.search_off,
                  title: 'KEY_NO_RESULTS'.loc,
                )
              : _buildGrid(visible),
        ),
      ],
    );
  }

  Widget _buildGrid(List<CardModel> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mínimo 2 por fila; más columnas si la pantalla es ancha.
        final columns = math.max(
          _minColumns,
          (constraints.maxWidth / _targetCardWidth).floor(),
        );
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return CardGridItem(
              card: card,
              onTap: () => _openCardEditor(card: card),
              onDelete: () => _deleteCard(card),
            );
          },
        );
      },
    );
  }
}
