import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Qué tarjetas se ven en el mazo.
enum _CardFilter { all, complete, incomplete }

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;
  final VoidCallback onDeckUpdated;

  /// Abre el editor de una tarjeta nueva nada más entrar (al crear un mazo).
  final bool startWithNewCard;

  const DeckDetailScreen({
    super.key,
    required this.deck,
    required this.onDeckUpdated,
    this.startWithNewCard = false,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  static const int _minColumns = 2;
  static const double _targetCardWidth = 190;

  String _query = '';
  _CardFilter _filter = _CardFilter.all;

  /// Tarjetas marcadas en el modo selección (vacío = modo selección apagado).
  final Set<String> _selectedIds = {};

  Deck get _deck => widget.deck;

  @override
  void initState() {
    super.initState();
    if (widget.startWithNewCard) {
      // Se espera al primer frame: no se puede navegar durante initState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCardEditor();
      });
    }
  }

  bool get _selecting => _selectedIds.isNotEmpty;

  bool get _allVisibleSelected {
    final visible = _visibleCards;
    return visible.isNotEmpty && visible.every((c) => _selectedIds.contains(c.id));
  }

  /// Busca en el nombre (front) y en la respuesta (back), y aplica el filtro.
  List<CardModel> get _visibleCards => _deck.cards
      .where((c) => matchesSearch(_query, [c.front, c.back]))
      .where((c) => switch (_filter) {
            _CardFilter.all => true,
            _CardFilter.complete => c.isUsable,
            _CardFilter.incomplete => !c.isUsable,
          })
      .toList();

  /// Abre el editor de tarjeta: crea si [card] es null, edita si no.
  Future<void> _openCardEditor({CardModel? card}) async {
    final result = await Navigator.push<CardEditResult>(
      context,
      MaterialPageRoute(
        // La ruta nueva no hereda el estilo del mazo: se vuelve a aplicar.
        builder: (_) => DeckLookScope.forDeck(
          _deck,
          child: CardEditScreen(
            card: card,
            frontLabel: _deck.effectiveFrontLabel,
            backLabel: _deck.backLabel,
          ),
        ),
      ),
    );
    if (result == null) return;

    // Los rótulos de anverso y reverso son de todo el mazo: si cambian, cambian
    // en todas las tarjetas.
    final newFront = result.frontLabel.isEmpty ? _deck.title : result.frontLabel;
    if (newFront != _deck.effectiveFrontLabel) {
      await DeckController.updateFrontLabel(_deck, result.frontLabel);
    }
    if (result.backLabel != _deck.backLabel) {
      await DeckController.updateBackLabel(_deck, result.backLabel);
    }

    if (card == null) {
      await DeckController.addCardToDeck(_deck, result.card);
    } else {
      await DeckController.updateCardInDeck(_deck, result.card);
    }
    _refresh();
  }

  /// Abre los ajustes del mazo (nombre, rótulos, color y estilo).
  Future<void> _openDeckSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => DeckEditScreen(deck: _deck)),
    );
    _refresh();
  }

  // ------------------------- Selección y borrado -------------------------

  void _toggleSelected(CardModel card) {
    setState(() {
      if (!_selectedIds.remove(card.id)) _selectedIds.add(card.id);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  void _toggleAllVisible() {
    setState(() {
      if (_allVisibleSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_visibleCards.map((c) => c.id));
      }
    });
  }

  /// Elimina una tarjeta, previa confirmación.
  Future<void> _deleteCard(CardModel card) async {
    final confirmed = await confirmDelete(
      context,
      title: 'KEY_DELETE_CARD_TITLE'.loc,
      message: 'KEY_DELETE_CARD_MSG'
          .loc
          .fill({'name': card.front}),
    );
    if (!confirmed || !mounted) return;

    await DeckController.deleteCardFromDeck(_deck, card.id);
    _selectedIds.remove(card.id);
    _refresh();
  }

  /// Elimina las tarjetas marcadas, previa confirmación.
  Future<void> _deleteSelected() async {
    final ids = Set<String>.of(_selectedIds);

    final confirmed = await confirmDelete(
      context,
      title: 'KEY_DELETE_CARDS_TITLE'
          .loc
          .fill({'count': ids.length}),
      message: 'KEY_DELETE_CARDS_MSG'
          .loc
          .fill({'count': ids.length}),
    );
    if (!confirmed || !mounted) return;

    await DeckController.deleteCardsFromDeck(_deck, ids);
    _selectedIds.clear();
    _refresh();
  }

  void _refresh() {
    if (mounted) setState(() {});
    widget.onDeckUpdated();
  }

  @override
  Widget build(BuildContext context) {
    // Con el modo selección activo, "atrás" lo cierra en vez de salir.
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting
            ? SelectionAppBar(
                count: _selectedIds.length,
                allSelected: _allVisibleSelected,
                onClose: _clearSelection,
                onToggleAll: _toggleAllVisible,
                onDelete: _deleteSelected,
              )
            : AppBar(
                title: Text(_deck.title),
                actions: [
                  // Botón con texto: lápiz + "Estilo".
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: Text('KEY_STYLE'.loc),
                      onPressed: _openDeckSettings,
                    ),
                  ),
                ],
              ),
        // Miniaturas del mazo con SU estilo y color.
        body: DeckLookScope.forDeck(_deck, child: _buildBody()),
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton(
                onPressed: () => _openCardEditor(),
                child: const Icon(Icons.add),
              ),
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
        AppSearchBar(
          hintText: 'KEY_SEARCH_CARDS'.loc,
          // Al buscar se limpia la selección: así nunca se borra algo oculto.
          onChanged: (value) => setState(() {
            _query = value;
            _selectedIds.clear();
          }),
        ),
        _buildFilter(),
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

  /// Filtro bajo el buscador: todas, solo las completas (las que se estudian) o
  /// solo las incompletas (sin palabra o sin respuesta).
  Widget _buildFilter() {
    final incomplete = _deck.incompleteCount;
    final complete = _deck.cards.length - incomplete;

    Widget chip(_CardFilter value, String label, {IconData? icon, Color? color}) {
      return ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 18, color: color),
        label: Text(label),
        selected: _filter == value,
        showCheckmark: false,
        onSelected: (_) => setState(() {
          _filter = value;
          _selectedIds.clear();
        }),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        children: [
          chip(_CardFilter.all,
              '${'KEY_FILTER_ALL'.loc} (${_deck.cards.length})'),
          const SizedBox(width: 8),
          chip(
            _CardFilter.complete,
            '${'KEY_FILTER_COMPLETE'.loc} ($complete)',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          chip(
            _CardFilter.incomplete,
            '${'KEY_FILTER_INCOMPLETE'.loc} ($incomplete)',
            icon: Icons.warning_amber_rounded,
            color: Colors.redAccent,
          ),
        ],
      ),
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
            childAspectRatio: 0.66, // tarjeta alta (más estirada)
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return CardGridItem(
              card: card,
              selectionMode: _selecting,
              selected: _selectedIds.contains(card.id),
              onTap: () =>
                  _selecting ? _toggleSelected(card) : _openCardEditor(card: card),
              onLongPress: () => _toggleSelected(card),
              onDelete: () => _deleteCard(card),
            );
          },
        );
      },
    );
  }
}
