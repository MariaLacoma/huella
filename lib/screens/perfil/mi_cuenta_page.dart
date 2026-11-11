
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'editar_perfil_page.dart';
import 'cambiar_correo_page.dart';
import 'cambiar_contrasena_page.dart';

class MiCuentaPage extends StatefulWidget {
  final int idUsuario;
  final String nombre;
  final String email;
  final String telefono;

  const MiCuentaPage({
    super.key,
    required this.idUsuario,
    required this.nombre,
    required this.email,
    required this.telefono,
  });

  @override
  State<MiCuentaPage> createState() => _MiCuentaPageState();
}

class _MiCuentaPageState extends State<MiCuentaPage> {
  late String nombreActual;
  late String telefonoActual;

  @override
  void initState() {
    super.initState();

    nombreActual = widget.nombre;
    telefonoActual = widget.telefono;
  }

  Future<void> _editarPerfil() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilPage(
          idUsuario: widget.idUsuario,
          nombre: nombreActual,
          email: widget.email,
          telefono: telefonoActual,
        ),
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        nombreActual = resultado['nombre'];
        telefonoActual = resultado['telefono'];
      });
    }
  }

  void _abrirCambiarCorreo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CambiarCorreoPage(
          email: widget.email,
        ),
      ),
    );
  }

  void _abrirCambiarContrasena() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CambiarContrasenaPage(
          email: widget.email,
        ),
      ),
    );
  }

  Widget _filaAcceso({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icono,
        color: AppTheme.verdePrincipal,
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textoPrincipal,
        ),
      ),
      subtitle: Text(
        descripcion,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textoSecundario,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textoSecundario,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        backgroundColor: AppTheme.fondo,
        foregroundColor: AppTheme.textoPrincipal,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.verdeClaro,
                child: Icon(
                  Icons.person,
                  size: 45,
                  color: AppTheme.verdePrincipal,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Información de tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 28),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Información personal',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textoPrincipal,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.person_outline,
                          color: AppTheme.verdePrincipal,
                        ),
                        title: const Text(
                          'Nombre',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                        subtitle: Text(
                          nombreActual,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.phone_outlined,
                          color: AppTheme.verdePrincipal,
                        ),
                        title: const Text(
                          'Teléfono',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                        subtitle: Text(
                          telefonoActual.isEmpty
                              ? 'No registrado'
                              : telefonoActual,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      OutlinedButton.icon(
                        onPressed: _editarPerfil,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modificar datos personales'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Seguridad y acceso',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textoPrincipal,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _filaAcceso(
                        icono: Icons.email_outlined,
                        titulo: 'Correo electrónico',
                        descripcion: widget.email,
                        onTap: _abrirCambiarCorreo,
                      ),

                      const Divider(height: 1),

                      _filaAcceso(
                        icono: Icons.lock_outline,
                        titulo: 'Contraseña',
                        descripcion: 'Actualizá tu contraseña',
                        onTap: _abrirCambiarContrasena,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
