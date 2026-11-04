import 'package:memorio/barrel_file.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLanguage> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return LocalizationService.supportedLanguages;
    return LocalizationService.supportedLanguages
        .where((l) =>
            l.nativeName.toLowerCase().contains(q) ||
            l.code.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final current = LocalizationService.instance.currentLanguage;
    final languages = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text('KEY_LANGUAGE'.loc)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'KEY_SEARCH'.loc,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: languages.isEmpty
                ? Center(child: Text('KEY_NO_RESULTS'.loc))
                : ListView.builder(
                    itemCount: languages.length,
                    itemBuilder: (context, i) {
                      final lang = languages[i];
                      final selected = lang.code == current;
                      return ListTile(
                        title: Text(
                          lang.nativeName, // siempre en su idioma original
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(lang.code),
                        trailing: selected
                            ? const Icon(Icons.check_circle, color: Colors.indigo)
                            : null,
                        onTap: () async {
                          await LocalizationService.instance
                              .changeLanguage(lang.code);
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
