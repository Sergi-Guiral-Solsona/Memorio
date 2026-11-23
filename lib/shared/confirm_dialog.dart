import 'package:memorio/barrel_file.dart';

/// Sustituye marcadores `{nombre}` de un texto (p. ej. un texto traducido).
///
///     'Se eliminarán {count} tarjetas'.fill({'count': 3})
extension StringFill on String {
  String fill(Map<String, Object> values) {
    var result = this;
    values.forEach((key, value) => result = result.replaceAll('{$key}', '$value'));
    return result;
  }
}

/// Pide confirmar un borrado (evita eliminar por un toque sin querer).
/// Devuelve true solo si la persona pulsa "Eliminar"; cancelar, tocar fuera o
/// el botón atrás devuelven false.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        icon: Icon(Icons.delete_forever_rounded, size: 34, color: scheme.error),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('KEY_CANCEL'.loc),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('KEY_DELETE'.loc),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
