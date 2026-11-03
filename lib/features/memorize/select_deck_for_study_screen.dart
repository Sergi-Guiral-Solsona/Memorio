import 'package:flutter/material.dart';
import 'package:memorio/barrel_file.dart';

class SelectDeckForStudyScreen extends StatelessWidget {
  final String studyModeTitle;
  final List<Deck> decks;

  const SelectDeckForStudyScreen({
    super.key,
    required this.studyModeTitle,
    required this.decks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${'KEY_MODE'.loc} : $studyModeTitle'),
      ),
      body:  ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: decks.length,
        itemBuilder: (context, index) {
          final deck = decks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: const Icon(Icons.style, color: Colors.indigo),
              title: Text(
                deck.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${deck.cards.length} ${'KEY_CARDS'.loc}'),
              trailing: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.green,
                size: 28,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Iniciando $studyModeTitle con el mazo: ${deck.title}',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}