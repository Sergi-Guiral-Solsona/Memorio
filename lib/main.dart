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
      debugShowCheckedModeBanner: false,
      title: 'Memorio',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const BottomNavScreen(),
    );
  }
}