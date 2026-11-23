import 'package:memorio/barrel_file.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => BottomNavScreenState();

  static BottomNavScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<BottomNavScreenState>();
}

class BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  /// Pide abrir el diálogo de crear mazo al mostrar la pestaña de mazos.
  /// Se consume una sola vez (al abrirse), para no repetirse al cambiar de pestaña.
  bool _pendingCreateDeck = false;

  /// Abre la pestaña de mazos. Con [createDeck] abre además el menú de crear mazo.
  void openDecks({bool createDeck = false}) {
    setState(() {
      _pendingCreateDeck = createDeck;
      _currentIndex = 0;
    });
  }

  void openMemorize() {
    setState(() => _currentIndex = 1);
  }

  void openSettings() {
    setState(() => _currentIndex = 2);
  }

  Widget _screenAt(int index) {
    switch (index) {
      case 0:
        return DecksScreen(
          openCreateDialogOnStart: _pendingCreateDeck,
          onCreateDialogRequestHandled: () => _pendingCreateDeck = false,
        );
      case 1:
        return const MemorizeScreen();
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screenAt(_currentIndex),
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          _BarItem(
            icon: Icons.style_outlined,
            activeIcon: Icons.style,
            label: 'KEY_DECKS'.loc,
          ),
          _BarItem(
            icon: Icons.psychology_outlined,
            activeIcon: Icons.psychology,
            label: 'KEY_MEMORIZE'.loc,
          ),
          _BarItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'KEY_SETTINGS'.loc,
          ),
        ],
      ),
    );
  }
}

// ============================ Barra inferior ============================

class _BarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _BarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Barra de navegación propia: la pestaña activa lleva un círculo iluminado
/// detrás del icono, como si estuviera pulsada, para que se vea de un vistazo.
class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_BarItem> items;

  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainer,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BarButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final _BarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _BarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  /// Diámetro del círculo que se ilumina detrás del icono.
  static const double _circle = 46;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        radius: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: _circle,
              height: _circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Mismo aspecto que un círculo pulsado, pero fijo mientras la
                // pestaña está activa.
                color: selected
                    ? scheme.primary.withValues(alpha: 0.20)
                    : Colors.transparent,
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
