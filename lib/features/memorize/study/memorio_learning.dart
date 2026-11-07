import 'dart:math' as math;
import 'package:memorio/features/decks/models/card_model.dart';

/// Memorio Learning: el orden de las tarjetas depende de cuánto las fallas.
///
/// - El PESO de una tarjeta es su porcentaje de fallos (fallos / intentos).
///     * Falladas 1 de 3 veces  -> peso 0.33
///     * Tarjeta nueva (sin intentos) -> peso 1.0 (sale pronto)
///     * Nunca fallada -> peso mínimo [minWeight] (nunca 0, así siempre sale)
/// - El orden es un sorteo ponderado SIN reemplazo: cuanto más peso, más
///   probable es que salga antes, pero no está garantizado. Una tarjeta de
///   peso 4 puede salir antes que una de peso 80, y todas acaban saliendo
///   exactamente una vez por ronda.
///
/// Técnica: Efraimidis–Spirakis. A cada tarjeta se le asigna la clave
/// `u^(1/peso)` con `u` aleatorio en (0,1) y se ordena de mayor a menor.
/// (Aquí se usa su logaritmo, que ordena igual y es numéricamente estable.)
class MemorioLearning {
  MemorioLearning._();

  /// Peso de una tarjeta que aún no se ha respondido nunca.
  static const double unseenWeight = 1.0;

  /// Peso mínimo: garantiza que hasta las tarjetas dominadas vuelvan a salir.
  static const double minWeight = 0.03;

  /// Peso de la tarjeta (0.03 .. 1.0).
  static double weightOf(CardModel card) {
    if (card.attempts == 0) return unseenWeight;
    return math.max(minWeight, card.errorRate);
  }

  /// Devuelve [items] en un orden aleatorio ponderado por [weightOf].
  static List<T> weightedOrder<T>(
    Iterable<T> items,
    double Function(T item) weightOf, {
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final keyed = <_KeyedItem<T>>[];

    for (final item in items) {
      final weight = math.max(weightOf(item), 1e-9);
      final u = math.max(rng.nextDouble(), 1e-12); // evita log(0)
      keyed.add(_KeyedItem(item, math.log(u) / weight));
    }

    keyed.sort((a, b) => b.key.compareTo(a.key));
    return [for (final entry in keyed) entry.item];
  }
}

class _KeyedItem<T> {
  final T item;
  final double key;

  const _KeyedItem(this.item, this.key);
}
