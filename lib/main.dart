import 'package:memorio/barrel_file.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El orden importa: primero los ajustes guardados, luego lo que los lee.
  await SettingsService.instance.init();
  ThemeService.instance.load();
  await LocalizationService.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    LocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LocalizationService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    // Marca todo el árbol como "sucio", incluidos los widgets const, para que
    // se reevalúen todos los `.loc` sin perder la navegación.
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final themes = ThemeService.instance;
    final localization = LocalizationService.instance;

    // AnimatedBuilder vale para cualquier Listenable y funciona en todas las
    // versiones de Flutter.
    return AnimatedBuilder(
      animation: Listenable.merge([themes, localization]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Memorio',
          theme: themes.lightTheme,
          darkTheme: themes.darkTheme,
          themeMode: themes.mode,
          // Los textos de la app salen del CSV (.loc), así que no hace falta
          // flutter_localizations. Solo se ajusta la dirección del texto para
          // los idiomas de derecha a izquierda (árabe...).
          builder: (context, child) => Directionality(
            textDirection: localization.textDirection,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const BottomNavScreen(),
        );
      },
    );
  }
}
