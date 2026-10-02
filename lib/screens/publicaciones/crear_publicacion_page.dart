import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';
import 'ubicacion_publicacion_page.dart';

class CrearPublicacionPage extends StatefulWidget {
  final int idUsuario;

  const CrearPublicacionPage({super.key, required this.idUsuario});

  @override
  State<CrearPublicacionPage> createState() => _CrearPublicacionPageState();
}

class _CrearPublicacionPageState extends State<CrearPublicacionPage> {
  String tipoPublicacion = 'Perdida';

  final ImagePicker selectorImagen = ImagePicker();

  XFile? imagenSeleccionada;
  LatLng? ubicacionConfirmada;

  void mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.verdePrincipal,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void mostrarMensajeAdvertencia(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> seleccionarImagenGaleria() async {
    final XFile? imagen = await selectorImagen.pickImage(
      source: ImageSource.gallery,
    );

    if (imagen != null) {
      setState(() {
        imagenSeleccionada = imagen;
      });
    }
  }

  Future<void> tomarFotografia() async {
    final XFile? imagen = await selectorImagen.pickImage(
      source: ImageSource.camera,
    );

    if (imagen != null) {
      setState(() {
        imagenSeleccionada = imagen;
      });
    }
  }

  /* Future<Position?> obtenerUbicacionActual() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return null;
    }

    try {
      Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));

      return posicion;
    } catch (e) {
      return null;
    }
  }
*/
  Future<Position?> obtenerUbicacionActual() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();

    print('SERVICIO GPS: $servicioActivo');

    if (!servicioActivo) {
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    print('PERMISO INICIAL: $permiso');

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();

      print('PERMISO DESPUÉS DE SOLICITAR: $permiso');
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return null;
    }

    try {
      Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 2));

      print('UBICACIÓN OBTENIDA: ${posicion.latitude}, ${posicion.longitude}');

