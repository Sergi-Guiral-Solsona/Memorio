import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:memorio/barrel_file.dart';

/// Resultado de añadir mazos importados.
class ImportSummary {
  final int decks;
  final int cards;
  const ImportSummary({required this.decks, required this.cards});
}

/// Importar y exportar mazos como un archivo `.json`.
///
/// Formato del archivo:
///
///     {
///       "format": "memorio-decks",
///       "version": 1,
///       "exportedAt": "2026-11-19T10:00:00.000",
///       "decks": [ { ...Deck.toMap()... } ]
///     }
///
/// Al importar NUNCA se modifica ni se sustituye nada de lo que ya hay: los
/// mazos del archivo se AÑADEN como mazos nuevos (con ids nuevos y, si el
/// nombre ya existe, con un sufijo "(2)", "(3)"...).
class DeckTransferService {
  DeckTransferService._();

  static const String formatId = 'memorio-decks';
  static const int formatVersion = 1;

  // ------------------------------ Exportar ------------------------------

  /// Convierte [decks] a texto JSON. Por defecto NO incluye el progreso de
  /// estudio (aciertos, fallos, rachas): así se comparte solo el contenido.
  static String encode(List<Deck> decks, {bool includeProgress = false}) {
    final data = {
      'format': formatId,
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'decks': [
        for (final deck in decks)
          (includeProgress ? deck : _withoutProgress(deck)).toMap(),
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Deck _withoutProgress(Deck deck) => deck.copyWith(
    cards: [
      for (final card in deck.cards) card.copyWith(methodStats: const {}),
    ],
  );

  static String suggestedFileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'memorio_decks_${now.year}-${two(now.month)}-${two(now.day)}.json';
  }

  /// Pide al sistema dónde guardar el archivo y lo escribe.
  /// Devuelve false si la persona cancela.
  static Future<bool> saveToDevice(String content, {String? fileName}) async {
    final bytes = Uint8List.fromList(utf8.encode(content));

    // file_picker 12+: `bytes` es obligatorio y el propio plugin escribe el
    // archivo en todas las plataformas. Devuelve null si se cancela.
    final saved = await FilePicker.saveFile(
      dialogTitle: 'KEY_EXPORT_DECKS'.locOr('Exportar mazos', 'Export decks'),
      fileName: fileName ?? suggestedFileName(),
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    return saved != null;
  }

  // ------------------------------ Importar ------------------------------

  /// Abre el selector y devuelve el texto de cada archivo elegido
  /// (null si se cancela).
  ///
  /// file_picker 12+: `pickFiles()` devuelve la lista directamente (vacía si
  /// se cancela), permite varios archivos por defecto y los bytes se leen con
  /// `readAsBytes()` (ya no existen `withData` ni `allowMultiple`).
  static Future<List<String>?> pickFilesContent() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return null;

    final contents = <String>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      contents.add(utf8.decode(bytes, allowMalformed: true));
    }
    return contents;
  }

  /// Lee los mazos de un texto. Acepta el formato de Memorio, una lista de
  /// mazos o un único mazo. Lanza [FormatException] si no hay nada válido.
  static List<Deck> decode(String source) {
    final clean = source.replaceFirst('\uFEFF', '').trim();
    final dynamic raw = json.decode(clean);

    final List<dynamic> items;
    if (raw is Map && raw['decks'] is List) {
      items = raw['decks'] as List;
    } else if (raw is Map && raw['cards'] is List) {
      items = [raw];
    } else if (raw is List) {
      items = raw;
    } else {
      throw const FormatException('Formato de mazos no reconocido');
    }

    final decks = <Deck>[];
    for (final item in items) {
      if (item is! Map) continue;
      try {
        final deck = Deck.fromMap(Map<String, dynamic>.from(item));
        // Se descartan tarjetas totalmente vacías.
        final cards = deck.cards
            .where((c) => c.front.trim().isNotEmpty || c.back.trim().isNotEmpty)
            .toList();
        decks.add(deck.copyWith(cards: cards));
      } catch (e, stack) {
        AppLogger.error('Mazo ignorado al importar', error: e, stackTrace: stack);
      }
    }

    if (decks.isEmpty) {
      throw const FormatException('El archivo no contiene mazos válidos');
    }
    return decks;
  }

  /// Añade [incoming] a los mazos guardados SIN tocar los existentes.
  static Future<ImportSummary> addDecks(List<Deck> incoming) async {
    final existing = await DeckController.loadDecks();
    final usedTitles = existing.map((d) => d.title.trim().toLowerCase()).toSet();

    // Ids únicos aunque se creen muchos en el mismo instante.
    var seed = DateTime.now().microsecondsSinceEpoch;
    String nextId() => (seed++).toString();

    final fallbackTitle = 'KEY_IMPORTED_DECK'.locOr('Mazo importado', 'Imported deck');

    final added = <Deck>[];
    var cardCount = 0;
    for (final deck in incoming) {
      final baseTitle =
      deck.title.trim().isEmpty ? fallbackTitle : deck.title.trim();

      var title = baseTitle;
      var n = 2;
      while (usedTitles.contains(title.toLowerCase())) {
        title = '$baseTitle ($n)';
        n++;
      }
      usedTitles.add(title.toLowerCase());

      final cards = [
        for (final card in deck.cards) card.copyWith(id: nextId()),
      ];
      cardCount += cards.length;

      added.add(Deck(
        id: nextId(),
        title: title,
        frontLabel: deck.frontLabel,
        backLabel: deck.backLabel,
        cards: cards,
      ));
    }

    await DeckController.saveDecks([...existing, ...added]);
    return ImportSummary(decks: added.length, cards: cardCount);
  }
}