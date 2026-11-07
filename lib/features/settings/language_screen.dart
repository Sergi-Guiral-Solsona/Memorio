import 'package:memorio/barrel_file.dart';

/// Lista de idiomas (salen del CSV), cada uno con su nombre en su propio
/// idioma, con buscador.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _query = '';

  List<AppLanguage> get _filtered => LocalizationService.instance.languages
      .where((l) => matchesSearch(_query, [l.nativeName, l.code]))
      .toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = LocalizationService.instance.currentLanguage;
    final languages = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text('KEY_LANGUAGE'.loc)),
      body: Column(
        children: [
          AppSearchBar(onChanged: (value) => setState(() => _query = value)),
          Expanded(
            child: languages.isEmpty
                ? EmptyStateView(icon: Icons.search_off, title: 'KEY_NO_RESULTS'.loc)
                : ListView.builder(
                    itemCount: languages.length,
                    itemBuilder: (context, i) {
                      final lang = languages[i];
                      final selected = lang.code == current;
                      return ListTile(
                        title: Text(
                          lang.nativeName, // siempre en su idioma original
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(lang.code.toUpperCase()),
                        trailing: selected
                            ? Icon(Icons.check_circle, color: scheme.primary)
                            : null,
                        onTap: () async {
                          await LocalizationService.instance.changeLanguage(lang.code);
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
