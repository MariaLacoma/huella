import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../theme/app_theme.dart';

import 'detalle_publicacion_page.dart';

class MisPublicacionesPage extends StatefulWidget {
  final int idUsuario;

  const MisPublicacionesPage({super.key, required this.idUsuario});

  @override
  State<MisPublicacionesPage> createState() => _MisPublicacionesPageState();
}

class _MisPublicacionesPageState extends State<MisPublicacionesPage> {
  List<dynamic> publicaciones = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarPublicaciones();
  }

  Future<void> cargarPublicaciones() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/mis_publicaciones.php',
      ).replace(queryParameters: {'id_usuario': widget.idUsuario.toString()});

      final respuesta = await http.get(uri);

      if (respuesta.statusCode != 200) {
        throw Exception('Error al consultar las publicaciones.');
      }

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (datos['ok'] != true) {
        throw Exception(
          datos['mensaje'] ?? 'No se pudieron cargar las publicaciones.',
        );
      }

      if (!mounted) return;

      setState(() {
        publicaciones = datos['publicaciones'] as List<dynamic>;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'No se pudieron cargar las publicaciones.';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis publicaciones'),
        backgroundColor: AppTheme.verdePrincipal,
        foregroundColor: Colors.white,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: cargarPublicaciones,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : publicaciones.isEmpty
          ? const Center(child: Text('Todavía no tenés publicaciones.'))
          : RefreshIndicator(
              onRefresh: cargarPublicaciones,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: publicaciones.length,
                itemBuilder: (context, index) {
                  final publicacion =
                      publicaciones[index] as Map<String, dynamic>;

                  final nombre = publicacion['nombre']?.toString() ?? '';

                  final especie = publicacion['especie']?.toString() ?? '';

                  final tipo =
                      publicacion['tipo']?.toString().toLowerCase() ?? '';
                  final estado =
                      publicacion['estado']?.toString().toLowerCase() ?? '';

                  final String tipoVisible;
                  if (tipo == 'perdida') {
                    tipoVisible = 'Mascota perdida';
                  } else if (tipo == 'encontrada') {
                    tipoVisible = 'Mascota encontrada';
                  } else {
                    tipoVisible = publicacion['tipo']?.toString() ?? '';
                  }

                  final String estadoVisible;
                  if (estado == 'encontrada' && tipo == 'perdida') {
                    estadoVisible = '¡La mascota fue encontrada!';
                  } else if (estado == 'encontrada' && tipo == 'encontrada') {
                    estadoVisible = '¡La mascota volvió con su familia!';
                  } else if (estado == 'activa' && tipo == 'perdida') {
                    estadoVisible = 'Se sigue buscando';
                  } else if (estado == 'activa' && tipo == 'encontrada') {
                    estadoVisible = 'Se busca a su familia';
                  } else {
                    estadoVisible = publicacion['estado']?.toString() ?? '';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '${ApiConfig.baseUrl}/${publicacion['foto']}',
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 75,
                              height: 75,
                              color: AppTheme.verdeClaro,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.verdePrincipal,
                              ),
                            );
                          },
                        ),
                      ),

                      title: Text(
                        nombre.isEmpty ? especie : nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                     subtitle: Text('$tipoVisible\n$estadoVisible'),

                      onTap: () async {
                        final resultado = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetallePublicacionPage(
                              publicacion: publicacion,
                              idUsuario: widget.idUsuario,
                            ),
                          ),
                        );

                        if (resultado == true && mounted) {
                          await cargarPublicaciones();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
