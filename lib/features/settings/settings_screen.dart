import 'package:memorio/barrel_file.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KEY_SETTINGS'.loc),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tarjeta o ListTile de Ajuste de Idioma
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language, color: Colors.indigo),
              ),
              title: Text(
                'KEY_LANGUAGE'.loc,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                // Muestra el idioma actual de forma amigable
                LocalizationService.instance.currentLanguage == 'ES'
                    ? 'Español'
                    : 'English',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: PopupMenuButton<String>(
                initialValue: LocalizationService.instance.currentLanguage,
                onSelected: (String newLang) {

                  LocalizationService.instance.changeLanguage(newLang);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'ES',
                    child: Text('Español (ES)'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ENG',
                    child: Text('English (ENG)'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LocalizationService.instance.currentLanguage,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}