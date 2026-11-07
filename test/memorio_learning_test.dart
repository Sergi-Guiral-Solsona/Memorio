import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:memorio/features/decks/models/card_model.dart';
import 'package:memorio/features/memorize/study/memorio_learning.dart';

CardModel _card({int ok = 0, int ko = 0}) => CardModel(
      id: 'x',
      front: 'front',
      back: 'back',
      correctCount: ok,
      incorrectCount: ko,
    );

void main() {
  group('MemorioLearning.weightOf', () {
    test('una tarjeta nueva tiene la prioridad máxima', () {
      expect(MemorioLearning.weightOf(_card()), MemorioLearning.unseenWeight);
    });

    test('el peso es el porcentaje de fallos', () {
      expect(MemorioLearning.weightOf(_card(ok: 2, ko: 1)), closeTo(1 / 3, 1e-9));
      expect(MemorioLearning.weightOf(_card(ok: 1, ko: 3)), closeTo(0.75, 1e-9));
    });

    test('una tarjeta sin fallos nunca llega a peso 0 (siempre acaba saliendo)', () {
      expect(MemorioLearning.weightOf(_card(ok: 10)), MemorioLearning.minWeight);
      expect(MemorioLearning.minWeight, greaterThan(0));
    });
  });

  group('MemorioLearning.weightedOrder', () {
    test('todas las tarjetas salen exactamente una vez', () {
      final items = List.generate(50, (i) => i);
      final ordered = MemorioLearning.weightedOrder<int>(
        items,
        (i) => (i % 5 + 1) / 5,
        random: math.Random(1),
      );

      expect(ordered.length, items.length);
      expect(ordered.toSet(), items.toSet());
    });

    test('la de más peso sale antes la mayoría de las veces (80 vs 4)', () {
      final random = math.Random(42);
      const trials = 4000;
      var lightFirst = 0;

      for (var i = 0; i < trials; i++) {
        final ordered = MemorioLearning.weightedOrder<String>(
          ['alta', 'baja'],
          (s) => s == 'alta' ? 0.80 : 0.04,
          random: random,
        );
        if (ordered.first == 'baja') lightFirst++;
      }

      // Teórico: 0.04 / (0.80 + 0.04) ≈ 4.8 %
      expect(lightFirst, greaterThan(0)); // la de 4 SÍ puede salir antes
      expect(lightFirst / trials, closeTo(0.048, 0.015));
    });

    test('las tarjetas de más peso tienen una posición media menor', () {
      final random = math.Random(7);
      final items = ['a', 'b', 'c'];
      final weight = {'a': 1.0, 'b': 0.3, 'c': 0.05};
      final positionSum = {'a': 0, 'b': 0, 'c': 0};

      for (var i = 0; i < 3000; i++) {
        final ordered = MemorioLearning.weightedOrder<String>(
          items,
          (s) => weight[s]!,
          random: random,
        );
        for (var p = 0; p < ordered.length; p++) {
          positionSum[ordered[p]] = positionSum[ordered[p]]! + p;
        }
      }

      expect(positionSum['a']!, lessThan(positionSum['b']!));
      expect(positionSum['b']!, lessThan(positionSum['c']!));
    });
  });
}
