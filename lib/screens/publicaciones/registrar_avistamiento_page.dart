
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'ubicacion_publicacion_page.dart';

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

class _RegistrarAvistamientoPageState
    extends State<RegistrarAvistamientoPage> {
  final descripcionController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  DateTime fechaSeleccionada = DateTime.now();
  double? latitud;
  double? longitud;
  bool guardando = false;

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
    final ubicacion = await Navigator.push<LatLng>(
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

  void mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: esError
            ? const Color(0xFFB93838)
            : const Color(0xFF238653),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> guardarAvistamiento() async {
    if (latitud == null || longitud == null) {
      mostrarMensaje(
        'Seleccioná la ubicación del avistamiento.',
        esError: true,
      );
      return;
    }

    final idPublicacion =
        int.tryParse(widget.publicacion['id_publicacion'].toString());

    if (idPublicacion == null) {
      mostrarMensaje(
        'No se pudo identificar la publicación.',
        esError: true,
      );
      return;
    }

    final usuarioAutenticado = supabase.auth.currentUser;

    if (usuarioAutenticado == null) {
      mostrarMensaje(
        'Iniciá sesión para registrar un avistamiento.',
        esError: true,
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final fecha = '${fechaSeleccionada.year.toString().padLeft(4, '0')}-'
          '${fechaSeleccionada.month.toString().padLeft(2, '0')}-'
          '${fechaSeleccionada.day.toString().padLeft(2, '0')}';

      await supabase.from('avistamiento').insert({
        'id_publicacion': idPublicacion,
        'id_usuario': widget.idUsuario,
        'fecha': fecha,
        'latitud': latitud,
        'longitud': longitud,
        'descripcion': descripcionController.text.trim(),
      });

      if (!mounted) return;

      mostrarMensaje('Avistamiento registrado correctamente.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        'No se pudo guardar el avistamiento. Verificá los permisos de Supabase.',
        esError: true,
      );

      debugPrint('Error al registrar avistamiento: $error');
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (widget.publicacion['nombre'] ?? '').toString().trim();
    final especie =
        (widget.publicacion['especie'] ?? 'Mascota').toString();

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Registrar avistamiento'),
      ),
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
              nombre.isEmpty ? especie : nombre,
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
              onPressed: guardando ? null : seleccionarFecha,
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
              onPressed: guardando ? null : seleccionarUbicacion,
              icon: const Icon(Icons.location_on),
              label: Text(
                latitud == null
                    ? 'Seleccionar ubicación en el mapa'
                    : 'Ubicación seleccionada',
              ),
            ),
            if (latitud != null && longitud != null) ...[
              const SizedBox(height: 8),
              Text(
                'Latitud: ${latitud!.toStringAsFixed(5)}\n'
                'Longitud: ${longitud!.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
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
              enabled: !guardando,
              decoration: const InputDecoration(
                hintText: 'Contá cómo era o hacia dónde iba...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: guardando ? null : guardarAvistamiento,
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                guardando ? 'Guardando...' : 'Guardar avistamiento',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
