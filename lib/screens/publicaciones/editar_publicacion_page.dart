import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'ubicacion_publicacion_page.dart';

class EditarPublicacionPage extends StatefulWidget {
  final Map<String, dynamic> publicacion;
  final int idUsuario;

  const EditarPublicacionPage({
    super.key,
    required this.publicacion,
    required this.idUsuario,
  });

  @override
  State<EditarPublicacionPage> createState() => _EditarPublicacionPageState();
}

class _EditarPublicacionPageState extends State<EditarPublicacionPage> {
  final ImagePicker selectorImagen = ImagePicker();

  late final TextEditingController nombreController;
  late final TextEditingController especieController;
  late final TextEditingController sexoController;
  late final TextEditingController descripcionController;
  late final TextEditingController fechaController;

  late String tipoPublicacion;
  late LatLng ubicacionConfirmada;

  XFile? imagenSeleccionada;
  bool guardando = false;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    final publicacion = widget.publicacion;

    nombreController = TextEditingController(
      text: publicacion['nombre']?.toString() ?? '',
    );

    especieController = TextEditingController(
      text: publicacion['especie']?.toString() ?? '',
    );

    sexoController = TextEditingController(
      text: publicacion['sexo']?.toString() ?? '',
    );

    descripcionController = TextEditingController(
      text: publicacion['descripcion']?.toString() ?? '',
    );

    fechaController = TextEditingController(
      text: publicacion['fecha']?.toString() ?? '',
    );

    tipoPublicacion = publicacion['tipo']?.toString() ?? 'Perdida';

    ubicacionConfirmada = LatLng(
      double.tryParse(publicacion['latitud']?.toString() ?? '') ?? 0.0,
      double.tryParse(publicacion['longitud']?.toString() ?? '') ?? 0.0,
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    especieController.dispose();
    sexoController.dispose();
    descripcionController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  Future<void> seleccionarImagen() async {
    try {
      final imagen = await selectorImagen.pickImage(
        source: ImageSource.gallery,
      );

      if (imagen != null && mounted) {
        setState(() {
          imagenSeleccionada = imagen;
        });
      }
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje('No se pudo seleccionar la fotografía.', esError: true);
    }
  }

  Future<void> seleccionarUbicacion() async {
    final ubicacion = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => UbicacionPublicacionPage(
          latitudInicial: ubicacionConfirmada.latitude,
          longitudInicial: ubicacionConfirmada.longitude,
        ),
      ),
    );

    if (ubicacion != null && mounted) {
      setState(() {
        ubicacionConfirmada = ubicacion;
      });
    }
  }

  String obtenerRutaFotoActual() {
    final foto = widget.publicacion['foto']?.toString() ?? '';

    if (foto.startsWith('fotos-mascotas/')) {
      return foto.substring('fotos-mascotas/'.length);
    }

    return foto;
  }

  Future<String?> subirNuevaFoto() async {
    if (imagenSeleccionada == null) {
      return obtenerRutaFotoActual().isEmpty ? null : obtenerRutaFotoActual();
    }

    final bytes = await imagenSeleccionada!.readAsBytes();
    final extension = imagenSeleccionada!.name.contains('.')
        ? imagenSeleccionada!.name.split('.').last.toLowerCase()
        : 'jpg';

    final nombreArchivo =
        'mascota_${widget.idUsuario}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final ruta = '${widget.idUsuario}/$nombreArchivo';

    await supabase.storage
        .from('fotos-mascotas')
        .uploadBinary(
          ruta,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: false,
          ),
        );

    return ruta;
  }

  Future<void> guardarCambios() async {
    if (especieController.text.trim().isEmpty ||
        descripcionController.text.trim().isEmpty ||
        fechaController.text.trim().isEmpty) {
      mostrarMensaje('Completá los campos obligatorios.', esError: true);
      return;
    }

    final idPublicacion = int.tryParse(
      widget.publicacion['id_publicacion'].toString(),
    );

    if (idPublicacion == null) {
      mostrarMensaje('No se pudo identificar la publicación.', esError: true);
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final foto = await subirNuevaFoto();

      final cambios = <String, dynamic>{
        'tipo': tipoPublicacion,
        'nombre': nombreController.text.trim(),
        'especie': especieController.text.trim(),
        'sexo': sexoController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'fecha': fechaController.text.trim(),
        'latitud': ubicacionConfirmada.latitude,
        'longitud': ubicacionConfirmada.longitude,
        if (foto != null) 'foto': foto,
      };

      final resultado = await supabase
          .from('publicacion')
          .update(cambios)
          .eq('id_publicacion', idPublicacion)
          .eq('id_usuario', widget.idUsuario)
          .select('id_publicacion')
          .maybeSingle();

      if (!mounted) return;

      if (resultado == null) {
        mostrarMensaje(
          'No se pudo actualizar la publicación. Verificá que sea tuya y que tengas permiso para modificarla.',
          esError: true,
        );
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF238653),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Publicación actualizada correctamente.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      mostrarMensaje(
        'Ocurrió un error al actualizar la publicación. Verificá tu conexión y los permisos de Supabase.',
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rutaFotoActual = obtenerRutaFotoActual();

    final String? urlFotoActual = rutaFotoActual.isEmpty
        ? null
        : supabase.storage.from('fotos-mascotas').getPublicUrl(rutaFotoActual);

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(title: const Text('Editar publicación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de publicación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: tipoPublicacion == 'Encontrada'
                  ? 'Encontrada'
                  : 'Perdida',
              items: const [
                DropdownMenuItem(value: 'Perdida', child: Text('Perdida')),
                DropdownMenuItem(
                  value: 'Encontrada',
                  child: Text('Encontrada'),
                ),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() {
                    tipoPublicacion = valor;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la mascota (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: especieController,
              decoration: const InputDecoration(
                labelText: 'Especie *',
                hintText: 'Perro, Gato u Otro',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sexoController,
              decoration: const InputDecoration(labelText: 'Sexo (opcional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fechaController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha *',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final fechaActual =
                    DateTime.tryParse(fechaController.text) ?? DateTime.now();

                final fecha = await showDatePicker(
                  context: context,
                  initialDate: fechaActual,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (fecha != null && mounted) {
                  setState(() {
                    fechaController.text =
                        '${fecha.year.toString().padLeft(4, '0')}-'
                        '${fecha.month.toString().padLeft(2, '0')}-'
                        '${fecha.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Fotografía',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            if (imagenSeleccionada != null)
              FutureBuilder<Uint8List>(
                future: imagenSeleccionada!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    );
                  }

                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              )
            else if (urlFotoActual != null)
              Image.network(
                urlFotoActual,
                height: 180,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  );
                },
              )
            else
              const SizedBox(
                height: 100,
                child: Center(
                  child: Icon(
                    Icons.pets,
                    size: 48,
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: guardando ? null : seleccionarImagen,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Cambiar fotografía'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Latitud: ${ubicacionConfirmada.latitude.toStringAsFixed(5)}\n'
              'Longitud: ${ubicacionConfirmada.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: AppTheme.textoSecundario),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: guardando ? null : seleccionarUbicacion,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Modificar ubicación'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardarCambios,
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(guardando ? 'Guardando...' : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
