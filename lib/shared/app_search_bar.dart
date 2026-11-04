import 'package:memorio/barrel_file.dart';

/// Buscador reutilizable. Solo avisa del texto con [onChanged]; el filtrado
/// lo hace quien lo usa (ver `matchesSearch` en search_utils.dart).
class AppSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? hintText;
  final EdgeInsetsGeometry padding;

  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hintText,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // actualiza el botón de borrar
    widget.onChanged(value);
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'KEY_SEARCH'.loc,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.close), onPressed: _clear),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
