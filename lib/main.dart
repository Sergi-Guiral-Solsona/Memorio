import 'package:flutter/material.dart';

void main() {
  runApp(const MiAppEstudio());
}

class MiAppEstudio extends StatelessWidget {
  const MiAppEstudio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Memorización',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Mazos de Estudio'),
        ),
        body: const Center(
          child: Text(
            '¡Hola, Mundo! Aquí empezarán mis tarjetas.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}