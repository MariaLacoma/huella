import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'usuarios_page.dart';
import '../inicio/inicio_page.dart';

class PanelAdministrador extends StatelessWidget {
  const PanelAdministrador({super.key});

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

              // Ícono
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
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

              // Consultar usuarios
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

              // Cerrar sesión
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
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
                              Navigator.pop(context);
                            },
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const InicioPage(),
                                ),
                                (route) => false,
                              );
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