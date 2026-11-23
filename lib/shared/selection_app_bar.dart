import 'package:memorio/barrel_file.dart';

/// Barra superior del modo selección: cerrar, nº de elementos marcados,
/// seleccionar/deseleccionar todos y eliminar los marcados.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int count;
  final bool allSelected;
  final VoidCallback onClose;
  final VoidCallback onToggleAll;
  final VoidCallback onDelete;

  const SelectionAppBar({
    super.key,
    required this.count,
    required this.allSelected,
    required this.onClose,
    required this.onToggleAll,
    required this.onDelete,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      leading: IconButton(
        tooltip: 'KEY_CANCEL'.loc,
        icon: const Icon(Icons.close_rounded),
        onPressed: onClose,
      ),
      title: Text(
        'KEY_SELECTED_COUNT'
            .loc
            .fill({'count': count}),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          tooltip: allSelected
              ? 'KEY_DESELECT_ALL'.loc
              : 'KEY_SELECT_ALL'.loc,
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          onPressed: onToggleAll,
        ),
        IconButton(
          tooltip: 'KEY_DELETE'.loc,
          icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
