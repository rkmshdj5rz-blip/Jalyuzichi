import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/country_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(AppScope(
    state: state,
    child: JalyuzichiApp(startLoggedIn: state.isLoggedIn),
  ));
}

class JalyuzichiApp extends StatelessWidget {
  const JalyuzichiApp({super.key, required this.startLoggedIn});

  final bool startLoggedIn;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      title: 'Jalyuzichi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: state.themeMode,
      home: startLoggedIn ? const HomeScreen() : const CountryScreen(),
    );
  }
}
