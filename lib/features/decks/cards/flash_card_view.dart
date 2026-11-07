import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Mando de una [FlashCardView]: permite girarla desde fuera (`flip()`) y
/// saber en qué cara se ha detenido (`isBack`).
///
/// Sustituye al antiguo par `showBack` + `onSideChanged`, que podía quedar
/// desincronizado entre el padre y la tarjeta (origen de fallos al girar).
class FlashCardController extends ChangeNotifier {
  _FlashCardViewState? _state;
  bool _isBack = false;

  /// true cuando la tarjeta está QUIETA mostrando la cara trasera.
  /// Durante la animación mantiene el valor anterior.
  bool get isBack => _isBack;

  /// Gira la tarjeta a la otra cara con animación.
  void flip() => _state?._flipFromOutside();

  void _setBack(bool value) {
    if (_isBack == value) return;
    _isBack = value;
    notifyListeners();
  }
}

/// Tarjeta con dos caras: frontal (palabra + pista) y trasera (respuesta).
///
/// - Se gira arrastrando con el dedo: sigue al dedo y al soltar se "engancha"
///   a la cara más cercana (o a la siguiente si el giro iba avanzado).
/// - También con [FlashCardController.flip] y, si [flipOnTap], tocándola.
/// - editable = true  -> campos de texto (crear / editar)
/// - editable = false -> solo lectura (estudio)
class FlashCardView extends StatefulWidget {
  final FlashCardController controller;
  final TextEditingController frontController;
  final TextEditingController hintController;
  final TextEditingController backController;
  final bool editable;

  /// Si la pista empieza visible. En estudio conviene false.
  final bool initialHintVisible;

  /// Girar al tocar la tarjeta (para estudio; en edición debe ser false).
  final bool flipOnTap;

  /// Proporción ancho/alto de la tarjeta (para calcular su tamaño desde fuera).
  static const double aspectRatio = 0.68;

  const FlashCardView({
    super.key,
    required this.controller,
    required this.frontController,
    required this.hintController,
    required this.backController,
    this.editable = true,
    this.initialHintVisible = true,
    this.flipOnTap = false,
  });

  @override
  State<FlashCardView> createState() => _FlashCardViewState();
}

