import 'package:memorio/barrel_file.dart';

/// Mayúscula automática al escribir el texto de una tarjeta (anverso, reverso
/// y pista) y el nombre de un mazo.
///
/// Se delega en el TECLADO del sistema (`TextCapitalization.sentences`) en vez
/// de convertir el texto por código, por tres razones:
///  - El teclado conoce las reglas del idioma que se está escribiendo (que no
///    tiene por qué ser el de la app): no pone mayúsculas en chino, japonés,
///    árabe, hebreo, hindi... y trata bien el turco (i -> İ), el alemán (ß), etc.
///  - NO es obligatoria: el teclado solo activa la tecla Mayús al empezar, y
///    quien quiera minúscula la desactiva y escribe en minúscula sin que nada
///    se lo corrija después.
///  - No toca el texto ya guardado ni el cursor.
///
/// Si algún día se quiere otra política (p. ej. un ajuste "mayúscula
/// automática" o distinta por campo), solo hay que cambiarla aquí.
const TextCapitalization kAutoCapitalization = TextCapitalization.sentences;
