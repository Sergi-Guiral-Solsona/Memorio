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
        title: Text('Modo: $studyModeTitle'),
      ),
      body: decks.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '¡No hay mazos disponibles!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tienes que crear un mazo primero antes de poder iniciar una sesión de estudio con $studyModeTitle.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Te devuelve a la pestaña de Decks o cierra esta vista
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Ir a crear un mazo'),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: decks.length,
        itemBuilder: (context, index) {
          final deck = decks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.style, color: Colors.indigo),
              title: Text(
                deck.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${deck.cards.length} tarjetas'),
              trailing: const Icon(Icons.play_arrow_rounded, color: Colors.green, size: 28),
              onTap: () {
                // AQUÍ SE INICIARÍA LA SESIÓN DE ESTUDIO CON ESTE MAZO Y ESTE MODO
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Iniciando $studyModeTitle con el mazo: ${deck.title}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}