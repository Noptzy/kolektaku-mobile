import 'package:flutter/widgets.dart';

double genreHue(String name) {
  var hash = 17;
  for (final unit in name.toLowerCase().codeUnits) {
    hash = (hash * 31 + unit) & 0xFFFFF;
  }
  return (hash % 360).toDouble();
}

List<Color> genreTint(String name) {
  final hue = genreHue(name);
  return [
    HSLColor.fromAHSL(1, hue, 0.5, 0.32).toColor(),
    HSLColor.fromAHSL(1, (hue + 35) % 360, 0.55, 0.16).toColor(),
  ];
}

class GenreTint extends StatelessWidget {
  const GenreTint({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: genreTint(name),
        ),
      ),
    );
  }
}
