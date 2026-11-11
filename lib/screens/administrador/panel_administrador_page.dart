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
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppTheme.verdeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 50,
                  color: AppTheme.verdePrincipal,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Panel de administrador',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestioná las cuentas y funciones administrativas de HUELLA.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsuariosPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('Consultar usuarios'),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PublicacionesAdministradorPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.pets),
                label: const Text('Gestionar publicaciones'),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportesAdministradorPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.flag),
                label: const Text('Gestionar reportes'),
              ),
              const SizedBox(height: 12),

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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
