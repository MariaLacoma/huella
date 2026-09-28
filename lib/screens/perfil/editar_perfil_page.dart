import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';

class EditarPerfilPage extends StatefulWidget {
  final int idUsuario;
  final String nombre;
  final String telefono;
  final String email;

  const EditarPerfilPage({
    super.key,
    required this.idUsuario,
    required this.nombre,
    required this.telefono,
    required this.email,
  });

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  late TextEditingController nombreController;
  late TextEditingController telefonoController;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.nombre);
    telefonoController = TextEditingController(text: widget.telefono);
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    super.dispose();
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

              // Ícono
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppTheme.verdeClaro,
                child: Icon(
                  Icons.edit,
                  size: 45,
                  color: AppTheme.verdePrincipal,
                ),
              ),

              const SizedBox(height: 20),

              // Título
              const Text(
                'Modificar datos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Actualizá tu información personal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 30),

              // Nombre
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextField(
                controller: telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 24),

              // Guardar cambios
              ElevatedButton.icon(
                onPressed: () async {
                  final respuesta = await http.post(
                    Uri.parse(
                      'http://10.0.2.2/huella_api/actualizar_usuario.php',
                    ),
                    body: {
                      'id_usuario': widget.idUsuario.toString(),
                      'nombre': nombreController.text,
                      'telefono': telefonoController.text,
                    },
                  );

                  print(respuesta.body);

                  if (respuesta.body.contains('"ok":true')) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            '¡Listo!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.verdePrincipal,
                            ),
                          ),
                          content: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'Tus datos fueron actualizados correctamente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context, {
                                  'nombre': nombreController.text,
                                  'telefono': telefonoController.text,
                                });
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudieron actualizar los datos'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),

              const SizedBox(height: 12),

              // Cancelar
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}