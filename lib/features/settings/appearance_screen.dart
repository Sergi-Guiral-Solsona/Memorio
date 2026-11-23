import 'package:memorio/barrel_file.dart';

/// Tema de la app: claro / oscuro / sistema, color de acento, modelo de
/// tarjeta y negro AMOLED. Los cambios se ven al instante.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.instance,
        LocalizationService.instance,
      ]),
      builder: (context, _) {
        final theme = ThemeService.instance;

        return Scaffold(
          appBar: AppBar(title: Text('KEY_APPEARANCE'.loc)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('KEY_THEME'.loc),
              SegmentedButton<ThemeMode>(
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto),
                    label: _SegmentLabel('KEY_THEME_SYSTEM'.loc),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: _SegmentLabel('KEY_THEME_LIGHT'.loc),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: _SegmentLabel('KEY_THEME_DARK'.loc),
                  ),
                ],
                selected: {theme.mode},
                onSelectionChanged: (selection) => theme.setMode(selection.first),
              ),
              const SizedBox(height: 28),
              _SectionLabel('KEY_ACCENT_COLOR'.loc),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final accent in AppAccent.values)
                    _AccentDot(
                      accent: accent,
                      selected: accent == theme.accent,
                      onTap: () => theme.setAccent(accent),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('KEY_AMOLED'.loc),
                subtitle: Text('KEY_AMOLED_DESC'.loc),
                // Solo tiene efecto si puede salir el tema oscuro.
                value: theme.amoled,
                onChanged: theme.mode == ThemeMode.light ? null : theme.setAmoled,
              ),
              const SizedBox(height: 24),
              _SectionLabel('KEY_CARD_STYLE'.loc),
              for (final style in CardStyle.values)
                _CardStyleTile(
                  style: style,
                  selected: style == theme.cardStyle,
                  onTap: () => theme.setCardStyle(style),
                ),
              const SizedBox(height: 12),
              _SectionLabel('KEY_CARD_BORDER'.loc),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('KEY_CARD_BORDER_DEFAULT'
                        .loc),
                    selected: theme.cardBorder == null,
                    onSelected: (_) => theme.setCardBorder(null),
                  ),
                  for (final b in CardBorder.values)
                    ChoiceChip(
                      label: Text(b.titleKey.loc),
                      selected: theme.cardBorder == b,
                      onSelected: (_) => theme.setCardBorder(b),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              BorderColorPicker(
                selected: theme.cardBorderColor,
                onChanged: theme.setCardBorderColor,
              ),
              const SizedBox(height: 6),
              Text(
                'KEY_CARD_BORDER_GLOBAL_DESC'.loc,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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

class _SegmentLabel extends StatelessWidget {
  final String text;

  const _SegmentLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
}

class _AccentDot extends StatelessWidget {
  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({
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

/// Un modelo de tarjeta: vista previa del anverso y del reverso + nombre y descripción.
class _CardStyleTile extends StatelessWidget {
  final CardStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _CardStyleTile({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
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
                  _MiniCard(style: style, isBack: false),
                  const SizedBox(width: 10),
                  _MiniCard(style: style, isBack: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style.titleKey.loc,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          style.descriptionKey.loc,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
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
}

/// Tarjetita de muestra con un estilo concreto (da igual cuál esté elegido).
class _MiniCard extends StatelessWidget {
  final CardStyle style;
  final bool isBack;

  const _MiniCard({required this.style, required this.isBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 94,
      child: CardSurface(
        style: style,
        isBack: isBack,
        compact: true,
        radius: 12,
        padding: const EdgeInsets.all(8),
        child: _MiniContent(isBack: isBack),
      ),
    );
  }
}

class _MiniContent extends StatelessWidget {
  final bool isBack;

  const _MiniContent({required this.isBack});

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);
    final title = CardFonts.title(color: face.title, size: 15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardCaption(isBack ? 'ES' : 'EN', size: 6),
        if (isBack)
          Expanded(
            child: Center(
              child: Text('Manzana', style: title.copyWith(fontSize: 12)),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          Text('Apple', textAlign: TextAlign.center, style: title),
          const SizedBox(height: 5),
          Center(
            child: const CardAccentLine(width: 14),
          ),
        ],
      ],
    );
  }
}
