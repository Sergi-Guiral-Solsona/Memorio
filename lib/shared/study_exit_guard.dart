import 'package:memorio/barrel_file.dart';

/// Pregunta si se quiere salir de una sesión de estudio. Devuelve true solo si
/// la persona pulsa "Salir"; "Seguir estudiando", tocar fuera o atrás devuelven false.
Future<bool> confirmExitStudy(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        icon: Icon(Icons.exit_to_app_rounded, size: 34, color: scheme.primary),
        title: Text(
          'KEY_EXIT_STUDY_TITLE'.locOr('¿Salir del estudio?', 'Leave the study session?'),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'KEY_EXIT_STUDY_MSG'.locOr(
            'Las tarjetas que ya has respondido se guardan, pero esta sesión se cerrará.',
            'The cards you have already answered are saved, but this session will close.',
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('KEY_KEEP_STUDYING'.locOr('Seguir estudiando', 'Keep studying')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('KEY_EXIT'.loc),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Envuelve una pantalla de estudio: mientras la sesión está en marcha, el
/// botón "atrás" (flecha, gesto o botón del sistema) pregunta antes de salir.
/// Con [canExit] true (sesión terminada) se sale sin preguntar.
///
/// [onAsking] y [onStay] avisan de cuándo se abre el diálogo y de cuándo se
/// decide seguir (p. ej. para pausar y reanudar el temporizador del Pomodoro).
class StudyExitGuard extends StatelessWidget {
  final bool canExit;
  final VoidCallback? onAsking;
  final VoidCallback? onStay;
  final Widget child;

  const StudyExitGuard({
    super.key,
    required this.canExit,
    required this.child,
    this.onAsking,
    this.onStay,
  });

  Future<void> _handleBack(BuildContext context) async {
    onAsking?.call();
    final exit = await confirmExitStudy(context);
    if (!context.mounted) return;

    if (exit) {
      Navigator.pop(context);
    } else {
      onStay?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack(context);
      },
      child: child,
    );
  }
}
