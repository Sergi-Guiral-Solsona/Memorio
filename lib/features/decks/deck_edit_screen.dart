import 'dart:async';
import 'package:memorio/barrel_file.dart';

/// Edita los ajustes de UN mazo: nombre, rótulos del anverso y del reverso,
/// color, modelo y borde de tarjeta. Se abre desde el lápiz de la lista de
/// mazos y desde dentro del mazo. No tiene botón de guardar: cada cambio se
/// guarda solo (con [DeckController]) al tocar una opción o al escribir.
class DeckEditScreen extends StatefulWidget {
  final Deck deck;

  const DeckEditScreen({super.key, required this.deck});

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> {
  Deck get _deck => widget.deck;

  late final TextEditingController _title =
      TextEditingController(text: _deck.title);
  late final TextEditingController _frontLabel =
      TextEditingController(text: _deck.effectiveFrontLabel);
  late final TextEditingController _backLabel =
      TextEditingController(text: _deck.backLabel);

  late CardStyle? _style = _deck.cardStyle;
  late AppAccent? _accent = _deck.accent;
  late CardBorder? _border = _deck.border;
  late CardBorderColor? _borderColor = _deck.borderColor;

  /// Mientras el rótulo del anverso no se haya tocado, sigue al nombre del mazo.
  late bool _frontFollowsTitle = _deck.frontLabel.isEmpty;
  bool _syncing = false;

  Timer? _debounce;
  Future<void> _lastSave = Future.value();

  @override
  void initState() {
    super.initState();
    _title.addListener(_onTitleChanged);
    _frontLabel.addListener(_onFrontChanged);
    _backLabel.addListener(_onTextChanged);
  }

  void _onTitleChanged() {
    if (_frontFollowsTitle) {
      _syncing = true;
      _frontLabel.text = _title.text;
      _syncing = false;
    }
    _onTextChanged();
  }

  void _onFrontChanged() {
    if (_syncing) return;
    final text = _frontLabel.text.trim();
    _frontFollowsTitle = text.isEmpty || text == _title.text.trim();
    _onTextChanged();
  }

  /// Texto escrito: se actualiza la vista previa y se guarda poco después.
  void _onTextChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _persist);
  }

  /// Cambio de una opción (estilo, color, borde): se guarda al momento.
  void _set(VoidCallback change) {
    setState(change);
    _persist();
  }

  /// Guarda lo que hay ahora en pantalla. Los guardados se encadenan para que
  /// nunca se pisen entre sí.
  void _persist() {
    _debounce?.cancel();
    final title = _title.text;
    final front = _frontFollowsTitle ? '' : _frontLabel.text;
    final back = _backLabel.text;
    final style = _style, accent = _accent;
    final border = _border, borderColor = _borderColor;

    _lastSave = _lastSave.then((_) => DeckController.updateDeckSettings(
          _deck,
          title: title,
          frontLabel: front,
          backLabel: back,
          cardStyle: style,
          accent: accent,
          border: border,
          borderColor: borderColor,
        ));
  }

  @override
  void dispose() {
    // Lo que quede pendiente de escribir se guarda al salir.
    if (_debounce?.isActive ?? false) _persist();
    _title.dispose();
    _frontLabel.dispose();
    _backLabel.dispose();
    super.dispose();
  }

  /// Rótulo del anverso tal y como saldrá en la tarjeta.
  String get _previewFront {
    final text = _frontLabel.text.trim();
    if (text.isNotEmpty) return text;
    final name = _title.text.trim();
    return name.isEmpty ? _deck.title : name;
  }

  String get _previewBack {
    final text = _backLabel.text.trim();
    return text.isEmpty ? 'KEY_ANSWER'.loc : text;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sample = _deck.cards.isEmpty ? null : _deck.cards.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('KEY_EDIT_DECK_STYLE'.locOr('Editar estilo de mazo', 'Edit deck style')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ---- Vista previa con el estilo y el color elegidos ----
            DeckLookScope(
              style: _style,
              accent: _accent,
              border: _border,
              borderColor: _borderColor,
              child: _Preview(
                frontLabel: _previewFront,
                backLabel: _previewBack,
                frontText: sample?.front ?? 'Apple',
                backText: sample?.back ?? 'Manzana',
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel('KEY_DECK_NAME'.loc),
            TextField(
              controller: _title,
              textCapitalization: kAutoCapitalization,
              decoration: InputDecoration(
                hintText: 'KEY_DECK_NAME'.loc,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            _SectionLabel(
                'KEY_CARD_LABELS'.locOr('Rótulos de la tarjeta', 'Card labels')),
            TextField(
              controller: _frontLabel,
              textCapitalization: kAutoCapitalization,
              decoration: InputDecoration(
                labelText: 'KEY_FRONT_LABEL'.locOr('Anverso', 'Front'),
                hintText: _title.text.trim().isEmpty ? _deck.title : _title.text.trim(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _backLabel,
              textCapitalization: kAutoCapitalization,
              decoration: InputDecoration(
                labelText: 'KEY_BACK_LABEL'.locOr('Reverso', 'Back'),
                hintText: 'KEY_ANSWER'.loc,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'KEY_SHARED_LABELS'.locOr(
                'Los rótulos del anverso y del reverso son comunes a todo el mazo',
                'The front and back labels are shared by the whole deck',
              ),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 28),

            _SectionLabel('KEY_ACCENT_COLOR'.loc),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _DefaultDot(
                  selected: _accent == null,
                  onTap: () => _set(() => _accent = null),
                ),
                for (final accent in AppAccent.values)
                  _ColorDot(
                    accent: accent,
                    selected: accent == _accent,
                    onTap: () => _set(() => _accent = accent),
                  ),
              ],
            ),
            const SizedBox(height: 28),

            _SectionLabel('KEY_CARD_STYLE'.loc),
            _StyleTile(
              style: null,
              accent: _accent,
              border: _border,
              borderColor: _borderColor,
              selected: _style == null,
              onTap: () => _set(() => _style = null),
            ),
            for (final style in CardStyle.values)
              _StyleTile(
                style: style,
                accent: _accent,
                border: _border,
                borderColor: _borderColor,
                selected: _style == style,
                onTap: () => _set(() => _style = style),
              ),
            const SizedBox(height: 16),

            _SectionLabel('KEY_CARD_BORDER'.locOr('Borde', 'Border')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(
                      'KEY_DECK_DEFAULT'.locOr('Como en Ajustes', 'Same as Settings')),
                  selected: _border == null,
                  onSelected: (_) => _set(() => _border = null),
                ),
                for (final b in CardBorder.values)
                  ChoiceChip(
                    label: Text(b.titleKey.locOr(b.fallbackEs, b.fallbackEn)),
                    selected: _border == b,
                    onSelected: (_) => _set(() => _border = b),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            BorderColorPicker(
              selected: _borderColor,
              onChanged: (c) => _set(() => _borderColor = c),
            ),
            const SizedBox(height: 4),
            Text(
              'KEY_CARD_BORDER_DESC'.locOr(
                'Sin color elegido, el borde usa el color del estilo.',
                'With no colour chosen, the border uses the style colour.',
              ),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),

          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ============================ Vista previa ============================

/// Anverso y reverso de ejemplo con el estilo del contexto (ver [DeckLookScope]).
class _Preview extends StatelessWidget {
  final String frontLabel;
  final String backLabel;
  final String frontText;
  final String backText;

  const _Preview({
    required this.frontLabel,
    required this.backLabel,
    required this.frontText,
    required this.backText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PreviewCard(label: frontLabel, text: frontText, isBack: false),
        const SizedBox(width: 16),
        _PreviewCard(label: backLabel, text: backText, isBack: true),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isBack;
  final double width;
  final double height;
  final double titleSize;
  final double captionSize;

  const _PreviewCard({
    required this.label,
    required this.text,
    required this.isBack,
    this.width = 140,
    this.height = 196,
    this.titleSize = 24,
    this.captionSize = 9,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CardSurface(
        isBack: isBack,
        padding: EdgeInsets.all(width * 0.1),
        radius: 22,
        child: _PreviewContent(
          label: label,
          text: text,
          isBack: isBack,
          titleSize: titleSize,
          captionSize: captionSize,
        ),
      ),
    );
  }
}

class _PreviewContent extends StatelessWidget {
  final String label;
  final String text;
  final bool isBack;
  final double titleSize;
  final double captionSize;

  const _PreviewContent({
    required this.label,
    required this.text,
    required this.isBack,
    required this.titleSize,
    required this.captionSize,
  });

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);
    final title = CardFonts.title(color: face.title, size: titleSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardCaption(label, size: captionSize),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: title,
                ),
                if (!isBack) ...[
                  const SizedBox(height: 10),
                  const CardAccentLine(width: 22),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================ Color ============================

/// "Como en Ajustes": el mazo usa el color global.
class _DefaultDot extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _DefaultDot({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'KEY_DECK_DEFAULT'.locOr('Como en Ajustes', 'Same as Settings'),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerHigh,
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outlineVariant,
              width: selected ? 3 : 1.5,
            ),
          ),
          child: Icon(
            selected ? Icons.check : Icons.brightness_auto_outlined,
            color: scheme.onSurfaceVariant,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accent.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: selected ? 1 : 0,
          child: const Icon(Icons.check, color: Colors.white),
        ),
      ),
    );
  }
}

// ============================ Estilo ============================

/// Un modelo de tarjeta con su anverso y reverso en pequeño. [style] null es
/// "Como en Ajustes".
class _StyleTile extends StatelessWidget {
  final CardStyle? style;
  final AppAccent? accent;
  final CardBorder? border;
  final CardBorderColor? borderColor;
  final bool selected;
  final VoidCallback onTap;

  const _StyleTile({
    required this.style,
    required this.accent,
    required this.border,
    required this.borderColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = style == null
        ? 'KEY_DECK_DEFAULT'.locOr('Como en Ajustes', 'Same as Settings')
        : style!.titleKey.loc;
    final description = style == null
        ? 'KEY_DECK_STYLE_DEFAULT_DESC'.locOr(
            'Usa el modelo elegido en Ajustes > Apariencia',
            'Uses the style chosen in Settings > Appearance',
          )
        : style!.descriptionKey.loc;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  DeckLookScope(
                    style: style,
                    accent: accent,
                    border: border,
                    borderColor: borderColor,
                    child: Row(
                      children: [
                        _mini(isBack: false),
                        const SizedBox(width: 10),
                        _mini(isBack: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                              color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mini({required bool isBack}) {
    return SizedBox(
      width: 56,
      height: 78,
      child: CardSurface(
        isBack: isBack,
        compact: true,
        radius: 10,
        padding: const EdgeInsets.all(7),
        child: _PreviewContent(
          label: isBack ? 'ES' : 'EN',
          text: isBack ? 'Manzana' : 'Apple',
          isBack: isBack,
          titleSize: isBack ? 10 : 13,
          captionSize: 5,
        ),
      ),
    );
  }
}

// ============================ Color del borde ============================

/// Colores neutros para el borde (negro, grises, blanco) y un botón para
/// igualarlo al estilo: [selected] null = el borde toma el color del estilo.
/// Lo usan la pantalla del mazo y Ajustes > Apariencia.
class BorderColorPicker extends StatelessWidget {
  final CardBorderColor? selected;
  final ValueChanged<CardBorderColor?> onChanged;

  const BorderColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matched = selected == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KEY_BORDER_COLOR'.locOr('Color del borde', 'Border colour'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in CardBorderColor.values)
              Tooltip(
                message: c.titleKey.locOr(c.fallbackEs, c.fallbackEn),
                child: GestureDetector(
                  onTap: () => onChanged(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected == c
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: selected == c ? 3 : 1,
                      ),
                    ),
                    child: selected == c
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: ThemeData.estimateBrightnessForColor(c.color) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Igualar: el borde vuelve a tomar el color del estilo.
        OutlinedButton.icon(
          onPressed: matched ? null : () => onChanged(null),
          icon: Icon(matched ? Icons.check : Icons.link_rounded, size: 18),
          label: Text(
            'KEY_BORDER_MATCH'.locOr(
              'Igualar borde y estilo',
              'Match border to style',
            ),
          ),
        ),
      ],
    );
  }
}
