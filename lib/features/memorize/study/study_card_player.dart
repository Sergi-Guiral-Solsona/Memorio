import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Muestra una tarjeta para estudiar, con animaciones:
///  - entra desde abajo con un pequeño rebote;
///  - se gira (dedo, toque o botón) y solo entonces aparecen los botones
///    "Lo sabía / No lo sabía";
///  - al responder sale volando (derecha + brillo verde si acertó,
///    izquierda + brillo rojo si falló) y vibra.
///
/// Ponle una `key` distinta en cada tarjeta para que se reinicie el estado.
class StudyCardPlayer extends StatefulWidget {
  final CardModel card;
  final Future<void> Function(bool isCorrect) onAnswer;

  /// Widget opcional sobre la tarjeta (p. ej. la prioridad en Memorio Learning).
  final Widget? header;

  const StudyCardPlayer({
    super.key,
    required this.card,
    required this.onAnswer,
    this.header,
  });

  @override
  State<StudyCardPlayer> createState() => _StudyCardPlayerState();
}

class _StudyCardPlayerState extends State<StudyCardPlayer>
    with TickerProviderStateMixin {
  static const double _maxContentWidth = 380;
  static const double _minCardWidth = 220;
  static const double _baseReservedHeight = 150; // botones + márgenes
  static const double _headerHeight = 48;

  final FlashCardController _flip = FlashCardController();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  bool _isBusy = false;
  double _exitDirection = 1; // 1 = derecha (acierto), -1 = izquierda (fallo)

  @override
  void initState() {
    super.initState();
    _flip.addListener(_onFlipChanged);
    _enter.forward();
  }

  @override
  void dispose() {
    _flip.removeListener(_onFlipChanged);
    _flip.dispose();
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  void _onFlipChanged() => setState(() {});

  Future<void> _answer(bool isCorrect) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _exitDirection = isCorrect ? 1 : -1;
    });
    HapticFeedback.lightImpact();

    await _exit.forward();
    if (!mounted) return;

    // El padre guarda el resultado y sustituye este widget por la siguiente tarjeta.
    await widget.onAnswer(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved =
            _baseReservedHeight + (widget.header != null ? _headerHeight : 0);
        // La tarjeta se ajusta al alto disponible para no tener que hacer scroll.
        final byHeight = (constraints.maxHeight - reserved) * FlashCardView.aspectRatio;
        final cardWidth = math.max(
          _minCardWidth,
          math.min(
            math.min(_maxContentWidth, constraints.maxWidth - 48),
            byHeight,
          ),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (widget.header != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: widget.header!,
                ),
              _buildAnimatedCard(cardWidth, constraints.maxWidth),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: _buildActions(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCard(double cardWidth, double screenWidth) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _exit]),
      builder: (context, child) {
        final enter = Curves.easeOutBack.transform(_enter.value);
        final exit = Curves.easeInCubic.transform(_exit.value);
        final glow = (_exitDirection > 0 ? Colors.green : Colors.red)
            .withValues(alpha: 0.55 * exit);

        return Opacity(
          opacity: (_enter.value * (1 - exit)).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(_exitDirection * exit * screenWidth, (1 - enter) * 36),
            child: Transform.rotate(
              angle: _exitDirection * exit * 0.35,
              child: Transform.scale(
                scale: 0.9 + 0.1 * enter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: glow, blurRadius: 36, spreadRadius: 2)],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: SizedBox(
        width: cardWidth,
        child: StudyCardView(card: widget.card, controller: _flip),
      ),
    );
  }

  Widget _buildActions() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      // Los botones de respuesta solo aparecen cuando la tarjeta ya está girada.
      child: _flip.isBack
          ? _AnswerButtons(
              key: const ValueKey('answers'),
              enabled: !_isBusy,
              onAnswer: _answer,
            )
          : SizedBox(
              key: const ValueKey('flip'),
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _flip.flip,
                icon: const Icon(Icons.flip),
                label: Text('KEY_FLIP'.loc),
              ),
            ),
    );
  }
}

class _AnswerButtons extends StatelessWidget {
  final bool enabled;
  final Future<void> Function(bool isCorrect) onAnswer;

  const _AnswerButtons({super.key, required this.enabled, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // FittedBox: con idiomas de texto largo (alemán, ruso...) el texto se
    // reduce en vez de desbordar el botón.
    Widget label(String text) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1),
        );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? () => onAnswer(false) : null,
            icon: const Icon(Icons.close),
            label: label('KEY_DIDNT_KNOW'.loc),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled ? () => onAnswer(true) : null,
            icon: const Icon(Icons.check),
            label: label('KEY_KNEW_IT'.loc),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
