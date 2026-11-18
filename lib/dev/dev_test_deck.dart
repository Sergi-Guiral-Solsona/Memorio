import 'package:memorio/barrel_file.dart';

// ============================================================================
// SOLO PARA DESARROLLO.
//
// Crea un mazo llamado "test" con ~100 tarjetas llenas de caracteres raros
// (ñ, acentos, varios alfabetos, emojis, RTL, saltos de línea, comillas...)
// para comprobar que la app los soporta en pantalla, búsqueda, CSV, estudio...
//
// Cómo eliminarlo por completo:
//   1. Borra este archivo (lib/dev/dev_test_deck.dart).
//   2. Borra su línea en lib/barrel_file.dart.
//   3. En decks_screen.dart borra el bloque marcado con "DEV-ONLY".
// ============================================================================

/// Una tarjeta de prueba (datos crudos, sin id).
class _Seed {
  final String front;
  final String back;
  final String hint;

  const _Seed(this.front, this.back, {this.hint = ''});
}

class DevTestDeck {
  DevTestDeck._();

  /// Id fijo: pulsar el botón varias veces regenera el mazo en vez de duplicarlo.
  static const String deckId = 'dev_test_deck';
  static const String deckTitle = 'test';

  /// Crea (o sustituye) el mazo "test" y lo guarda. Devuelve cuántas tarjetas tiene.
  static Future<int> create() async {
    final decks = await DeckController.loadDecks();
    decks.removeWhere((d) => d.id == deckId);

    final cards = buildCards();
    decks.add(Deck(
      id: deckId,
      title: deckTitle,
      // El rótulo del anverso también lleva caracteres raros a propósito.
      frontLabel: 'Texto · Text · Текст · 文本 · نص',
      backLabel: 'Respuesta · Answer · Ответ · 答案 · إجابة',
      cards: cards,
    ));

    await DeckController.saveDecks(decks);
    return cards.length;
  }

  /// Genera las tarjetas de prueba. Los ids son únicos y deterministas
  /// (no se usa DeckController._newId, que repetiría ids al crear muchas seguidas).
  static List<CardModel> buildCards() {
    return [
      for (var i = 0; i < _seeds.length; i++)
        CardModel(
          id: '${deckId}_card_${(i + 1).toString().padLeft(3, '0')}',
          front: _seeds[i].front,
          hint: _seeds[i].hint,
          back: _seeds[i].back,
        ),
    ];
  }

