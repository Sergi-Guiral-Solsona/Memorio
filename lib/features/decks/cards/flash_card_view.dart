import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Tarjeta con dos caras: frontal (palabra + pista) y trasera (significado
/// centrado). Se gira arrastrando con el dedo o desde fuera con [showBack].
///
/// - Al arrastrar, la tarjeta sigue al dedo y al soltar se "engancha" a la
///   cara más cercana (o a la siguiente si el giro ya iba lo bastante avanzado).
/// - [onSideChanged] avisa de la cara que ha quedado visible (true = trasera),
///   para que el padre mantenga sincronizado su botón de girar.
/// - editable = true  -> campos de texto (crear / editar)
/// - editable = false -> solo lectura (práctica)
class FlashCardView extends StatefulWidget {
  final TextEditingController frontController;
  final TextEditingController hintController;
  final TextEditingController backController;
  final bool showBack;
  final ValueChanged<bool>? onSideChanged;
  final bool editable;

  /// Si la pista empieza visible. En práctica conviene false (se descubre con el ojo).
  final bool initialHintVisible;

  /// Proporción ancho/alto de la tarjeta (para calcular su tamaño desde fuera).
  static const double aspectRatio = 0.68;

  const FlashCardView({
    super.key,
    required this.frontController,
    required this.hintController,
    required this.backController,
    this.showBack = false,
    this.onSideChanged,
    this.editable = true,
    this.initialHintVisible = true,
  });

  @override
  State<FlashCardView> createState() => _FlashCardViewState();
}

class _FlashCardViewState extends State<FlashCardView>
    with SingleTickerProviderStateMixin {
  static const Duration _buttonFlipDuration = Duration(milliseconds: 500);
  static const Duration _dragSettleDuration = Duration(milliseconds: 280);

  /// Fracción de giro (0..1) a partir de la cual la tarjeta termina sola.
  static const double _snapThreshold = 0.3;

  /// Ancho de arrastre (en proporción al ancho de la tarjeta) para media vuelta.
  static const double _dragExtentFactor = 0.8;

  /// Posición del giro en medias vueltas: 0 = frontal, 1 = trasera, 2 = frontal...
  /// Sin límites, así cada giro puede seguir en la misma dirección.
  late final AnimationController _turn = AnimationController.unbounded(
    vsync: this,
    value: widget.showBack ? 1 : 0,
  );

  /// Cara de destino (entero): par = frontal, impar = trasera.
  late int _face = widget.showBack ? 1 : 0;

  // Vive aquí (y no en la cara) porque la cara frontal se destruye al girar.
  late bool _hintVisible = widget.initialHintVisible;

  double get _dragExtent =>
      (context.size?.width ?? 300) * _dragExtentFactor;

  @override
  void didUpdateWidget(covariant FlashCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedFromOutside = oldWidget.showBack != widget.showBack &&
        _face.isOdd != widget.showBack;
    if (changedFromOutside) {
      FocusManager.instance.primaryFocus?.unfocus();
      _settleOn(
        _face + 1,
        duration: _buttonFlipDuration,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  // --------------------------- Giro ---------------------------

  void _settleOn(
      int face, {
        Duration duration = _dragSettleDuration,
        Curve curve = Curves.easeOutCubic,
      }) {
    _face = face;
    _turn
        .animateTo(face.toDouble(), duration: duration, curve: curve)
        .whenCompleteOrCancel(() {
      if (mounted && _face == face) _notifySide();
    });
  }

  void _notifySide() {
    final isBack = _face.isOdd;
    if (isBack != widget.showBack) widget.onSideChanged?.call(isBack);
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
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: AspectRatio(
        aspectRatio: FlashCardView.aspectRatio,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) {
            final showingBack = _turn.value.round().isOdd;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_turn.value * math.pi),
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
    // Al editar siempre hay pista; al practicar solo si la tarjeta la tiene.
    final hasHint = editable || hintController.text.isNotEmpty;

    return CardSurface(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InsetBox(
            child: _FaceText(
              controller: frontController,
              editable: editable,
              hintText: 'KEY_WORD_OR_PHRASE'.loc,
              maxLines: 2,
              style: const TextStyle(
                color: CardSurface.ink,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          if (hasHint) ...[
            const SizedBox(height: 16),
            const CardDivider(),
            const SizedBox(height: 16),
            Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggleHint,
                child: HintBadge(size: 46, visible: hintVisible),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: hintVisible
                  ? _InsetBox(
                borderColor: CardSurface.accent,
                borderWidth: 2,
                expand: true,
                child: SingleChildScrollView(
                  child: _FaceText(
                    controller: hintController,
                    editable: editable,
                    hintText: 'KEY_HINT'.loc,
                    style: const TextStyle(
                      color: CardSurface.ink,
                      fontSize: 15,
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
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
    return CardSurface(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: SingleChildScrollView(
          child: _FaceText(
            controller: controller,
            editable: editable,
            hintText: 'KEY_ANSWER'.loc,
            style: const TextStyle(color: CardSurface.ink, fontSize: 22),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ========================== Componentes ==========================

/// Hueco claro, como un campo impreso sobre la tarjeta.
class _InsetBox extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final bool expand;

  const _InsetBox({
    required this.child,
    this.borderColor,
    this.borderWidth = 1.5,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? CardSurface.ink.withValues(alpha: 0.25),
          width: borderWidth,
        ),
      ),
      child: child,
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
    if (!editable) {
      return Text(
        controller.text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return TextField(
      controller: controller,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      cursorColor: CardSurface.ink,
      decoration: InputDecoration.collapsed(
        hintText: hintText,
        hintStyle: style.copyWith(
          color: CardSurface.ink.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
