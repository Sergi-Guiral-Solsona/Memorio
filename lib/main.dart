import 'package:memorio/barrel_file.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Carga el paquete de traducciones
  await LocalizationService.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Random_TEXT'.loc),
        ),
      ),
    );
  }
}