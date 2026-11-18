import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Utilidades de ordenación que pueden usar varios métodos (cada uno les pasa
/// SUS estadísticas; aquí no se lee nada de ningún método concreto).
class WeightedOrder {
  WeightedOrder._();

  /// Peso de una tarjeta que el método aún no ha visto nunca.
  static const double unseenWeight = 1.0;

  /// Peso mínimo: garantiza que hasta las tarjetas dominadas vuelvan a salir.
  static const double minWeight = 0.03;

  /// Peso según el porcentaje de fallos de [stats] (0.03 .. 1.0).
  ///   * Sin intentos -> 1.0 (sale pronto)
  ///   * Nunca fallada -> mínimo (nunca 0, así siempre sale)
  static double errorWeight(MethodStats stats) {
    if (stats.attempts == 0) return unseenWeight;
    return math.max(minWeight, stats.errorRate);
  }

  /// Devuelve [items] en un orden aleatorio ponderado por [weightOf]: cuanto
  /// más peso, más probable es que salga antes, pero no está garantizado. Todas
  /// salen exactamente una vez.
  ///
  /// Técnica: Efraimidis–Spirakis. A cada elemento se le asigna la clave
  /// `u^(1/peso)` con `u` aleatorio en (0,1) y se ordena de mayor a menor
  /// (aquí con su logaritmo, que ordena igual y es numéricamente estable).
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
