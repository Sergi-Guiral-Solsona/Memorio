/// Utilidades de búsqueda reutilizables (decks, tarjetas, idiomas...).

const Map<String, String> _accentMap = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// Minúsculas y sin acentos, para comparar sin importar cómo se escribió.
String normalizeForSearch(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_accentMap[char] ?? char);
  }
  return buffer.toString();
}

/// true si [query] está contenida en alguno de los [fields].
/// Una búsqueda vacía coincide con todo.
bool matchesSearch(String query, Iterable<String> fields) {
  final normalizedQuery = normalizeForSearch(query.trim());
  if (normalizedQuery.isEmpty) return true;
  return fields.any((f) => normalizeForSearch(f).contains(normalizedQuery));
}
