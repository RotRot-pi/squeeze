import 'package:fluent_ui/fluent_ui.dart';

import 'package:squeeze/features/home/presentation/pages/home_page.dart';
import 'package:squeeze/app/theme.dart';
import 'package:squeeze/core/constants/app_constants.dart';

class SqueezeApp extends StatelessWidget {
  const SqueezeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: getTheme(Brightness.light),
      darkTheme: getTheme(Brightness.dark),
      home: const HomePage(),
    );
  }
}
