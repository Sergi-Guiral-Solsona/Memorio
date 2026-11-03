import 'package:memorio/barrel_file.dart';

class EmptyDecksMemorizeView extends StatelessWidget {
  const EmptyDecksMemorizeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
             Text(
              'KEY_NO_DECKS'.loc,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => BottomNavScreen.of(context)?.openDecks(),
              icon: const Icon(Icons.arrow_back),
              label:  Text('KEY_GO_TO_CREATE_DECK'.loc),
            ),
          ],
        ),
      ),
    );
  }
}