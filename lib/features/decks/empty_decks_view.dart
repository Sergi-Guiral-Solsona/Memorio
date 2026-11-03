import 'package:memorio/barrel_file.dart';

class EmptyDecksView extends StatelessWidget {
  final VoidCallback onCreateDeckPressed;

  const EmptyDecksView({
    super.key,
    required this.onCreateDeckPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'KEY_NO_DECKS'.loc,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'KEY_CREATE_FIRST_DECK'.loc,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateDeckPressed,
              icon: const Icon(Icons.add),
              label: Text('KEY_CREATE_DECK'.loc),
            ),
          ],
        ),
      ),
    );
  }
}