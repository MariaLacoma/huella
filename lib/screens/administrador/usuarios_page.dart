import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';


class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final String urlUsuarios = 'http://10.0.2.2/huella_api/listar_usuarios.php';

  List<dynamic> usuarios = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    final respuesta = await http.get(Uri.parse(urlUsuarios));

    print(respuesta.body);

    if (respuesta.body.contains('"ok":true')) {
      final datos = jsonDecode(respuesta.body);

      setState(() {
        usuarios = datos['usuarios'];
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botón volver
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ),

              const SizedBox(height: 12),

              // Ícono
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.verdeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people,
                  size: 45,
                  color: AppTheme.verdePrincipal,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Usuarios registrados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Usuarios registrados en HUELLA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: usuarios.length,
                        itemBuilder: (context, index) {
                          final usuario = usuarios[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.verdeClaro,
                                child: Icon(
                                  Icons.person,
                                  color: AppTheme.verdePrincipal,
                                ),
                              ),
                              title: Text(
                                usuario['nombre'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoPrincipal,
                                ),
                              ),
                              subtitle: Text(
                                usuario['email'],
                                style: const TextStyle(
                                  color: AppTheme.textoSecundario,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}