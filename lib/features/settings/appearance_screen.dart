import 'package:memorio/barrel_file.dart';

/// Tema de la app: claro / oscuro / sistema, color de acento, negro AMOLED
/// y una tarjeta de vista previa que cambia en directo.
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
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('KEY_AMOLED'.loc),
                subtitle: Text('KEY_AMOLED_DESC'.loc),
                // Solo tiene efecto si puede salir el tema oscuro.
                value: theme.amoled,
                onChanged: theme.mode == ThemeMode.light ? null : theme.setAmoled,
              ),
              const SizedBox(height: 20),
              _SectionLabel('KEY_PREVIEW'.loc),
              const Center(child: _CardPreview()),
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

/// Mini tarjeta para ver cómo quedan los colores del tema elegido.
class _CardPreview extends StatelessWidget {
  const _CardPreview();

  @override
  Widget build(BuildContext context) {
    final ink = context.cardPalette.ink;

    return SizedBox(
      width: 230,
      child: CardSurface(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Memorio',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ink),
            ),
            const SizedBox(height: 14),
            const CardDivider(),
            const SizedBox(height: 14),
            const HintBadge(size: 38),
            const SizedBox(height: 10),
            CardCaption('KEY_HINT'.loc),
          ],
        ),
      ),
    );
  }
}
