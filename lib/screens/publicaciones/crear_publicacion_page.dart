
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'ubicacion_publicacion_page.dart';

class CrearPublicacionPage extends StatefulWidget {
  final int idUsuario;

  const CrearPublicacionPage({
    super.key,
    required this.idUsuario,
  });

  @override
  State<CrearPublicacionPage> createState() =>
      _CrearPublicacionPageState();
}

class _CrearPublicacionPageState
    extends State<CrearPublicacionPage> {
  String tipoPublicacion = 'Perdida';

  final ImagePicker selectorImagen = ImagePicker();

  XFile? imagenSeleccionada;
  Uint8List? bytesImagen;
  LatLng? ubicacionConfirmada;
  bool _guardando = false;

  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final caracteristicasController = TextEditingController();
  final fechaController = TextEditingController();

  String? especieSeleccionada;
  String? sexoSeleccionado;
  String? tamanoSeleccionado;
  String? edadSeleccionada;
  String? colorSeleccionado;
  String? razaSeleccionada;
  final otroColorController = TextEditingController();
final razaConocidaController = TextEditingController();

  void mostrarMensajeExito(String mensaje) {
    if (!mounted) return;

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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
            ),
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

  Widget crearSelector({
    required String titulo,
    required String? valor,
    required List<String> opciones,
    required String etiqueta,
    required IconData icono,
    required ValueChanged<String?> alCambiar,
  }) {
    return DropdownButtonFormField<String>(
      value: valor,
      isExpanded: true,
     decoration: InputDecoration(
  labelText: titulo,
  prefixIcon: Icon(icono),
),
      hint: Text(etiqueta),
      items: opciones.map((opcion) {
        return DropdownMenuItem<String>(
          value: opcion,
          child: Text(opcion),
        );
      }).toList(),
      onChanged: alCambiar,
    );
  }

  Future<void> seleccionarImagenGaleria() async {
    try {
      final XFile? imagen = await selectorImagen.pickImage(
        source: ImageSource.gallery,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      if (!mounted) return;

      setState(() {
        imagenSeleccionada = imagen;
        bytesImagen = bytes;
      });
    } catch (e) {
      debugPrint('ERROR AL SELECCIONAR IMAGEN: $e');
      mostrarMensajeAdvertencia(
        'No se pudo seleccionar la fotografía.',
      );
    }
  }

  Future<void> tomarFotografia() async {
    try {
      final XFile? imagen = await selectorImagen.pickImage(
        source: ImageSource.camera,
      );

      if (imagen == null) return;

      final bytes = await imagen.readAsBytes();

      if (!mounted) return;

      setState(() {
        imagenSeleccionada = imagen;
        bytesImagen = bytes;
      });
    } catch (e) {
      debugPrint('ERROR AL TOMAR FOTOGRAFÍA: $e');
      mostrarMensajeAdvertencia(
        'No se pudo obtener la fotografía.',
      );
    }
  }

  Future<Position?> obtenerUbicacionActual() async {
    try {
      final servicioActivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicioActivo) return null;

      LocationPermission permiso =
          await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));

      return posicion;
    } catch (e) {
      debugPrint('ERROR OBTENIENDO UBICACIÓN: $e');
      return null;
    }
  }

  Future<void> guardarPublicacion() async {
    if (_guardando) return;

   if (especieSeleccionada == null ||
    sexoSeleccionado == null ||
    tamanoSeleccionado == null ||
    edadSeleccionada == null ||
    colorSeleccionado == null ||
    razaSeleccionada == null) {
  mostrarMensajeAdvertencia(
    'Completá todas las características de la mascota.',

  );
  return;
}
if (tipoPublicacion == 'Perdida' &&
    nombreController.text.trim().isEmpty) {
  mostrarMensajeAdvertencia(
    'Ingresá el nombre de la mascota perdida.',
  );
  return;
}

if (colorSeleccionado == 'Otro' &&
    otroColorController.text.trim().isEmpty) {
  mostrarMensajeAdvertencia(
    'Especificá el color de la mascota.',
  );
  return;
}

if (razaSeleccionada == 'Raza conocida' &&
    razaConocidaController.text.trim().isEmpty) {
  mostrarMensajeAdvertencia(
    'Especificá la raza de la mascota.',
  );
  return;
}

    if (descripcionController.text.trim().isEmpty) {
      mostrarMensajeAdvertencia(
        'Completá la descripción adicional.',
      );
      return;
    }

    if (fechaController.text.trim().isEmpty) {
      mostrarMensajeAdvertencia(
        'Seleccioná la fecha.',
      );
      return;
    }

    if (imagenSeleccionada == null || bytesImagen == null) {
      mostrarMensajeAdvertencia(
        'Seleccioná una fotografía.',
      );
      return;
    }

    if (ubicacionConfirmada == null) {
      mostrarMensajeAdvertencia(
        'Primero confirmá la ubicación.',
      );
      return;
    }

    final cliente = Supabase.instance.client;
    final usuarioAuth = cliente.auth.currentUser;

    if (usuarioAuth == null) {
      mostrarMensajeAdvertencia(
        'Tu sesión no está activa. Iniciá sesión nuevamente.',
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    String? rutaFoto;

    try {
      final perfil = await cliente
          .from('usuario')
          .select('id_usuario, estado')
          .eq('auth_user_id', usuarioAuth.id)
          .maybeSingle();

      if (perfil == null || perfil['estado'] != 'activo') {
        throw Exception(
          'No se encontró un perfil activo para esta cuenta.',
        );
      }

      final idUsuarioReal = perfil['id_usuario'] as int;

      final extensionOriginal =
          imagenSeleccionada!.name.contains('.')
              ? imagenSeleccionada!.name.split('.').last
              : 'jpg';

      final nombreArchivo =
          '${usuarioAuth.id}/'
          '${DateTime.now().millisecondsSinceEpoch}.$extensionOriginal';

      rutaFoto = await cliente.storage
          .from('fotos-mascotas')
          .uploadBinary(
            nombreArchivo,
            bytesImagen!,
          );

      await cliente.from('publicacion').insert({
        'id_usuario': idUsuarioReal,
        'tipo': tipoPublicacion,
        'nombre': nombreController.text.trim().isEmpty
            ? null
            : nombreController.text.trim(),
        'especie': especieSeleccionada,
        'sexo': sexoSeleccionado,
        'tamano': tamanoSeleccionado,
        'edad': edadSeleccionada,
        'color': colorSeleccionado == 'Otro'
    ? otroColorController.text.trim()
    : colorSeleccionado,
'raza': razaSeleccionada == 'Raza conocida'
    ? razaConocidaController.text.trim()
    : razaSeleccionada,
        'caracteristicas':
            caracteristicasController.text.trim().isEmpty
                ? null
                : caracteristicasController.text.trim(),
        'descripcion': descripcionController.text.trim(),
        'fecha': fechaController.text.trim(),
        'foto': rutaFoto,
        'latitud': ubicacionConfirmada!.latitude,
        'longitud': ubicacionConfirmada!.longitude,
        'estado': 'activa',
      });

      if (!mounted) return;

      mostrarMensajeExito(
        'Publicación creada correctamente.',
      );

      Navigator.pop(context, true);
    } on StorageException catch (e) {
      debugPrint('ERROR AL SUBIR FOTO: ${e.message}');

      if (!mounted) return;

      mostrarMensajeAdvertencia(
        'No se pudo subir la fotografía. Revisá los permisos de Storage.',
      );
    } on PostgrestException catch (e) {
      debugPrint('ERROR AL GUARDAR PUBLICACIÓN: ${e.message}');
      debugPrint('CÓDIGO: ${e.code}');

      if (rutaFoto != null) {
        try {
          await cliente.storage
              .from('fotos-mascotas')
              .remove([rutaFoto]);
        } catch (errorLimpieza) {
          debugPrint(
            'NO SE PUDO ELIMINAR LA FOTO: $errorLimpieza',
          );
        }
      }

      if (!mounted) return;

      mostrarMensajeAdvertencia(
        'No se pudo guardar la publicación. '
        'Revisá los permisos y los datos de Supabase.',
      );
    } catch (e) {
      debugPrint('ERROR AL CREAR PUBLICACIÓN: $e');

      if (!mounted) return;

      mostrarMensajeAdvertencia(
        'Ocurrió un error al crear la publicación. '
        'Revisá la terminal para conocer el detalle.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  void dispose() {
  nombreController.dispose();
  descripcionController.dispose();
  caracteristicasController.dispose();
  fechaController.dispose();
  otroColorController.dispose();
  razaConocidaController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear publicación'),
      ),
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
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textoSecundario,
                ),
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
                      if (valor == null) return;
                      setState(() {
                        tipoPublicacion = valor;
                      });
                    },
                  ),
                  const Text('Perdida'),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'Encontrada',
                    groupValue: tipoPublicacion,
                    onChanged: (valor) {
                      if (valor == null) return;
                      setState(() {
                        tipoPublicacion = valor;
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
                  labelText: 'Nombre o identificación (opcional)',
                  prefixIcon: Icon(Icons.pets_outlined),
                ),
              ),
              const SizedBox(height: 20),

              crearSelector(
                titulo: 'Especie',
                etiqueta: 'Seleccioná la especie',
                valor: especieSeleccionada,
                opciones: ['Perro', 'Gato', 'Otro'],
                icono: Icons.category_outlined,
              alCambiar: (valor) {
  setState(() {
    especieSeleccionada = valor;
    edadSeleccionada = null;
  });
},
              ),
              const SizedBox(height: 20),

              crearSelector(
                titulo: 'Sexo',
                etiqueta: 'Seleccioná el sexo',
                valor: sexoSeleccionado,
                opciones: ['Macho', 'Hembra', 'No identificado'],
                icono: Icons.pets_outlined,
                alCambiar: (valor) {
                  setState(() {
                    sexoSeleccionado = valor;
                  });
                },
              ),
              const SizedBox(height: 20),

              crearSelector(
                titulo: 'Tamaño',
                etiqueta: 'Seleccioná el tamaño',
                valor: tamanoSeleccionado,
                opciones: ['Pequeño', 'Mediano', 'Grande', 'Desconocido'],
                icono: Icons.straighten,
                alCambiar: (valor) {
                  setState(() {
                    tamanoSeleccionado = valor;
                  });
                },
              ),
              const SizedBox(height: 20),

            crearSelector(
  titulo: 'Edad aproximada',
  etiqueta: 'Seleccioná la edad',
  valor: edadSeleccionada,
  opciones: especieSeleccionada == 'Gato'
      ? [
          'Gatito',
          'Joven',
          'Adulto',
          'Adulto mayor',
          'Desconocida',
        ]
      : [
          'Cachorro',
          'Joven',
          'Adulto',
          'Adulto mayor',
          'Desconocida',
        ],
  icono: Icons.cake_outlined,
  alCambiar: (valor) {
    setState(() {
      edadSeleccionada = valor;
    });
  },
),
              const SizedBox(height: 20),

              crearSelector(
                titulo: 'Color predominante',
                etiqueta: 'Seleccioná el color',
                valor: colorSeleccionado,
                opciones: [
                  'Blanco',
                  'Negro',
                  'Marrón',
                  'Gris',
                  'Amarillo',
                  'Combinado',
                  'Otro',
                ],
                icono: Icons.palette_outlined,
                alCambiar: (valor) {
                  setState(() {
                    colorSeleccionado = valor;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (colorSeleccionado == 'Otro') ...[
  TextField(
    controller: otroColorController,
    decoration: const InputDecoration(
      labelText: '¿Qué otro color?',
      hintText: 'Ej.: beige, naranja...',
      prefixIcon: Icon(Icons.palette_outlined),
    ),
  ),
  const SizedBox(height: 20),
],

              crearSelector(
                titulo: 'Raza',
                etiqueta: 'Seleccioná la raza',
                valor: razaSeleccionada,
                opciones: [
                  'Mestizo',
                  'Raza conocida',
                  'Desconocida',
                ],
                icono: Icons.pets_outlined,
                alCambiar: (valor) {
                  setState(() {
                    razaSeleccionada = valor;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (razaSeleccionada == 'Raza conocida') ...[
  TextField(
    controller: razaConocidaController,
    decoration: const InputDecoration(
      labelText: '¿Qué raza?',
      hintText: 'Ej.: Labrador, Caniche...',
      prefixIcon: Icon(Icons.pets_outlined),
    ),
  ),
  const SizedBox(height: 20),
],

              TextField(
                controller: caracteristicasController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Características particulares (opcional)',
                  hintText: 'Ej.: mancha blanca en el pecho, collar rojo...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: descripcionController,
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Descripción adicional',
                  hintText: 'Agregá otros detalles importantes...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: fechaController,
                readOnly: true,
                onTap: () async {
                  final fechaSeleccionada = await showDatePicker(
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
                    builder: (contextHoja) {
                      return SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.camera_alt_outlined,
                              ),
                              title: const Text('Tomar fotografía'),
                              onTap: () {
                                Navigator.pop(contextHoja);
                                tomarFotografia();
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.photo_library_outlined,
                              ),
                              title: const Text('Elegir de la galería'),
                              onTap: () {
                                Navigator.pop(contextHoja);
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
                  child: bytesImagen == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 45,
                            ),
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
                          child: Image.memory(
                            bytesImagen!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              if (ubicacionConfirmada != null) ...[
                const SizedBox(height: 16),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubicación confirmada',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textoPrincipal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
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
                TextButton.icon(
                  onPressed: () async {
                    final nuevaUbicacion =
                        await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UbicacionPublicacionPage(
                          latitudInicial:
                              ubicacionConfirmada!.latitude,
                          longitudInicial:
                              ubicacionConfirmada!.longitude,
                        ),
                      ),
                    );

                    if (!mounted || nuevaUbicacion == null) return;

                    setState(() {
                      ubicacionConfirmada = nuevaUbicacion;
                    });

                    mostrarMensajeExito(
                      'Ubicación modificada correctamente.',
                    );
                  },
                  icon: const Icon(Icons.edit_location_alt),
                  label: const Text('Cambiar ubicación'),
                ),
              ],

              const SizedBox(height: 28),

              if (ubicacionConfirmada == null)
                ElevatedButton.icon(
                  onPressed: () async {
                    final posicion = await obtenerUbicacionActual();

                    if (!mounted) return;

                    double latitudInicial = -46.4397;
                    double longitudInicial = -67.5197;

                    if (posicion != null) {
                      latitudInicial = posicion.latitude;
                      longitudInicial = posicion.longitude;
                    }

                    final nuevaUbicacion =
                        await Navigator.push<LatLng>(
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

                    mostrarMensajeExito(
                      'Ubicación confirmada correctamente.',
                    );
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Elegir ubicación'),
                ),

              const SizedBox(height: 12),

              if (ubicacionConfirmada != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _guardando
                        ? null
                        : guardarPublicacion,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.publish),
                    label: Text(
                      _guardando
                          ? 'Publicando...'
                          : 'Publicar mascota',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
