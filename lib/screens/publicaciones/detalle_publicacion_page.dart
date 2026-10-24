import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import 'editar_publicacion_page.dart';

import 'registrar_avistamiento_page.dart';

import 'consultar_avistamientos_page.dart';

Future<Map<String, dynamic>> marcarMascotaEncontrada({
  required int idPublicacion,
  required int idUsuario,
}) async {
  final respuesta = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/marcar_encontrada.php'),
    body: {
      'id_publicacion': idPublicacion.toString(),
      'id_usuario': idUsuario.toString(),
    },
  );

  return jsonDecode(respuesta.body) as Map<String, dynamic>;
}

class DetallePublicacionPage extends StatelessWidget {
  final Map<String, dynamic> publicacion;
  final int? idUsuario;

  const DetallePublicacionPage({
    super.key,
    required this.publicacion,
    this.idUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = publicacion['nombre'].toString().isEmpty
        ? 'Sin nombre'
        : publicacion['nombre'].toString();

    final tipo = publicacion['tipo'].toString();
    final especie = publicacion['especie'].toString();
    final sexo = publicacion['sexo'].toString();
    final descripcion = publicacion['descripcion'].toString();
    final fecha = publicacion['fecha'].toString();

    final bool esPerdida = tipo.toLowerCase() == 'perdida';

    final estado = publicacion['estado'].toString().toLowerCase();

    final String estadoVisible;

if (estado == 'encontrada') {
  if (tipo.toLowerCase() == 'perdida') {
    estadoVisible = '¡La mascota fue encontrada!';
  } else {
    estadoVisible = '¡La mascota volvió con su familia!';
  }
} else if (estado == 'activa') {
  if (tipo.toLowerCase() == 'perdida') {
    estadoVisible = 'Se sigue buscando';
  } else {
    estadoVisible = 'Se busca a su familia';
  }
} else {
  estadoVisible = estado;
}

    final latitud = double.parse(publicacion['latitud'].toString());
    final longitud = double.parse(publicacion['longitud'].toString());

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de publicación')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              '${ApiConfig.baseUrl}/${publicacion['foto']}',
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 280,
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 60),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.pets,
                        size: 20,
                        color: AppTheme.verdePrincipal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sexo == 'null' || sexo.isEmpty
                            ? especie
                            : '$especie · $sexo',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: AppTheme.verdePrincipal,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Descripción',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textoPrincipal,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          descripcion,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icono: Icons.calendar_today_outlined,
                          titulo: 'Fecha',
                          valor: fecha,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _InfoCard(
                          icono: Icons.circle,
                          titulo: 'Estado',
                          valor: estadoVisible,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(latitud, longitud),
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.huella',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(latitud, longitud),
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 50,
                                  color: AppTheme.verdePrincipal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (idUsuario != null &&
                      publicacion['id_usuario'].toString() ==
                          idUsuario.toString() &&
                      publicacion['estado'].toString().toLowerCase() ==
                          'activa')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final resultado = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditarPublicacionPage(
                                publicacion: publicacion,
                                idUsuario: idUsuario!,
                              ),
                            ),
                          );

                          if (resultado == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar publicación'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textoPrincipal,
                          side: BorderSide(color: AppTheme.verdeClaro),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                 
                  // Botón para cerrar una publicación propia
                  if (idUsuario != null &&
                      publicacion['id_usuario'].toString() ==
                          idUsuario.toString() &&
                      publicacion['estado'].toString().toLowerCase() ==
                          'activa' &&
                      (publicacion['tipo'].toString().toLowerCase() ==
                              'perdida' ||
                          publicacion['tipo'].toString().toLowerCase() ==
                              'encontrada'))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final tipoPublicacion =
                              publicacion['tipo'].toString().toLowerCase();

                          final mensajeConfirmacion =
                              tipoPublicacion == 'perdida'
                                  ? '¿Confirmás que encontraste a tu mascota?'
                                  : '¿Confirmás que la mascota volvió con su familia?';

                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cerrar publicación'),
                              content: Text(mensajeConfirmacion),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Confirmar'),
                                ),
                              ],
                            ),
                          );

                          if (confirmar != true || !context.mounted) return;

                          try {
                            final resultado = await marcarMascotaEncontrada(
                              idPublicacion: int.parse(
                                publicacion['id_publicacion'].toString(),
                              ),
                              idUsuario: idUsuario!,
                            );

                            if (!context.mounted) return;

                           
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: resultado['ok'] == true
        ? const Color(0xFF238653)
        : const Color(0xFFB93838),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
    content: Row(
      children: [
        Icon(
          resultado['ok'] == true
              ? Icons.check_circle_outline
              : Icons.error_outline,
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            resultado['mensaje']?.toString() ??
                'No se pudo actualizar la publicación.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  ),
);


                            if (resultado['ok'] == true) {
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            if (!context.mounted) return;

                           
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFFB93838),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
    content: const Row(
      children: [
        Icon(Icons.cloud_off_outlined, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'No se pudo conectar con el servidor.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  ),
);

                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          publicacion['tipo'].toString().toLowerCase() ==
                                  'perdida'
                              ? '¡La encontré!'
                              : '¡Volvió con su familia!',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF238653),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),


                  const SizedBox(height: 12),

                  if (publicacion['estado'].toString().toLowerCase() ==
                      'activa') ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Avistamientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.verdeClaro),
                      ),
                      child: Column(
                        children: [
                          if (idUsuario != null) ...[
                            ListTile(
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: AppTheme.verdePrincipal,
                              ),
                              title: const Text('Registrar avistamiento'),
                              subtitle: const Text(
                                'Informar dónde viste a la mascota',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RegistrarAvistamientoPage(
                                          idUsuario: idUsuario!,
                                          publicacion: publicacion,
                                        ),
                                  ),
                                );

                                if (!context.mounted) return;

                                if (resultado == true) {
                                
                       }
                              },
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                          ListTile(
                            leading: const Icon(
                              Icons.visibility_outlined,
                              color: AppTheme.verdePrincipal,
                            ),
                            title: const Text('Ver avistamientos'),
                            subtitle: const Text(
                              'Consultar los lugares registrados',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ConsultarAvistamientosPage(
                                        publicacion: publicacion,
                                      ),
                                ),
                              );
                            },
                          ),
                          if (idUsuario == null) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppTheme.verdePrincipal,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '¿Querés registrar un avistamiento? '
                                      'Iniciá sesión o registrate para informar '
                                      'dónde viste a la mascota.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _InfoCard({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: AppTheme.verdePrincipal),

          const SizedBox(height: 10),

          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textoSecundario,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}