      return posicion;
    } catch (e) {
      print('ERROR OBTENIENDO UBICACIÓN: $e');
      return null;
    }
  }

  Future<void> guardarPublicacion() async {
    if (ubicacionConfirmada == null) {
      mostrarMensajeAdvertencia('Primero confirmá la ubicación.');
    }

    final url = Uri.parse('http://10.0.2.2/huella_api/crear_publicacion.php');

    final solicitud = http.MultipartRequest('POST', url);

    solicitud.fields['id_usuario'] = widget.idUsuario.toString();
    solicitud.fields['tipo'] = tipoPublicacion;
    solicitud.fields['nombre'] = nombreController.text.trim();
    solicitud.fields['especie'] = especieController.text.trim();
    solicitud.fields['sexo'] = sexoController.text.trim();
    solicitud.fields['descripcion'] = descripcionController.text.trim();
    solicitud.fields['fecha'] = fechaController.text.trim();
    solicitud.fields['latitud'] = ubicacionConfirmada!.latitude.toString();
    solicitud.fields['longitud'] = ubicacionConfirmada!.longitude.toString();

    solicitud.files.add(
      await http.MultipartFile.fromPath('foto', imagenSeleccionada!.path),
    );
final respuesta = await solicitud.send();
final cuerpo = await respuesta.stream.bytesToString();

print('RESPUESTA DEL SERVIDOR:');
print(cuerpo);

final datos = jsonDecode(cuerpo);

    if (!mounted) return;

    if (datos['ok'] == true) {
      mostrarMensajeExito('Publicación creada correctamente.');

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(datos['mensaje'])));
    }
  }

  final nombreController = TextEditingController();
  final especieController = TextEditingController();
  final sexoController = TextEditingController();
  final descripcionController = TextEditingController();
  final fechaController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    especieController.dispose();
    descripcionController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Usuario que crea la publicación: ${widget.idUsuario}');
    return Scaffold(
      appBar: AppBar(title: const Text('Crear publicación')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publicar mascota',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Completá los datos para ayudar a encontrarla.',
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 24),

              const Text(
                'Tipo de publicación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Radio<String>(
                    value: 'Perdida',
                    groupValue: tipoPublicacion,
                    onChanged: (valor) {
                      setState(() {
                        tipoPublicacion = valor!;
                      });
                    },
                  ),
                  const Text('Perdida'),

                  const SizedBox(width: 20),

                  Radio<String>(
                    value: 'Encontrada',
                    groupValue: tipoPublicacion,
                    onChanged: (valor) {
                      setState(() {
                        tipoPublicacion = valor!;
                      });
                    },
                  ),
                  const Text('Encontrada'),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre o identificación (si se conoce)',
                  prefixIcon: Icon(Icons.pets_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: especieController,
                decoration: const InputDecoration(
                  labelText: 'Especie',
                  hintText: 'Ej.: perro, gato',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: sexoController,
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  hintText: 'Ej.: macho, hembra, no identificado',
                  prefixIcon: Icon(Icons.pets_outlined),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: descripcionController,
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Indicá color, tamaño, raza u otras características de la mascota.',
                style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: fechaController,
                readOnly: true,
                onTap: () async {
                  DateTime? fechaSeleccionada = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (fechaSeleccionada != null) {
                    setState(() {
                      fechaController.text =
                          '${fechaSeleccionada.year}-'
                          '${fechaSeleccionada.month.toString().padLeft(2, '0')}-'
                          '${fechaSeleccionada.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Fotografía',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt_outlined),
                              title: const Text('Tomar fotografía'),
                              onTap: () {
                                Navigator.pop(context);
                                tomarFotografia();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library_outlined),
                              title: const Text('Elegir de la galería'),
                              onTap: () {
                                Navigator.pop(context);
                                seleccionarImagenGaleria();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.verdeClaro,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: imagenSeleccionada == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 45),
                            SizedBox(height: 10),
                            Text(
                              'Seleccionar fotografía',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Tocá aquí para elegir una imagen'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(imagenSeleccionada!.path),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              if (ubicacionConfirmada != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 32,
                          color: AppTheme.verdePrincipal,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ubicación confirmada',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoPrincipal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Lista para publicar.',
                                style: TextStyle(
                                  color: AppTheme.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (ubicacionConfirmada != null)
                TextButton.icon(
                  onPressed: () async {
                    LatLng? nuevaUbicacion = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UbicacionPublicacionPage(
                          latitudInicial: ubicacionConfirmada!.latitude,
                          longitudInicial: ubicacionConfirmada!.longitude,
                        ),
                      ),
                    );

                    if (!mounted || nuevaUbicacion == null) return;

                    setState(() {
                      ubicacionConfirmada = nuevaUbicacion;
                    });

                    mostrarMensajeExito('Ubicación modificada correctamente.');
                  },
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('Cambiar ubicación'),
                ),

              const SizedBox(height: 28),

              if (ubicacionConfirmada == null)
                ElevatedButton.icon(
                  onPressed: () async {
                    Position? posicion = await obtenerUbicacionActual();

                    if (!mounted) return;

                    double latitudInicial = -46.4397;
                    double longitudInicial = -67.5197;

                    if (posicion != null) {
                      latitudInicial = posicion.latitude;
                      longitudInicial = posicion.longitude;
                    }

                    LatLng? nuevaUbicacion = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UbicacionPublicacionPage(
                          latitudInicial: latitudInicial,
                          longitudInicial: longitudInicial,
                        ),
                      ),
                    );

                    if (!mounted || nuevaUbicacion == null) return;

                    setState(() {
                      ubicacionConfirmada = nuevaUbicacion;
                    });

                    mostrarMensajeExito('Ubicación confirmada correctamente.');
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Elegir ubicación'),
                ),

              const SizedBox(height: 12),

              if (ubicacionConfirmada != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    await guardarPublicacion();
                  },
                  icon: const Icon(Icons.publish),
                  label: const Text('Publicar mascota'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
