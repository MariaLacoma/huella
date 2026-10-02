import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';

class UbicacionPublicacionPage extends StatefulWidget {
  final double latitudInicial;
  final double longitudInicial;

  const UbicacionPublicacionPage({
    super.key,
    required this.latitudInicial,
    required this.longitudInicial,
  });

  @override
  State<UbicacionPublicacionPage> createState() =>
      _UbicacionPublicacionPageState();
}

class _UbicacionPublicacionPageState extends State<UbicacionPublicacionPage> {
  late LatLng ubicacionSeleccionada;

  @override
  void initState() {
    super.initState();

    ubicacionSeleccionada = LatLng(
      widget.latitudInicial,
      widget.longitudInicial,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Verificá la ubicación de la mascota. '
              'Podés mover el mapa para ajustar el punto.',
              style: TextStyle(fontSize: 16, color: AppTheme.textoPrincipal),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: ubicacionSeleccionada,
                    initialZoom: 16,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        ubicacionSeleccionada = camera.center;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.huella',
                    ),
                  ],
                ),

                const Center(
                  child: Icon(
                    Icons.location_pin,
                    size: 50,
                    color: AppTheme.verdePrincipal,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, ubicacionSeleccionada);
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirmar ubicación'),
            ),
          ),
        ],
      ),
    );
  }
}
