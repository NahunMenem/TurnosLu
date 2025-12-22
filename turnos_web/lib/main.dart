import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/servicios_screen.dart';

void main() async {
  // 🔑 OBLIGATORIO para usar await antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 🇦🇷 Inicializar locale español
  await initializeDateFormatting('es', null);

  runApp(const TurnosApp());
}

class TurnosApp extends StatelessWidget {
  const TurnosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Turnos',
      debugShowCheckedModeBanner: false,

      // 🌍 Locale global
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🎨 Theme
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),

      // 🏠 Home
      home: const ServiciosScreen(),
    );
  }
}
