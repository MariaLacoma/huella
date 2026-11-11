
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'mi_cuenta_page.dart';
import '../inicio/inicio_page.dart';
import '../publicaciones/buscar_mascotas_page.dart';
import '../publicaciones/crear_publicacion_page.dart';
import '../publicaciones/mis_publicaciones_page.dart';

class PerfilPage extends StatelessWidget {
  final int idUsuario;
  final String nombre;
  final String email;
  final String telefono;

  const PerfilPage({
    super.key,
    required this.idUsuario,
    required this.nombre,
    required this.email,
    required this.telefono,
  });

  void _abrirMiCuenta(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MiCuentaPage(
          idUsuario: idUsuario,
          nombre: nombre,
          email: email,
          telefono: telefono,
        ),
      ),
    );
  }

  void _cerrarSesion(BuildContext context) {
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
  }

  Widget _opcionPrincipal({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.verdeClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  size: 28,
                  color: AppTheme.verdePrincipal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
  title: const Text('HUELLA'),
  backgroundColor: AppTheme.fondo,
  foregroundColor: AppTheme.textoPrincipal,
  elevation: 0,
  actions: [
    PopupMenuButton<String>(
      tooltip: 'Mi cuenta',
      icon: const Icon(
  Icons.account_circle_outlined,
  size: 32,
),
      onSelected: (opcion) {
        if (opcion == 'cuenta') {
          _abrirMiCuenta(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'cuenta',
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppTheme.verdePrincipal,
              ),
              SizedBox(width: 10),
              Text('Mi cuenta'),
            ],
          ),
        ),
      ],
    ),
  ],
),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              Text(
                '¡Hola, $nombre!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '¿Qué querés hacer hoy?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textoSecundario,
                ),
              ),

              const SizedBox(height: 28),

              _opcionPrincipal(
                context: context,
                icono: Icons.search,
                titulo: 'Buscar mascotas',
                descripcion: 'Consultá las publicaciones de mascotas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuscarMascotasPage(
                        idUsuario: idUsuario,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _opcionPrincipal(
                context: context,
                icono: Icons.add_a_photo_outlined,
                titulo: 'Nueva publicación',
                descripcion: 'Publicá una mascota perdida o encontrada',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CrearPublicacionPage(
                        idUsuario: idUsuario,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _opcionPrincipal(
                context: context,
                icono: Icons.list_alt,
                titulo: 'Mis publicaciones',
                descripcion: 'Consultá y administrá tus publicaciones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MisPublicacionesPage(
                        idUsuario: idUsuario,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

             

         

              OutlinedButton.icon(
                onPressed: () => _cerrarSesion(context),
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
