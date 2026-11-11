
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';

class UbicacionPublicacionPage extends StatefulWidget {
  final double latitudInicial;
  final double longitudInicial;
  final bool soloLectura;
  final String titulo;
  final List<Map<String, dynamic>> marcadoresAdicionales;

  const UbicacionPublicacionPage({
    super.key,
    required this.latitudInicial,
    required this.longitudInicial,
    this.soloLectura = false,
    this.titulo = 'Seleccionar ubicación',
    this.marcadoresAdicionales = const [],
  });

  @override
  State<UbicacionPublicacionPage> createState() =>
      _UbicacionPublicacionPageState();
}

class _UbicacionPublicacionPageState
    extends State<UbicacionPublicacionPage> {
  late LatLng ubicacionSeleccionada;

  final MapController controladorMapa = MapController();

  @override
  void initState() {
    super.initState();

    ubicacionSeleccionada = LatLng(
      widget.latitudInicial,
      widget.longitudInicial,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final coordenadas = obtenerCoordenadasAvistamientos();

      if (coordenadas.isNotEmpty) {
        controladorMapa.fitCamera(
          CameraFit.coordinates(
            coordinates: coordenadas,
            padding: const EdgeInsets.all(50),
            maxZoom: 16,
          ),
        );
      }
    });
  }

 List<Map<String, dynamic>> obtenerAvistamientosOrdenados() {
  final avistamientos = widget.marcadoresAdicionales.where((avistamiento) {
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

  avistamientos.sort((a, b) {
    final fechaA = (a['fecha'] ?? '').toString();
    final fechaB = (b['fecha'] ?? '').toString();

    return fechaA.compareTo(fechaB);
  });

  return avistamientos;
}

List<LatLng> obtenerCoordenadasAvistamientos() {
  return obtenerAvistamientosOrdenados().map((avistamiento) {
    return LatLng(
      double.parse(avistamiento['latitud'].toString()),
      double.parse(avistamiento['longitud'].toString()),
    );
  }).toList();
}

  List<Marker> construirMarcadores() {
  if (widget.marcadoresAdicionales.isNotEmpty) {
    final avistamientos = obtenerAvistamientosOrdenados();

    return List.generate(avistamientos.length, (index) {
      final avistamiento = avistamientos[index];

      final latitud = double.parse(
        avistamiento['latitud'].toString(),
      );

      final longitud = double.parse(
        avistamiento['longitud'].toString(),
      );

      final esPrimero = index == 0;
      final esUltimo = index == avistamientos.length - 1;

      final color = esPrimero
          ? Colors.green
          : esUltimo
              ? Colors.red
              : Colors.blue;

      return Marker(
        point: LatLng(latitud, longitud),
        width: 55,
        height: 60,
        child: GestureDetector(
          onTap: () {
            final fecha = avistamiento['fecha']?.toString() ?? '';
            final descripcion =
                avistamiento['descripcion']?.toString().trim() ?? '';

            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text('Avistamiento ${index + 1}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha: $fecha'),
                    const SizedBox(height: 10),
                    Text(
                      descripcion.isEmpty
                          ? 'Sin descripción.'
                          : descripcion,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      esPrimero
                          ? 'Primer avistamiento'
                          : esUltimo
                              ? 'Último avistamiento'
                              : 'Avistamiento intermedio',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
          child: Icon(
            Icons.location_pin,
            size: 45,
            color: color,
          ),
        ),
      );
    });
  }

  return [
    Marker(
      point: widget.soloLectura
          ? LatLng(widget.latitudInicial, widget.longitudInicial)
          : ubicacionSeleccionada,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.location_pin,
        size: 50,
        color: AppTheme.verdePrincipal,
      ),
    ),
  ];
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.marcadoresAdicionales.isNotEmpty
                  ? 'Estos son los puntos donde se registraron '
                      'los avistamientos de esta publicación.'
                  : 'Verificá la ubicación de la mascota. '
                      'Podés mover el mapa para ajustar el punto.',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textoPrincipal,
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: controladorMapa,
              options: MapOptions(
                initialCenter: ubicacionSeleccionada,
                initialZoom: 14,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture &&
                      !widget.soloLectura &&
                      widget.marcadoresAdicionales.isEmpty) {
                    setState(() {
                      ubicacionSeleccionada = camera.center;
                    });
                  }
                },
              ),
             children: [
  TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.example.huella',
  ),

  if (widget.marcadoresAdicionales.length >= 2)
    PolylineLayer(
      polylines: [
        Polyline(
          points: obtenerCoordenadasAvistamientos(),
          strokeWidth: 4,
          color: Colors.blue,
        ),
      ],
    ),

  MarkerLayer(
    markers: construirMarcadores(),
  ),
],
            ),
          ),
          if (!widget.soloLectura)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ubicacionSeleccionada,
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar ubicación'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
