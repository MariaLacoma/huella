import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'ubicacion_publicacion_page.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class RegistrarAvistamientoPage extends StatefulWidget {
  final int idUsuario;
  final Map<String, dynamic> publicacion;

  const RegistrarAvistamientoPage({
    super.key,
    required this.idUsuario,
    required this.publicacion,
  });

  @override
  State<RegistrarAvistamientoPage> createState() =>
      _RegistrarAvistamientoPageState();
}

class _RegistrarAvistamientoPageState extends State<RegistrarAvistamientoPage> {
  final descripcionController = TextEditingController();

  DateTime fechaSeleccionada = DateTime.now();
  double? latitud;
  double? longitud;

  @override
  void dispose() {
    descripcionController.dispose();
    super.dispose();
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null && mounted) {
      setState(() {
        fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> seleccionarUbicacion() async {
    final ubicacion = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UbicacionPublicacionPage(
          latitudInicial: latitud ?? -46.4397,
          longitudInicial: longitud ?? -67.5197,
        ),
      ),
    );

    if (ubicacion != null && mounted) {
      setState(() {
        latitud = ubicacion.latitude;
        longitud = ubicacion.longitude;
      });
    }
  }

  Future<void> guardarAvistamiento() async {
    if (latitud == null || longitud == null) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          Icon(Icons.location_off, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seleccioná la ubicación del avistamiento.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
  return;
}

    try {
      final respuesta = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/registrar_avistamiento.php'),
        body: {
          'id_publicacion': widget.publicacion['id_publicacion'].toString(),
          'id_usuario': widget.idUsuario.toString(),
          'fecha':
              '${fechaSeleccionada.year}-'
              '${fechaSeleccionada.month.toString().padLeft(2, '0')}-'
              '${fechaSeleccionada.day.toString().padLeft(2, '0')}',
          'latitud': latitud.toString(),
          'longitud': longitud.toString(),
          'descripcion': descripcionController.text.trim(),
        },
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (!mounted) return;

      final bool guardadoCorrectamente =
    respuesta.statusCode == 200 && datos['ok'] == true;

ScaffoldMessenger.of(context).hideCurrentSnackBar();
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: guardadoCorrectamente
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
          guardadoCorrectamente ? Icons.check_circle : Icons.error_outline,
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            datos['mensaje']?.toString() ??
                'No se pudo guardar el avistamiento.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  ),
);

      if (respuesta.statusCode == 200 && datos['ok'] == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
        Icon(Icons.wifi_off, color: Colors.white),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(title: const Text('Registrar avistamiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mascota publicada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (widget.publicacion['nombre'] ?? '').toString().trim().isEmpty
                  ? widget.publicacion['especie'].toString()
                  : widget.publicacion['nombre'].toString(),
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Qué día viste a la mascota?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: seleccionarFecha,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                '${fechaSeleccionada.day.toString().padLeft(2, '0')}/'
                '${fechaSeleccionada.month.toString().padLeft(2, '0')}/'
                '${fechaSeleccionada.year}',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Dónde la viste?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: seleccionarUbicacion,
              icon: const Icon(Icons.location_on),
              label: Text(
                latitud == null
                    ? 'Seleccionar ubicación en el mapa'
                    : 'Ubicación seleccionada',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Descripción',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Contá cómo era o hacia dónde iba...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: guardarAvistamiento,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar avistamiento'),
            ),
          ],
        ),
      ),
    );
  }
}
