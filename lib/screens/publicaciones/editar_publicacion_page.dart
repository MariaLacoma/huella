
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
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
  State<EditarPublicacionPage> createState() =>
      _EditarPublicacionPageState();
}

class _EditarPublicacionPageState
    extends State<EditarPublicacionPage> {
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

  @override
  void initState() {
    super.initState();

    final publicacion = widget.publicacion;

    nombreController =
        TextEditingController(text: publicacion['nombre']?.toString() ?? '');
    especieController =
        TextEditingController(text: publicacion['especie']?.toString() ?? '');
    sexoController =
        TextEditingController(text: publicacion['sexo']?.toString() ?? '');
    descripcionController =
        TextEditingController(text: publicacion['descripcion']?.toString() ?? '');
    fechaController =
        TextEditingController(text: publicacion['fecha']?.toString() ?? '');

    tipoPublicacion = publicacion['tipo'].toString();

    ubicacionConfirmada = LatLng(
      double.parse(publicacion['latitud'].toString()),
      double.parse(publicacion['longitud'].toString()),
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
    final imagen = await selectorImagen.pickImage(
      source: ImageSource.gallery,
    );

    if (imagen != null && mounted) {
      setState(() {
        imagenSeleccionada = imagen;
      });
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

  Future<void> guardarCambios() async {
    if (descripcionController.text.trim().isEmpty ||
        especieController.text.trim().isEmpty ||
        fechaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completá los campos obligatorios.'),
        ),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final solicitud = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}/actualizar_publicacion.php',
        ),
      );

      solicitud.fields.addAll({
        'id_publicacion':
            widget.publicacion['id_publicacion'].toString(),
        'id_usuario': widget.idUsuario.toString(),
        'tipo': tipoPublicacion,
        'nombre': nombreController.text.trim(),
        'especie': especieController.text.trim(),
        'sexo': sexoController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'fecha': fechaController.text.trim(),
        'latitud': ubicacionConfirmada.latitude.toString(),
        'longitud': ubicacionConfirmada.longitude.toString(),
      });

      if (imagenSeleccionada != null) {
        solicitud.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            imagenSeleccionada!.path,
          ),
        );
      }

      final respuesta = await solicitud.send();
      final cuerpo = await respuesta.stream.bytesToString();
      final datos = jsonDecode(cuerpo);

      if (!mounted) return;

      if (datos['ok'] == true) {
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

      } else {
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
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              datos['mensaje']?.toString() ??
                  'No se pudieron guardar los cambios.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
    } catch (error) {
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
            'Ocurrió un error al actualizar la publicación.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  ),
);
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
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Editar publicación'),
      ),
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
              initialValue: tipoPublicacion,
              items: const [
                DropdownMenuItem(
                  value: 'Perdida',
                  child: Text('Perdida'),
                ),
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
              decoration: const InputDecoration(
                labelText: 'Sexo (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
              ),
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
                    DateTime.tryParse(fechaController.text) ??
                    DateTime.now();

                final fecha = await showDatePicker(
                  context: context,
                  initialDate: fechaActual,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (fecha != null) {
                  fechaController.text =
                      '${fecha.year.toString().padLeft(4, '0')}-'
                      '${fecha.month.toString().padLeft(2, '0')}-'
                      '${fecha.day.toString().padLeft(2, '0')}';
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
              Image.file(
                File(imagenSeleccionada!.path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              const Text(
                'Se conservará la fotografía actual si no elegís otra.',
                style: TextStyle(
                  color: AppTheme.textoSecundario,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: seleccionarImagen,
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
            OutlinedButton.icon(
              onPressed: seleccionarUbicacion,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Modificar ubicación'),
            ),
            const SizedBox(height: 8),
          
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardarCambios,
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
                  guardando ? 'Guardando...' : 'Guardar cambios',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
