import 'package:memorio/barrel_file.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'KEY_THEME_SYSTEM'.loc;
      case ThemeMode.light:
        return 'KEY_THEME_LIGHT'.loc;
      case ThemeMode.dark:
        return 'KEY_THEME_DARK'.loc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Se redibuja al cambiar de idioma o de tema.
    return ListenableBuilder(
      listenable: Listenable.merge([
        LocalizationService.instance,
        ThemeService.instance,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text('KEY_SETTINGS'.loc)),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SettingsButton(
                icon: Icons.language,
                color: scheme.primary,
                title: 'KEY_LANGUAGE'.loc,
                trailingText: LocalizationService.instance.currentLanguage.toUpperCase(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
              ),
              SettingsButton(
                icon: Icons.palette_outlined,
                color: scheme.tertiary,
                title: 'KEY_APPEARANCE'.loc,
                trailingText: _themeModeLabel(ThemeService.instance.mode),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                ),
              ),
              SettingsButton(
                icon: Icons.file_download_outlined,
                color: scheme.secondary,
                title: 'KEY_IMPORT_DECKS'.loc,
                onTap: () => importDecksFlow(context),
              ),
              SettingsButton(
                icon: Icons.file_upload_outlined,
                color: scheme.primary,
                title: 'KEY_EXPORT_DECKS'.loc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeckExportScreen()),
                ),
              ),
              // Futuros botones: SettingsButton(...)
            ],
          ),
        );
      },
    );
  }
}

/// Botón reutilizable de la lista de ajustes.
class SettingsButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const SettingsButton({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trailingText!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
