
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/inicio/inicio_page.dart';

Future<void> probarConexionSupabase() async {
  try {
    final respuesta = await Supabase.instance.client
        .from('usuario')
        .select('id_usuario')
        .limit(1);

    debugPrint('Conexión con Supabase correcta: $respuesta');
  } catch (e) {
    debugPrint('Error al conectar con Supabase: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabasePublishableKey,
  );

  await probarConexionSupabase();
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








  



