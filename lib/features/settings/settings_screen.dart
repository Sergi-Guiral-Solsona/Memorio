import 'package:memorio/barrel_file.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return ListenableBuilder(
      listenable: LocalizationService.instance,
      builder: (context, _) {
        final loc = LocalizationService.instance;

        return Scaffold(
          appBar: AppBar(title: Text('KEY_SETTINGS'.loc)),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SettingsButton(
                icon: Icons.language,
                color: Colors.indigo,
                title: 'KEY_LANGUAGE'.loc,

                trailingText: loc.currentLanguage,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
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
