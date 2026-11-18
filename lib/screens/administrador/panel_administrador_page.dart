import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'usuarios_page.dart';
import '../inicio/inicio_page.dart';

import 'publicaciones_administrador_page.dart';

import 'reportes_administrador_page.dart';

class PanelAdministrador extends StatelessWidget {
  const PanelAdministrador({super.key});

  Future<void> cerrarSesion(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const InicioPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFFCEBEA),
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    content: const Text(
      'No se pudo cerrar la sesión. Intentá nuevamente.',
      style: TextStyle(
        color: AppTheme.error,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);

      debugPrint('Error al cerrar sesión: $e');
    }
  }


Widget _tarjetaAdministracion(
  BuildContext context, {
  required IconData icono,
  required String titulo,
  required String descripcion,
  required Widget destino,
}) {
  return Card(
    elevation: 1,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: AppTheme.verdeClaro,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => destino,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.verdeClaro,
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
              ),
              child: Icon(
                icono,
                color: AppTheme.verdePrincipal,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textoSecundario,
            ),
          ],
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
   
body: SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Encabezado
        const Icon(
          Icons.admin_panel_settings_outlined,
          size: 65,
          color: AppTheme.verdePrincipal,
        ),

        const SizedBox(height: 16),

        const Text(
          'Panel de administración',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppTheme.textoPrincipal,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Gestioná HUELLA desde un solo lugar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textoSecundario,
          ),
        ),

        const SizedBox(height: 32),

        // Gestión de usuarios
        _tarjetaAdministracion(
          context,
          icono: Icons.people_outline,
          titulo: 'Usuarios',
          descripcion: 'Consultar y gestionar cuentas.',
          destino: const UsuariosPage(),
        ),

        const SizedBox(height: 14),

        // Gestión de publicaciones
        _tarjetaAdministracion(
          context,
          icono: Icons.pets_outlined,
          titulo: 'Publicaciones',
          descripcion: 'Consultar y gestionar publicaciones.',
          destino: const PublicacionesAdministradorPage(),
        ),

        const SizedBox(height: 14),

        // Gestión de reportes
        _tarjetaAdministracion(
          context,
          icono: Icons.flag_outlined,
          titulo: 'Reportes',
          descripcion: 'Revisar reportes realizados por usuarios.',
          destino: const ReportesAdministradorPage(),
        ),


        const SizedBox(height: 30),



        // Cerrar sesión
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  content: const Text(
                    '¿Querés cerrar tu sesión de HUELLA?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        cerrarSesion(context);
                      },
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                );
              },
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: const BorderSide(color: AppTheme.error),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    ),
  ),
),

    );
  }
}
