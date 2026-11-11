
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';
import 'ubicacion_publicacion_page.dart';

class ConsultarAvistamientosPage extends StatefulWidget {
  final Map<String, dynamic> publicacion;

  const ConsultarAvistamientosPage({
    super.key,
    required this.publicacion,
  });

  @override
  State<ConsultarAvistamientosPage> createState() =>
      _ConsultarAvistamientosPageState();
}

class _ConsultarAvistamientosPageState
    extends State<ConsultarAvistamientosPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> avistamientos = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarAvistamientos();
  }

  Future<void> cargarAvistamientos() async {
    if (mounted) {
      setState(() {
        cargando = true;
        error = null;
      });
    }

    try {
      final idPublicacion =
          int.tryParse(widget.publicacion['id_publicacion'].toString());

      if (idPublicacion == null) {
        throw Exception('No se pudo identificar la publicación.');
      }

      final resultado = await supabase
          .from('avistamiento')
          .select()
          .eq('id_publicacion', idPublicacion)
          .order('fecha', ascending: false);

      if (!mounted) return;

      setState(() {
        avistamientos = List<Map<String, dynamic>>.from(resultado);
        cargando = false;
        error = null;
      });
    } catch (e) {
      debugPrint('Error al consultar avistamientos: $e');

      if (!mounted) return;

      setState(() {
        cargando = false;
        error = 'No se pudieron cargar los avistamientos.';
      });
    }
  }

  String formatearFecha(String fecha) {
    final partes = fecha.split('-');

    if (partes.length != 3) return fecha;

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  List<Map<String, dynamic>> obtenerAvistamientosConUbicacion() {
    return avistamientos.where((avistamiento) {
      final latitud = double.tryParse(
        (avistamiento['latitud'] ?? '').toString(),
      );

      final longitud = double.tryParse(
        (avistamiento['longitud'] ?? '').toString(),
      );

      return latitud != null &&
          longitud != null &&
          latitud >= -90 &&
          latitud <= 90 &&
          longitud >= -180 &&
          longitud <= 180;
    }).toList();
  }

  void verTodosEnMapa() {
    final puntos = obtenerAvistamientosConUbicacion();

  if (puntos.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppTheme.verdeClaro,
      behavior: SnackBarBehavior.floating,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      content: const Text(
        'No hay avistamientos con ubicaciones disponibles.',
        style: TextStyle(
          color: AppTheme.verdeOscuro,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
  return;
}

    final primerPunto = puntos.first;

    final latitud = double.parse(
      primerPunto['latitud'].toString(),
    );

    final longitud = double.parse(
      primerPunto['longitud'].toString(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UbicacionPublicacionPage(
          latitudInicial: latitud,
          longitudInicial: longitud,
          soloLectura: true,
          titulo: 'Mapa de avistamientos',
          marcadoresAdicionales: puntos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puntosConUbicacion =
        obtenerAvistamientosConUbicacion();

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Avistamientos'),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: cargarAvistamientos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : avistamientos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Todavía no hay avistamientos registrados '
                          'para esta publicación.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargarAvistamientos,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Avistamientos registrados: '
                            '${avistamientos.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textoPrincipal,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (puntosConUbicacion.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        color: AppTheme.verdePrincipal,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Mapa de avistamientos',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textoPrincipal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hay ${puntosConUbicacion.length} '
                                    'puntos disponibles en el mapa.',
                                    style: const TextStyle(
                                      color: AppTheme.textoSecundario,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: verTodosEnMapa,
                                      icon: const Icon(Icons.map),
                                      label: const Text(
                                        'Ver todos en el mapa',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.verdePrincipal,
                                        foregroundColor: Colors.white,
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          const Text(
                            'Detalle de los avistamientos',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textoPrincipal,
                            ),
                          ),

                          const SizedBox(height: 12),

                          ...avistamientos.map((avistamiento) {
                            final descripcion =
                                (avistamiento['descripcion'] ?? '')
                                    .toString()
                                    .trim();

                            final tieneUbicacion =
                                puntosConUbicacion.contains(avistamiento);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 1,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppTheme.verdeClaro.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.verdeClaro,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.pets_outlined,
                                            color: AppTheme.verdePrincipal,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Avistamiento registrado',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: AppTheme
                                                      .textoPrincipal,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formatearFecha(
                                                  avistamiento['fecha']
                                                          ?.toString() ??
                                                      '',
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme
                                                      .textoPrincipal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.fondo,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.notes_outlined,
                                            color: AppTheme.verdePrincipal,
                                            size: 21,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              descripcion.isEmpty
                                                  ? 'Sin descripción.'
                                                  : descripcion,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppTheme
                                                    .textoPrincipal,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 20,
                                          color: tieneUbicacion
                                              ? AppTheme.verdePrincipal
                                              : AppTheme.textoSecundario,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            tieneUbicacion
                                                ? 'Ubicación registrada en el mapa'
                                                : 'Sin ubicación disponible',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme
                                                  .textoSecundario,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
    );
  }
}