class _FlashCardViewState extends State<FlashCardView>
    with SingleTickerProviderStateMixin {
  static const Duration _flipDuration = Duration(milliseconds: 520);
  static const Duration _dragSettleDuration = Duration(milliseconds: 300);

  /// Fracción de giro (0..1) a partir de la cual la tarjeta termina sola.
  static const double _snapThreshold = 0.3;

  /// Ancho de arrastre (proporción del ancho de la tarjeta) para media vuelta.
  static const double _dragExtentFactor = 0.8;

  /// Giro en medias vueltas: 0 = frontal, 1 = trasera, 2 = frontal...
  /// Sin límites, así cada giro puede seguir en la misma dirección.
  late final AnimationController _turn;

  /// Cara de destino (entero): par = frontal, impar = trasera.
  late int _face;

  // Vive aquí (y no en la cara) porque la cara frontal se destruye al girar.
  late bool _hintVisible = widget.initialHintVisible;

  double get _dragExtent => (context.size?.width ?? 300) * _dragExtentFactor;

  @override
  void initState() {
    super.initState();
    _face = widget.controller.isBack ? 1 : 0;
    _turn = AnimationController.unbounded(vsync: this, value: _face.toDouble());
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant FlashCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller._state == this) oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _turn.dispose();
    super.dispose();
  }

  // --------------------------- Giro ---------------------------

  void _flipFromOutside() {
    FocusManager.instance.primaryFocus?.unfocus();
    _settleOn(_face + 1, duration: _flipDuration, curve: Curves.easeInOutCubic);
  }

  void _settleOn(
    int face, {
    Duration duration = _dragSettleDuration,
    Curve curve = Curves.easeOutCubic,
  }) {
    _face = face;
    _turn
        .animateTo(face.toDouble(), duration: duration, curve: curve)
        .whenCompleteOrCancel(() {
      // Solo avisa si no se ha empezado otro giro mientras tanto.
      if (mounted && _face == face) widget.controller._setBack(face.isOdd);
    });
  }

  void _onDragStart(DragStartDetails _) {
    FocusManager.instance.primaryFocus?.unfocus();
    _face = _turn.value.round(); // antes de parar, para ignorar el aviso viejo
    _turn.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Se bloquea al llegar a la cara contigua: un arrastre gira como mucho una cara.
    _turn.value = (_turn.value + details.delta.dx / _dragExtent)
        .clamp(_face - 1.0, _face + 1.0)
        .toDouble();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx / _dragExtent;
    final projected = _turn.value - _face + velocity * 0.1;
    final steps = projected.abs() > _snapThreshold ? projected.sign.toInt() : 0;
    _settleOn(_face + steps);
  }

  void _onDragCancel() => _settleOn(_face);

  // --------------------------- Build ---------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.flipOnTap ? _flipFromOutside : null,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: AspectRatio(
        aspectRatio: FlashCardView.aspectRatio,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) {
            final value = _turn.value;
            final showingBack = value.round().isOdd;
            // La tarjeta "se levanta" un poco a mitad del giro.
            final lift = math.sin((value % 1.0) * math.pi);

            return Transform.scale(
              scale: 1 + 0.04 * lift,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(value * math.pi),
                child: showingBack
                    // Se gira otra vez para que el texto no salga en espejo.
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: _BackFace(
                          controller: widget.backController,
                          editable: widget.editable,
                        ),
                      )
                    : _FrontFace(
                        frontController: widget.frontController,
                        hintController: widget.hintController,
                        editable: widget.editable,
                        hintVisible: _hintVisible,
                        onToggleHint: () =>
                            setState(() => _hintVisible = !_hintVisible),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================ Caras ============================

class _FrontFace extends StatelessWidget {
  final TextEditingController frontController;
  final TextEditingController hintController;
  final bool editable;
  final bool hintVisible;
  final VoidCallback onToggleHint;

  const _FrontFace({
    required this.frontController,
    required this.hintController,
    required this.editable,
    required this.hintVisible,
    required this.onToggleHint,
  });

  @override
  Widget build(BuildContext context) {
    // Al editar siempre hay pista; al estudiar solo si la tarjeta la tiene.
    final hasHint = editable || hintController.text.isNotEmpty;

    return CardSurface(
      padding: const EdgeInsets.fromLTRB(28, 38, 28, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InsetBox(
            editable: editable,
            child: _FaceText(
              controller: frontController,
              editable: editable,
              hintText: 'KEY_WORD_OR_PHRASE'.loc,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
            ),
          ),
          const SizedBox(height: 18),
          const CardDivider(),
          if (hasHint) ...[
            const SizedBox(height: 18),
            Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggleHint,
                child: HintBadge(size: 46, visible: hintVisible),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                child: hintVisible
                    ? _HintPanel(
                        key: const ValueKey('hint'),
                        controller: hintController,
                        editable: editable,
                      )
                    : const SizedBox.expand(key: ValueKey('no-hint')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;

  const _BackFace({required this.controller, required this.editable});

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;

    return CardSurface(
      padding: const EdgeInsets.fromLTRB(28, 38, 28, 30),
      child: Stack(
        children: [
          // Comillas de fondo, muy suaves.
          Positioned.fill(
            child: Center(
              child: Icon(
                Icons.format_quote_rounded,
                size: 150,
                color: p.ink.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardCaption('KEY_ANSWER'.loc),
              const SizedBox(height: 14),
              const CardDivider(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _FaceText(
                      controller: controller,
                      editable: editable,
                      hintText: 'KEY_ANSWER'.loc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================== Componentes ==========================

/// Al editar: campo con fondo y borde. Al estudiar: solo el texto.
class _InsetBox extends StatelessWidget {
  final bool editable;
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final bool expand;

  const _InsetBox({
    required this.editable,
    required this.child,
    this.borderColor,
    this.borderWidth = 1.5,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!editable) return child;

    final p = context.cardPalette;
    return Container(
      width: double.infinity,
      height: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? p.ink.withValues(alpha: 0.22),
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}

/// Panel de la pista: un campo amarillo al editar, una nota al estudiar.
class _HintPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;

  const _HintPanel({super.key, required this.controller, required this.editable});

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    const style = TextStyle(fontSize: 15);

    if (editable) {
      return _InsetBox(
        editable: true,
        expand: true,
        borderColor: p.accent,
        borderWidth: 2,
        child: SingleChildScrollView(
          child: _FaceText(
            controller: controller,
            editable: true,
            hintText: 'KEY_HINT'.loc,
            style: style,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: p.accent, width: 4)),
      ),
      child: SingleChildScrollView(
        child: _FaceText(
          controller: controller,
          editable: false,
          hintText: '',
          style: style,
        ),
      ),
    );
  }
}

/// Texto que es un TextField si [editable] y un Text si no.
class _FaceText extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;
  final String hintText;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;

  const _FaceText({
    required this.controller,
    required this.editable,
    required this.hintText,
    required this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final ink = context.cardPalette.ink;
    final base = style.copyWith(color: ink);

    if (!editable) {
      return Text(
        controller.text,
        style: base,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }

    return TextField(
      controller: controller,
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      cursorColor: ink,
      decoration: InputDecoration.collapsed(
        hintText: hintText,
        hintStyle: base.copyWith(color: ink.withValues(alpha: 0.4)),
      ),
    );
  }
}