  static const List<_Seed> _seeds = [
    // ------------------------------ Español ------------------------------
    _Seed('El pingüino añoraba la cigüeña', 'ñ, ü y acentos en una frase',
        hint: 'ñ ü á é í ó ú'),
    _Seed('¿Cómo estás? ¡Qué sorpresa!', 'Signos de apertura ¿ ¡'),
    _Seed('ÁÉÍÓÚ ÑÜ áéíóú ñü', 'Mayúsculas y minúsculas acentuadas',
        hint: 'Compara con la búsqueda sin acentos'),
    _Seed('Árbol / arbol / ÁRBOL', 'Para probar el buscador sin acentos ni mayúsculas'),
    _Seed('Camión', 'Plural: camiones (el acento desaparece)'),
    _Seed('Mañana', 'Tomorrow / morning', hint: 'ñ'),
    _Seed('Cigüeña', 'Stork', hint: 'ü + ñ en la misma palabra'),
    _Seed('«Comillas angulares» y “comillas curvas”', 'Comillas tipográficas'),
    _Seed('Párrafo § — guion largo – guion medio … puntos suspensivos',
        'Puntuación tipográfica'),
    _Seed('º ª № € £ ¥ ¢ © ® ™', 'Símbolos habituales en textos en español'),

    // ------------------------ Otros idiomas latinos ------------------------
    _Seed('Où est la bibliothèque ?', 'Francés: ù è é ê ç œ'),
    _Seed('Cœur, sœur, œuf, être, naïve, Noël', 'Ligaduras y diéresis en francés'),
    _Seed('Straße, Mädchen, Äpfel, Öl, Übung', 'Alemán: ß ä ö ü',
        hint: 'ß en mayúsculas es SS (o ẞ)'),
    _Seed('GROẞE STRAẞE', 'Eszett mayúscula ẞ (U+1E9E)'),
    _Seed('Donaudampfschifffahrtsgesellschaftskapitän',
        'Palabra larguísima sin espacios (prueba de desbordamiento)'),
    _Seed('Coração, não, pão, açúcar, avó', 'Portugués: ã õ ç â ê'),
    _Seed('Perché? Città, caffè, più, già', 'Italiano con acentos graves'),
    _Seed('col·legi, il·lusió, paral·lel', 'Catalán: punt volat l·l',
        hint: 'U+00B7 punto medio'),
    _Seed('Què fas? Ça va? À la vora del mar', 'Catalán: à è ç'),
    _Seed('Teño unha cunca de café, mañá chove', 'Gallego'),

    // ------------------- Nórdico, eslavo, turco, rumano... -------------------
    _Seed('Blåbærsyltetøy', 'Noruego/danés: å æ ø'),
    _Seed('Älvdalen, ögon, åtta', 'Sueco: ä ö å'),
    _Seed('Þingvellir, Íslenska, ðá', 'Islandés: Þ þ Ð ð'),
    _Seed('Zażółć gęślą jaźń', 'Polaco: ą ć ę ł ń ó ś ź ż'),
    _Seed('Příliš žluťoučký kůň úpěl ďábelské ódy', 'Pangrama checo'),
    _Seed('İstanbul, ışık, ığdır, Şişli, Çağrı', 'Turco: İ ı ş ç ğ',
        hint: 'La I mayúscula con punto'),
    _Seed('Țară, șoarece, înțelept, ăsta', 'Rumano: ț ș î ă â'),
    _Seed('Árvíztűrő tükörfúrógép', 'Húngaro: ő ű'),
    _Seed('Dž dž Lj lj Nj nj ǅ ǆ', 'Dígrafos croatas en un solo carácter'),
    _Seed('Čaj, šuma, žaba, ćevapi, đak', 'Croata/serbio latino: č š ž ć đ'),
    _Seed('Ą Č Ę Ė Į Š Ų Ū Ž', 'Alfabeto lituano'),
    _Seed('Ŵŷ â ê î ô û ŵ ŷ', 'Galés: circunflejos'),
    _Seed('Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch',
        'Topónimo galés larguísimo'),
    _Seed('Tiếng Việt: ắ ằ ẳ ẵ ặ ế ề ể ễ ệ ơ ư', 'Vietnamita (múltiples diacríticos)'),

    // --------------------------- Griego y cirílico ---------------------------
    _Seed('Καλημέρα κόσμε', 'Griego: buenos días, mundo'),
    _Seed('ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ', 'Mayúsculas griegas'),
    _Seed('αβγδεζηθικλμνξοπρσςτυφχψω', 'Minúsculas griegas (σ y ς final)'),
    _Seed('Привет, мир!', 'Ruso: ¡Hola, mundo!'),
    _Seed('Съешь же ещё этих мягких французских булок', 'Pangrama ruso'),
    _Seed('Ёжик, щётка, чёрный', 'Ruso con Ё', hint: 'Ё ё'),
    _Seed('Україна, їжак, ґанок, є', 'Ucraniano: ї є ґ'),
    _Seed('Ђ ђ Љ љ Њ њ Ћ ћ Џ џ', 'Cirílico serbio'),

    // ------------------- Derecha a izquierda (RTL) y mixtos -------------------
    _Seed('مرحبا بالعالم', 'Árabe: hola mundo (RTL)'),
    _Seed('اللغة العربية جميلة', 'El idioma árabe es hermoso'),
    _Seed('שלום עולם', 'Hebreo: hola mundo (RTL)'),
    _Seed('Hello مرحبا World שלום', 'Texto mixto LTR + RTL en la misma línea'),
    _Seed('فارسی: سلام دنیا', 'Persa'),
    _Seed('اردو: ہیلو دنیا', 'Urdu'),

    // ------------------------------ Asia oriental ------------------------------
    _Seed('こんにちは世界', 'Japonés: hola mundo'),
    _Seed('ひらがな カタカナ 漢字', 'Los tres sistemas de escritura japoneses'),
    _Seed('食べる (たべる)', 'Comer', hint: 'Kanji + furigana'),
    _Seed('你好，世界', 'Chino simplificado'),
    _Seed('你好，世界！學習繁體字', 'Chino tradicional'),
    _Seed('안녕하세요 세계', 'Coreano'),
    _Seed('ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ', 'Consonantes coreanas (jamo)'),
    _Seed('𠮷野家 𩸽 𪚥', 'Kanji raros fuera del BMP (planos suplementarios)',
        hint: 'U+20BB7 y similares'),
    _Seed('ＦＵＬＬＷＩＤＴＨ １２３', 'Caracteres de ancho completo'),

    // ---------------------------- Otros alfabetos ----------------------------
    _Seed('สวัสดีชาวโลก', 'Tailandés (con vocales y tonos apilados)'),
    _Seed('नमस्ते दुनिया', 'Hindi (Devanagari con conjuntos)'),
    _Seed('வணக்கம் உலகம்', 'Tamil'),
    _Seed('Բարեւ աշխարհ', 'Armenio'),
    _Seed('გამარჯობა მსოფლიო', 'Georgiano'),
    _Seed('ሰላም ልዑል', 'Amárico (etíope)'),

    // -------------------------------- Emojis --------------------------------
    _Seed('😀 😂 🥹 😍 🤯 😴', 'Emojis de caras básicos'),
    _Seed('👍🏻 👍🏽 👍🏿', 'Emoji con modificadores de tono de piel'),
    _Seed('👨‍👩‍👧‍👦 👩‍❤️‍👨 🧑‍💻 👩🏽‍🚀', 'Secuencias ZWJ (varios emojis unidos)',
        hint: 'Deben verse como un solo símbolo'),
    _Seed('🇪🇸 🇯🇵 🇧🇷 🇦🇷 🇲🇽 🇺🇸', 'Banderas (pares de indicadores regionales)'),
    _Seed('1️⃣ 2️⃣ 3️⃣ #️⃣ *️⃣', 'Emojis keycap (con selector de variación)'),
    _Seed('🏳️‍🌈 🏴‍☠️ 🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Banderas especiales (arcoíris, pirata, Inglaterra)'),
    _Seed('❤️ ❤ ♥ ♡', 'Mismo corazón con y sin selector de emoji (U+FE0F)'),
    _Seed('🐱🐶🦄🐙🦖🐝', 'Animales', hint: 'Los más nuevos pueden salir como □ en Androids viejos'),
    _Seed('🍕🌮🍣🥑🍩☕', 'Comida'),
    _Seed('🔥💯✨🎉🚀🌈', 'Emojis de celebración'),
    _Seed('😶‍🌫️ 🫠 🫶 🫡', 'Emojis recientes (Unicode 13-14)'),
    _Seed('Hola 👋 mundo 🌍 con emoji en medio', 'Texto mezclado con emojis'),

    // ------------------- Matemáticas, símbolos, flechas -------------------
    _Seed('∑ ∏ ∫ √ ∞ ≠ ≈ ≤ ≥ ± × ÷', 'Símbolos matemáticos'),
    _Seed('E = mc²   H₂O   x₁ + x₂   a³ + b³', 'Superíndices y subíndices',
        hint: '² ³ ₁ ₂ ₂'),
    _Seed('← ↑ → ↓ ↔ ⇒ ⇐ ⇔ ↩ ➜', 'Flechas'),
    _Seed('€ £ ¥ ₹ ₽ ₩ ₿ ₪ ₺ ₫', 'Símbolos de moneda'),
    _Seed('½ ¼ ¾ ⅓ ⅔ ⅛ ⅝', 'Fracciones'),
    _Seed('♠ ♣ ♥ ♦ ♪ ♫ ☀ ☁ ☂ ★ ☆', 'Símbolos varios'),
    _Seed('𝕳𝖊𝖑𝖑𝖔 𝓦𝓸𝓻𝓵𝓭 𝔸𝔹ℂ', 'Letras matemáticas (plano suplementario)',
        hint: 'No son letras normales'),
    _Seed('ǅ ǆ Ǉ ǌ ﬁ ﬂ ﬃ', 'Ligaduras tipográficas en un solo carácter'),

    // ----------------------- Caracteres invisibles / Unicode -----------------------
    _Seed('n\u0303 vs ñ  |  e\u0301 vs é', 'Descompuesto (NFD) frente a compuesto (NFC)',
        hint: 'Se ven igual pero no son iguales como cadena'),
    _Seed('ab\u200Bcd (espacio de ancho cero entre b y c)',
        'U+200B invisible: puede romper comparaciones'),
    _Seed('inter\u00ADnacio\u00ADnal\u00ADización', 'Guion blando (U+00AD)'),
    _Seed('palabra\u00A0con\u00A0espacios\u00A0duros', 'Espacios no separables (NBSP)'),
    _Seed('Z\u0335\u0336a\u0338l\u0336g\u0337o\u0338', 'Zalgo: marcas combinantes apiladas',
        hint: 'Prueba de desbordamiento vertical'),
    _Seed('\u202Etexto invertido\u202C (RLO)', 'Override de dirección: texto al revés',
        hint: 'U+202E'),

    // --------------- Formato, comillas y cadenas problemáticas ---------------
    _Seed('Dijo: "hola", \'adiós\' y «chao»', 'Comillas simples, dobles y angulares mezcladas'),
    _Seed('a,b;c"d,e', 'Coma, punto y coma y comillas: rompe CSV si no se escapa',
        hint: 'Pruébalo con exportar/importar CSV'),
    _Seed('Línea 1\nLínea 2\nLínea 3', 'Salto de línea dentro de la tarjeta'),
    _Seed('Columna A\tColumna B\tColumna C', 'Tabuladores en el texto'),
    _Seed('Párrafo uno\n\nPárrafo dos tras línea en blanco', 'Doble salto de línea'),
    _Seed('{"clave": "valor", "n": [1, 2, 3], "ñ": "ü"}', 'Parece JSON; no debe romper el guardado'),
    _Seed('<b>negrita</b> & <script>alert(1)</script>', 'HTML sin interpretar'),
    _Seed(r'C:\Users\ñandú\Desktop\nueva_carpeta', r'Barras invertidas (\n y \t literales)'),
    _Seed(r'Cuesta $100, 50% de {name} y {count} cartas %s %d',
        r'Texto con $, % y {placeholders}: no debe confundirse con .fill()'),
    _Seed('   espacios al principio y al final   ', 'Prueba de trim()'),
    _Seed('ñ', 'Una sola letra'),
    _Seed('1234567890', 'Solo números'),
    _Seed('— – - _ ~ | / \\ ` ´ ¨ ^ ° ¬ ¦', 'Signos poco comunes'),
    _Seed(
      'Esta es una tarjeta con un texto extremadamente largo para comprobar cómo '
      'se comporta el diseño: ñandú, cigüeña, día, corazón, niño, canción, '
      'pingüino, avión, camión, árbol, lápiz, fácil, difícil, útil, sábado, '
      'miércoles, murciélago, ¿qué?, ¡caramba! Esto se repite varias veces para '
      'forzar el desbordamiento, el scroll y el ajuste de líneas en pantallas '
      'pequeñas, y también para ver si el texto se corta correctamente.',
      'Respuesta igualmente larga: el objetivo es ver que no hay overflow, que '
      'el texto se ajusta, que se puede hacer scroll si hace falta y que los '
      'caracteres especiales no se rompen al partir líneas: ñ ü é 日本語 😀 العربية.',
      hint: 'Texto largo (≈400 caracteres)',
    ),
    _Seed('Pneumonoultramicroscopicsilicovolcanoconiosis',
        'Palabra inglesa de 45 letras sin espacios'),
    _Seed('Supercalifragilisticoespialidoso 🪄', 'Palabra larga con emoji al final'),
    _Seed('Ünïcödé — ¿sí? ¡sí! 日本 🌍 ß ñ Ж', 'Mezcla final de todo un poco',
        hint: 'Última tarjeta de prueba'),
  ];
}

/// Botón flotante pequeño (icono de bicho) que crea el mazo de pruebas.
/// Solo se pinta en modo debug; en release no ocupa nada.
class DevTestDeckButton extends StatelessWidget {
  /// Se llama al terminar de crear el mazo, para refrescar la lista.
  final Future<void> Function() onCreated;

  const DevTestDeckButton({super.key, required this.onCreated});

  Future<void> _onPressed(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final count = await DevTestDeck.create();
    await onCreated();
    messenger.showSnackBar(
      SnackBar(content: Text('Mazo "${DevTestDeck.deckTitle}" creado con $count tarjetas')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return FloatingActionButton.small(
      heroTag: 'dev_test_deck_fab',
      tooltip: 'DEV: crear mazo "test"',
      backgroundColor: Colors.deepOrange,
      foregroundColor: Colors.white,
      onPressed: () => _onPressed(context),
      child: const Icon(Icons.bug_report),
    );
  }
}
