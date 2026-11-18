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
late final TextEditingController descripcionController;
late final TextEditingController caracteristicasController;
late final TextEditingController fechaController;
late final TextEditingController otroColorController;
late final TextEditingController razaConocidaController;

String? especieSeleccionada;
String? sexoSeleccionado;
String? tamanoSeleccionado;
String? edadSeleccionada;
String? colorSeleccionado;
String? razaSeleccionada;

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

  descripcionController = TextEditingController(
    text: publicacion['descripcion']?.toString() ?? '',
  );

  caracteristicasController = TextEditingController(
    text: publicacion['caracteristicas']?.toString() ?? '',
  );

  fechaController = TextEditingController(
    text: publicacion['fecha']?.toString() ?? '',
  );

  otroColorController = TextEditingController();
  razaConocidaController = TextEditingController();

  tipoPublicacion = publicacion['tipo']?.toString() ?? 'Perdida';

  especieSeleccionada = publicacion['especie']?.toString();
  sexoSeleccionado = publicacion['sexo']?.toString();
  tamanoSeleccionado = publicacion['tamano']?.toString();

  final edadGuardada = publicacion['edad']?.toString();

  final opcionesEdad = especieSeleccionada == 'Gato'
      ? ['Gatito', 'Joven', 'Adulto', 'Adulto mayor', 'Desconocida']
      : ['Cachorro', 'Joven', 'Adulto', 'Adulto mayor', 'Desconocida'];

  edadSeleccionada =
      opcionesEdad.contains(edadGuardada) ? edadGuardada : null;

  // Recuperar el color guardado.
  final colorGuardado = publicacion['color']?.toString();

  const colores = [
    'Blanco',
    'Negro',
    'Marrón',
    'Gris',
    'Amarillo',
    'Combinado',
  ];

  if (colores.contains(colorGuardado)) {
    colorSeleccionado = colorGuardado;
  } else if (colorGuardado != null && colorGuardado.isNotEmpty) {
    colorSeleccionado = 'Otro';
    otroColorController.text = colorGuardado;
  }

  // Recuperar la raza guardada.
  final razaGuardada = publicacion['raza']?.toString();

  if (razaGuardada == 'Mestizo' || razaGuardada == 'Desconocida') {
    razaSeleccionada = razaGuardada;
  } else if (razaGuardada == 'Raza conocida') {
    razaSeleccionada = 'Raza conocida';
  } else if (razaGuardada != null && razaGuardada.isNotEmpty) {
    razaSeleccionada = 'Raza conocida';
    razaConocidaController.text = razaGuardada;
  }

  ubicacionConfirmada = LatLng(
    double.tryParse(publicacion['latitud']?.toString() ?? '') ?? 0.0,
    double.tryParse(publicacion['longitud']?.toString() ?? '') ?? 0.0,
  );
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
   if (especieSeleccionada == null ||
    sexoSeleccionado == null ||
    tamanoSeleccionado == null ||
    edadSeleccionada == null ||
    colorSeleccionado == null ||
    razaSeleccionada == null ||
    (colorSeleccionado == 'Otro' &&
        otroColorController.text.trim().isEmpty) ||
    (razaSeleccionada == 'Raza conocida' &&
        razaConocidaController.text.trim().isEmpty) ||
    (tipoPublicacion == 'Perdida' &&
        nombreController.text.trim().isEmpty) ||
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
  'caracteristicas': caracteristicasController.text.trim().isEmpty
      ? null
      : caracteristicasController.text.trim(),
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

Widget crearSelector({
  required String titulo,
  required String? valor,
  required List<String> opciones,
  required String etiqueta,
  required IconData icono,
  required ValueChanged<String?> alCambiar,
}) {
  return DropdownButtonFormField<String>(
    initialValue: valor,
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
  decoration: InputDecoration(
    labelText: tipoPublicacion == 'Perdida'
        ? 'Nombre de la mascota *'
        : 'Nombre de la mascota (opcional)',
  ),
),
SizedBox(height: 16),
          
          // ESPECIE
crearSelector(
  titulo: 'Especie *',
  valor: especieSeleccionada,
  opciones: ['Perro', 'Gato', 'Otro'],
  etiqueta: 'Seleccioná la especie',
  icono: Icons.pets,
  alCambiar: (valor) {
    setState(() {
      especieSeleccionada = valor;

      edadSeleccionada = null;
    });
  },
),
const SizedBox(height: 16),

// SEXO
crearSelector(
  titulo: 'Sexo *',
  valor: sexoSeleccionado,
  opciones: ['Macho', 'Hembra', 'No identificado'],
  etiqueta: 'Seleccioná el sexo',
  icono: Icons.wc,
  alCambiar: (valor) {
    setState(() {
      sexoSeleccionado = valor;
    });
  },
),
const SizedBox(height: 16),

// TAMAÑO
crearSelector(
  titulo: 'Tamaño *',
  valor: tamanoSeleccionado,
  opciones: ['Pequeño', 'Mediano', 'Grande', 'Desconocido'],
  etiqueta: 'Seleccioná el tamaño',
  icono: Icons.straighten,
  alCambiar: (valor) {
    setState(() {
      tamanoSeleccionado = valor;
    });
  },
),
const SizedBox(height: 16),

// EDAD
crearSelector(
  titulo: 'Edad aproximada *',
  valor: edadSeleccionada,
  opciones: especieSeleccionada == 'Gato'
      ? ['Gatito', 'Joven', 'Adulto', 'Adulto mayor', 'Desconocida']
      : ['Cachorro', 'Joven', 'Adulto', 'Adulto mayor', 'Desconocida'],
  etiqueta: 'Seleccioná la edad',
  icono: Icons.cake_outlined,
  alCambiar: (valor) {
    setState(() {
      edadSeleccionada = valor;
    });
  },
),

            const SizedBox(height: 16),
            // COLOR
crearSelector(
  titulo: 'Color *',
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
  etiqueta: 'Seleccioná el color',
  icono: Icons.palette_outlined,
  alCambiar: (valor) {
    setState(() {
      colorSeleccionado = valor;
      if (valor != 'Otro') {
        otroColorController.clear();
      }
    });
  },
),
if (colorSeleccionado == 'Otro') ...[
  const SizedBox(height: 12),
  TextField(
    controller: otroColorController,
    decoration: const InputDecoration(
      labelText: '¿Qué otro color? *',
      hintText: 'Ej.: beige, naranja...',
      prefixIcon: Icon(Icons.color_lens_outlined),
    ),
  ),
],
const SizedBox(height: 16),



// RAZA
crearSelector(
  titulo: 'Raza *',
  valor: razaSeleccionada,
  opciones: ['Mestizo', 'Raza conocida', 'Desconocida'],
  etiqueta: 'Seleccioná la raza',
  icono: Icons.pets_outlined,
  alCambiar: (valor) {
    setState(() {
      razaSeleccionada = valor;
      if (valor != 'Raza conocida') {
        razaConocidaController.clear();
      }
    });
  },
),
if (razaSeleccionada == 'Raza conocida') ...[
  const SizedBox(height: 12),
  TextField(
    controller: razaConocidaController,
    decoration: const InputDecoration(
      labelText: '¿Qué raza? *',
      hintText: 'Ej.: Labrador, Caniche...',
      prefixIcon: Icon(Icons.edit_outlined),
    ),
  ),
],
const SizedBox(height: 16),
TextField(
  controller: caracteristicasController,
  maxLines: 3,
  decoration: const InputDecoration(
    labelText: 'Características adicionales (opcional)',
    hintText: 'Ej.: tiene collar rojo, una mancha en la pata...',
    prefixIcon: Icon(Icons.notes),
    alignLabelWithHint: true,
  ),
),
const SizedBox(height: 16),

          
            const SizedBox(height: 16),
           TextField(
  controller: descripcionController,
  maxLines: 4,
  decoration: const InputDecoration(
    labelText: 'Descripción *',
    hintText: 'Contá cómo es la mascota y cualquier dato importante...',
    alignLabelWithHint: true,
  ),
),
const SizedBox(height: 16),
            
            TextField(
              controller: fechaController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha en que se perdió o encontró *',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
              final hoy = DateTime.now();
final fechaGuardada = DateTime.tryParse(fechaController.text);

final fechaInicial = fechaGuardada == null
    ? hoy
    : fechaGuardada.isAfter(hoy)
        ? hoy
        : fechaGuardada.isBefore(DateTime(2020))
            ? DateTime(2020)
            : fechaGuardada;

final fecha = await showDatePicker(
  context: context,
  initialDate: fechaInicial,
  firstDate: DateTime(2020),
  lastDate: hoy,
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
          ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Container(
    height: 180,
    width: double.infinity,
    color: AppTheme.verdeClaro,
    child: imagenSeleccionada != null
        ? FutureBuilder<Uint8List>(
            future: imagenSeleccionada!.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                );
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          )
        : urlFotoActual != null
            ? Image.network(
                urlFotoActual,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: AppTheme.textoSecundario,
                    ),
                  );
                },
              )
            : const Center(
                child: Icon(
                  Icons.pets,
                  size: 48,
                  color: AppTheme.textoSecundario,
                ),
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
    fontWeight: FontWeight.bold,
    color: AppTheme.textoPrincipal,
  ),
),
const SizedBox(height: 10),

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
                'Guardada para esta publicación.',
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
  onPressed: guardando ? null : seleccionarUbicacion,
  icon: const Icon(Icons.edit_location_alt),
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
