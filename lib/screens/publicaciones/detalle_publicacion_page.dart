import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';

class DetallePublicacionPage extends StatelessWidget {
  final Map<String, dynamic> publicacion;

  const DetallePublicacionPage({super.key, required this.publicacion});

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
    final estado = publicacion['estado'].toString();

    final bool esPerdida = tipo.toLowerCase() == 'perdida';

    final latitud = double.parse(publicacion['latitud'].toString());
    final longitud = double.parse(publicacion['longitud'].toString());

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de publicación')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              'http://10.0.2.2/huella_api/${publicacion['foto']}',
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
                          valor: estado,
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
