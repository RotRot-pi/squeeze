import 'package:fluent_ui/fluent_ui.dart';

FluentThemeData getTheme(Brightness brightness) {
  return FluentThemeData(
    brightness: brightness,
    visualDensity: VisualDensity.standard,
  );
}
