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

  /// Rótulos de cada cara ("English", "Español"...). Pueden estar vacíos.
  final TextEditingController frontLabelController;
  final TextEditingController backLabelController;
  final bool editable;

  /// Si la pista empieza visible. En estudio conviene false.
  final bool initialHintVisible;

  /// Girar al tocar la tarjeta (para estudio; en edición debe ser false).
  final bool flipOnTap;

  /// Proporción ancho/alto de la tarjeta (para calcular su tamaño desde fuera).
  static const double aspectRatio = 0.72;

  const FlashCardView({
    super.key,
    required this.controller,
    required this.frontController,
    required this.hintController,
    required this.backController,
    required this.frontLabelController,
    required this.backLabelController,
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
                          labelController: widget.backLabelController,
                          editable: widget.editable,
                        ),
                      )
                    : _FrontFace(
                        frontController: widget.frontController,
                        hintController: widget.hintController,
                        labelController: widget.frontLabelController,
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

/// Estilo del título según el modelo de tarjeta: serif grande en los estilos
/// modernos, sans en negrita en el clásico.
TextStyle _titleStyle(CardFaceStyle face, double size, {bool bold = false}) {
  return CardFonts.title(color: face.title, size: size);
}

class _FrontFace extends StatelessWidget {
  final TextEditingController frontController;
  final TextEditingController hintController;
  final TextEditingController labelController;
  final bool editable;
  final bool hintVisible;
  final VoidCallback onToggleHint;

  const _FrontFace({
    required this.frontController,
    required this.hintController,
    required this.labelController,
    required this.editable,
    required this.hintVisible,
    required this.onToggleHint,
  });

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      isBack: false,
      padding: const EdgeInsets.fromLTRB(26, 20, 18, 26),
      child: _FrontContent(
        frontController: frontController,
        hintController: hintController,
        labelController: labelController,
        editable: editable,
        hintVisible: hintVisible,
        onToggleHint: onToggleHint,
      ),
    );
  }
}

class _FrontContent extends StatelessWidget {
  final TextEditingController frontController;
  final TextEditingController hintController;
  final TextEditingController labelController;
  final bool editable;
  final bool hintVisible;
  final VoidCallback onToggleHint;

  const _FrontContent({
    required this.frontController,
    required this.hintController,
    required this.labelController,
    required this.editable,
    required this.hintVisible,
    required this.onToggleHint,
  });

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);
    // Al editar siempre hay pista; al estudiar solo si la tarjeta la tiene.
    final hasHint = editable || hintController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: _CaptionField(
                  controller: labelController,
                  editable: editable,
                  //aqui
                  fallback: 'Test',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
        _InsetBox(
          enabled: editable,
          child: _TitleText(
            controller: frontController,
            editable: editable,
            hintText: 'KEY_WORD_OR_PHRASE'.loc,
            baseSize: 40,
            bold: true,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: CardAccentLine()),
        if (hasHint) _HintToggle(visible: hintVisible, onTap: onToggleHint),
        if (hasHint) ...[
          const SizedBox(height: 18),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              child: hintVisible
                  ? _HintArea(
                      key: const ValueKey('hint'),
                      controller: hintController,
                      editable: editable,
                    )
                  : const SizedBox.expand(key: ValueKey('no-hint')),
            ),
          ),
        ],
      ],
    );
  }
}

class _BackFace extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController labelController;
  final bool editable;

  const _BackFace({
    required this.controller,
    required this.labelController,
    required this.editable,
  });

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      isBack: true,
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 26),
      child: _BackContent(
        controller: controller,
        labelController: labelController,
        editable: editable,
      ),
    );
  }
}

class _BackContent extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController labelController;
  final bool editable;

  const _BackContent({
    required this.controller,
    required this.labelController,
    required this.editable,
  });

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _CaptionField(
              controller: labelController,
              editable: editable,
              fallback: 'KEY_ANSWER'.loc,
            ),
          ),
        ),
       // if (face.isClassic) ...[const SizedBox(height: 4), const CardDivider()],
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: _TitleText(
                controller: controller,
                editable: editable,
                hintText: 'KEY_ANSWER'.loc,
                baseSize: 38,
              ),
            ),
          ),
        ),
      ],
    );

    return content;
  }
}

// ========================== Componentes ==========================

/// Título o respuesta: la letra se reduce sola cuando el texto es largo.
class _TitleText extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;
  final String hintText;
  final double baseSize;
  final bool bold;
  final int? maxLines;

  const _TitleText({
    required this.controller,
    required this.editable,
    required this.hintText,
    required this.baseSize,
    this.bold = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final length = value.text.length;
        final size = length <= 12
            ? baseSize
            : length <= 24
                ? baseSize * 0.82
                : baseSize * 0.64;

        return _FaceText(
          controller: controller,
          editable: editable,
          hintText: hintText,
          textAlign: TextAlign.center,
          maxLines: maxLines,
          style: _titleStyle(face, size, bold: bold),
        );
      },
    );
  }
}

/// Rótulo de arriba a la izquierda ("ENGLISH"). Editable al crear la tarjeta;
/// si está vacío muestra [fallback].
class _CaptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;
  final String fallback;

  const _CaptionField({
    required this.controller,
    required this.editable,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);
    final style = TextStyle(
      fontSize: 11,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w600,
      color: face.caption,
    );

    if (!editable) {
      final text = controller.text.trim().isEmpty ? fallback : controller.text;
      return Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return TextField(
      controller: controller,
      style: style,
      maxLines: 1,
      cursorColor: face.caption,
      inputFormatters: [_UpperCaseFormatter(), LengthLimitingTextInputFormatter(24)],
      decoration: InputDecoration.collapsed(
        hintText: fallback.toUpperCase(),
        hintStyle: style.copyWith(color: face.caption.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final upper = newValue.text.toUpperCase();
    // Si cambia la longitud (ß -> SS) se deja tal cual para no descolocar el cursor.
    return upper.length == newValue.text.length ? newValue.copyWith(text: upper) : newValue;
  }
}

/// Botón del ojo para mostrar/ocultar la pista.
class _HintToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const _HintToggle({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);

    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: Color.fromRGBO(255, 167, 38, 1),
      icon: Icon(visible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
    );
  }
}

/// La pista: texto en cursiva bajo el título (moderno) o nota amarilla (clásico).
class _HintArea extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;

  const _HintArea({super.key, required this.controller, required this.editable});

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: _FaceText(
          controller: controller,
          editable: editable,
          hintText: 'KEY_HINT'.loc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 17,
            height: 1.35,
            color: face.hint,
          ),
        ),
      ),
    );
  }
}

/// Al editar con el estilo clásico: campo con fondo y borde. En el resto, solo el texto.
class _InsetBox extends StatelessWidget {
  final bool enabled;
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final bool expand;

  const _InsetBox({
    required this.enabled,
    required this.child,
    this.borderColor ,
    this.borderWidth = 1.5,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final face = CardFaceScope.of(context);
    return Container(
      width: double.infinity,
      height: expand ? double.infinity : 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: face.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? face.fieldBorder,
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
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }

    return TextField(
      controller: controller,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      cursorColor: style.color,
      decoration: InputDecoration.collapsed(
        hintText: hintText,
        hintStyle: style.copyWith(color: style.color?.withValues(alpha: 0.35)),
      ),
    );
  }
}
