import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'editar_perfil_page.dart';
import '../inicio/inicio_page.dart';

class PerfilPage extends StatefulWidget {
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

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late String nombreActual;
  late String telefonoActual;

  @override
  void initState() {
    super.initState();

    nombreActual = widget.nombre;
    telefonoActual = widget.telefono;
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

              // Ícono del perfil
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppTheme.verdeClaro,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: AppTheme.verdePrincipal,
                ),
              ),

              const SizedBox(height: 20),

              // Título
              const Text(
                'Mi perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Consultá y modificá tus datos personales.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 30),

              // Tarjeta con los datos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.person_outline,
                          color: AppTheme.verdePrincipal,
                        ),
                        title: const Text(
                          'Nombre',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                        subtitle: Text(
                          nombreActual,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),

                      const Divider(),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.email_outlined,
                          color: AppTheme.verdePrincipal,
                        ),
                        title: const Text(
                          'Correo electrónico',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                        subtitle: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),

                      const Divider(),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.phone_outlined,
                          color: AppTheme.verdePrincipal,
                        ),
                        title: const Text(
                          'Teléfono',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                        subtitle: Text(
                          telefonoActual,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Modificar datos
              ElevatedButton.icon(
                onPressed: () async {
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

                  if (resultado != null) {
                    setState(() {
                      nombreActual = resultado['nombre'];
                      telefonoActual = resultado['telefono'];
                    });
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modificar datos'),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}