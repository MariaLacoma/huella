import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/inicio/inicio_page.dart';

void main() {
  runApp(const HuellaApp());
}

class HuellaApp extends StatelessWidget {
  const HuellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HUELLA',
      theme: AppTheme.tema,
      home: const InicioPage(),
    );
  }
}







  



