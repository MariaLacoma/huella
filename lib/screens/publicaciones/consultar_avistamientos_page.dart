import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../theme/app_theme.dart';

import 'ubicacion_publicacion_page.dart';

class ConsultarAvistamientosPage extends StatefulWidget {
  final Map<String, dynamic> publicacion;

  const ConsultarAvistamientosPage({super.key, required this.publicacion});

  @override
  State<ConsultarAvistamientosPage> createState() =>
      _ConsultarAvistamientosPageState();
}

class _ConsultarAvistamientosPageState
    extends State<ConsultarAvistamientosPage> {
  List<dynamic> avistamientos = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarAvistamientos();
  }

  Future<void> cargarAvistamientos() async {
    try {
      final respuesta = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/consultar_avistamientos.php'
          '?id_publicacion=${widget.publicacion['id_publicacion']}',
        ),
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (respuesta.statusCode == 200 && datos['ok'] == true) {
        if (!mounted) return;

        setState(() {
          avistamientos = datos['avistamientos'] as List<dynamic>;
          cargando = false;
          error = null;
        });
      } else {
        throw Exception(
          datos['mensaje'] ?? 'No se pudieron consultar los avistamientos.',
        );
      }
    } catch (e) {
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

  void verUbicacion(Map<String, dynamic> avistamiento) {
    final latitud = double.tryParse(avistamiento['latitud'].toString());
    final longitud = double.tryParse(avistamiento['longitud'].toString());

    if (latitud == null || longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La ubicación no está disponible.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UbicacionPublicacionPage(
          latitudInicial: latitud,
          longitudInicial: longitud,
          soloLectura: true,
          titulo: 'Ubicación del avistamiento',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(title: const Text('Avistamientos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          cargando = true;
                          error = null;
                        });
                        cargarAvistamientos();
                      },
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: avistamientos.length,
                itemBuilder: (context, index) {
                  final avistamiento =
                      avistamientos[index] as Map<String, dynamic>;

                  final descripcion = (avistamiento['descripcion'] ?? '')
                      .toString()
                      .trim();

                 
return Card(
  margin: const EdgeInsets.only(bottom: 16),
  elevation: 1,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(
      color: AppTheme.verdeClaro.withValues(alpha: 0.6),
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.verdeClaro,
                borderRadius: BorderRadius.circular(12),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Avistamiento registrado',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatearFecha(
                      avistamiento['fecha'].toString(),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textoPrincipal,
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: AppTheme.textoPrincipal,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => verUbicacion(avistamiento),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver ubicación en el mapa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdePrincipal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

                },
              ),
            ),
    );
  }
}
