import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import 'editar_publicacion_page.dart';
import 'registrar_avistamiento_page.dart';
import 'consultar_avistamientos_page.dart';

Future<Map<String, dynamic>> marcarMascotaEncontrada({
  required int idPublicacion,
  required int idUsuario,
}) async {
  final supabase = Supabase.instance.client;
  final usuarioAutenticado = supabase.auth.currentUser;

  if (usuarioAutenticado == null) {
    return {
      'ok': false,
      'mensaje': 'Iniciá sesión para cerrar la publicación.',
    };
  }

  try {
    final resultado = await supabase
        .from('publicacion')
        .update({'estado': 'encontrada'})
        .eq('id_publicacion', idPublicacion)
        .eq('id_usuario', idUsuario)
        .eq('estado', 'activa')
        .select('id_publicacion')
        .maybeSingle();

    if (resultado == null) {
      return {
        'ok': false,
        'mensaje': 'No se pudo actualizar. Verificá que la publicación sea tuya, esté activa y tengas permiso para modificarla.',
      };
    }

    return {
      'ok': true,
      'mensaje': 'La publicación se actualizó correctamente.',
    };
  } on PostgrestException catch (error) {
    debugPrint('Error Supabase al cerrar publicación: ${error.message}');
    debugPrint('Código: ${error.code}');

    return {
      'ok': false,
      'mensaje': 'Supabase rechazó la actualización (${error.code}).',
    };
  } catch (error) {
    debugPrint('Error al cerrar publicación: $error');

    return {
      'ok': false,
      'mensaje': 'Ocurrió un error al actualizar la publicación.',
    };
  }
}

Future<Map<String, dynamic>?> mostrarFormularioReporte(
  BuildContext context,
) async {
  String motivoSeleccionado = 'Información falsa o engañosa';
  final descripcionController = TextEditingController();

  final resultado = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, actualizarDialogo) {
          return AlertDialog(
            title: const Text('Reportar publicación'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Por qué querés reportar esta publicación?'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: motivoSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Motivo del reporte',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Información falsa o engañosa',
                        child: Text('Información falsa o engañosa'),
                      ),
                      DropdownMenuItem(
                        value: 'Publicación duplicada',
                        child: Text('Publicación duplicada'),
                      ),
                      DropdownMenuItem(
                        value: 'Contenido inapropiado',
                        child: Text('Contenido inapropiado'),
                      ),
                      DropdownMenuItem(
                        value: 'Datos de contacto incorrectos',
                        child: Text('Datos de contacto incorrectos'),
                      ),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        actualizarDialogo(() {
                          motivoSeleccionado = valor;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descripcionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Contanos qué problema encontraste...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, {
                    'motivo': motivoSeleccionado,
                    'descripcion': descripcionController.text.trim(),
                  });
                },
                child: const Text('Enviar reporte'),
              ),
            ],
          );
        },
      );
    },
  );

  descripcionController.dispose();
  return resultado;
}

Future<void> abrirEnlaceContacto(BuildContext context, Uri uri) async {
  try {
    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFCEBEA),
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'No se pudo abrir la aplicación.',
            style: TextStyle(
              color: AppTheme.error,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  } catch (error) {
    debugPrint('Error al abrir enlace de contacto: $error');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFCEBEA),
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'Ocurrió un error al intentar contactar.',
            style: TextStyle(
              color: AppTheme.error,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }
}

class DetallePublicacionPage extends StatefulWidget {
  final Map<String, dynamic> publicacion;
  final int? idUsuario;
  final String? tipoUsuario;

  const DetallePublicacionPage({
    super.key,
    required this.publicacion,
    this.idUsuario,
    this.tipoUsuario,
  });

  @override
  State<DetallePublicacionPage> createState() => _DetallePublicacionPageState();
}

class _DetallePublicacionPageState extends State<DetallePublicacionPage> {
  Map<String, dynamic> get publicacion => widget.publicacion;
  Map<String, dynamic>? resultadoAnalisisIA;
  bool analizandoMascota = false;

  int? get idUsuario => widget.idUsuario;

  String? get tipoUsuario => widget.tipoUsuario;

  Future<Map<String, dynamic>?> obtenerDatosContacto() async {
    final idAutor = publicacion['id_usuario'];

    if (idAutor == null) return null;

    final resultado = await Supabase.instance.client.rpc(
      'obtener_datos_contacto',
      params: {'id_autor': idAutor},
    );

    if (resultado == null || (resultado as List).isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(resultado.first);
  }

  Future<Map<String, dynamic>?> obtenerAnalisisGuardado({
    required int idPublicacion,
    required String rutaFoto,
  }) async {
    try {
      final resultado = await Supabase.instance.client
          .from('analisis_mascota')
          .select('ruta_foto, resultado')
          .eq('id_publicacion', idPublicacion)
          .maybeSingle();

      if (resultado == null) {
        return null;
      }

      // Comprobar que el análisis corresponda a la foto actual.
      if (resultado['ruta_foto'] != rutaFoto) {
        return null;
      }

      final datos = resultado['resultado'];

      if (datos is Map) {
        return Map<String, dynamic>.from(datos);
      }

      return null;
    } catch (error) {
      debugPrint('Error al recuperar el análisis: $error');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> analizarMascota({
    required int idPublicacion,
    required String rutaFoto,
  }) async {
    final respuesta = await Supabase.instance.client.functions.invoke(
      'analizar-mascota',
      body: {'idPublicacion': idPublicacion, 'rutaFoto': rutaFoto},
    );

    if (respuesta.status != 200) {
  debugPrint('ERROR IA - Estado: ${respuesta.status}');
  debugPrint('ERROR IA - Respuesta: ${respuesta.data}');

  throw Exception(
    'Error ${respuesta.status}: ${respuesta.data}',
  );
}

    final datos = respuesta.data;

    if (datos is Map &&
        datos['analisis'] is Map &&
        datos['coincidencias'] is List) {
      return Map<String, dynamic>.from(datos);
    }

    throw Exception('La respuesta de la IA no tiene el formato esperado.');
  }

  Future<void> enviarReporte(BuildContext context) async {
    if (idUsuario == null) return;

    final datos = await mostrarFormularioReporte(context);

    if (datos == null || !context.mounted) return;

    try {
      await Supabase.instance.client.from('reporte').insert({
        'id_usuario': idUsuario,
        'id_publicacion': publicacion['id_publicacion'],
        'motivo': datos['motivo'],
        'descripcion': (datos['descripcion'] as String).isEmpty
            ? null
            : datos['descripcion'],
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.verdeClaro,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'El reporte se envió correctamente.',
            style: TextStyle(
              color: AppTheme.verdeOscuro,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFCEBEA),
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            'No se pudo enviar el reporte: $e',
            style: const TextStyle(
              color: AppTheme.error,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  final nombre = (publicacion['nombre'] ?? '').toString().trim().isEmpty
      ? (publicacion['tipo'] == 'Encontrada'
          ? 'Mascota encontrada'
          : 'Nombre no informado')
      : publicacion['nombre'].toString();

    final tipo = (publicacion['tipo'] ?? '').toString();
    final especie = (publicacion['especie'] ?? '').toString();
    final sexo = (publicacion['sexo'] ?? '').toString();
    final descripcion = (publicacion['descripcion'] ?? '').toString();

    final tamano = (publicacion['tamano'] ?? '').toString().trim();
    final edad = (publicacion['edad'] ?? '').toString().trim();
    final color = (publicacion['color'] ?? '').toString().trim();
    final raza = (publicacion['raza'] ?? '').toString().trim();
    final caracteristicas = (publicacion['caracteristicas'] ?? '')
        .toString()
        .trim();

    final hayCaracteristicas = [
      tamano,
      edad,
      color,
      raza,
      caracteristicas,
    ].any((valor) => valor.isNotEmpty && valor.toLowerCase() != 'null');

    final fecha = (publicacion['fecha'] ?? '').toString();
    final estado = (publicacion['estado'] ?? '').toString().toLowerCase();

    final esPropietario =
        idUsuario != null &&
        publicacion['id_usuario'].toString() == idUsuario.toString();

    final String estadoVisible;
    final Color colorEstado;

    if (estado == 'eliminada') {
      estadoVisible = 'Retirada por el administrador';
      colorEstado = AppTheme.error;
    } else if (estado == 'encontrada') {
      estadoVisible = tipo.toLowerCase() == 'perdida'
          ? '¡La mascota fue encontrada!'
          : '¡La mascota volvió con su familia!';
      colorEstado = const Color(0xFF238653);
    } else if (estado == 'activa') {
      estadoVisible = tipo.toLowerCase() == 'perdida'
          ? 'Se sigue buscando'
          : 'Se busca a su familia';
      colorEstado = AppTheme.verdePrincipal;
    } else {
      estadoVisible = estado;
      colorEstado = AppTheme.textoSecundario;
    }

    final latitud =
        double.tryParse(publicacion['latitud']?.toString() ?? '') ?? 0.0;
    final longitud =
        double.tryParse(publicacion['longitud']?.toString() ?? '') ?? 0.0;

    final fotoGuardada = publicacion['foto']?.toString() ?? '';
    final rutaFoto = fotoGuardada.startsWith('fotos-mascotas/')
        ? fotoGuardada.substring('fotos-mascotas/'.length)
        : fotoGuardada;

    final String? urlFoto = rutaFoto.isEmpty
        ? null
        : Supabase.instance.client.storage
              .from('fotos-mascotas')
              .getPublicUrl(rutaFoto);

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(title: const Text('Detalle de publicación'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO PRINCIPAL
            Stack(
              children: [
                if (urlFoto != null)
                  Image.network(
                    urlFoto,
                    width: double.infinity,
                    height: 290,
                   fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _fotoSinImagen();
                    },
                  )
                else
                  _fotoSinImagen(),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: tipo.toLowerCase() == 'perdida'
                          ? const Color(0xFFB93838)
                          : AppTheme.verdeOscuro,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tipo.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // INFORMACIÓN PRINCIPAL
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.pets,
                        size: 19,
                        color: AppTheme.verdePrincipal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sexo.isEmpty || sexo == 'null'
                              ? especie
                              : '$especie · $sexo',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ESTADO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          estado == 'encontrada'
                              ? Icons.check_circle_outline
                              : estado == 'eliminada'
                              ? Icons.remove_circle_outline
                              : Icons.search,
                          color: colorEstado,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            estadoVisible,
                            style: TextStyle(
                              color: colorEstado,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // INFORMACIÓN DE LA MASCOTA
                  _TarjetaDesplegable(
                    titulo: 'Información de la mascota',
                    icono: Icons.pets,
                    inicialmenteAbierta: true,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sobre la mascota',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          descripcion.isEmpty
                              ? 'Sin descripción.'
                              : descripcion,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),
                      if (hayCaracteristicas) ...[
                        const Divider(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Características',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textoPrincipal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (tamano.isNotEmpty && tamano.toLowerCase() != 'null')
                          _CaracteristicaItem(titulo: 'Tamaño', valor: tamano),
                        if (edad.isNotEmpty && edad.toLowerCase() != 'null')
                          _CaracteristicaItem(
                            titulo: 'Edad aproximada',
                            valor: edad,
                          ),
                        if (color.isNotEmpty && color.toLowerCase() != 'null')
                          _CaracteristicaItem(titulo: 'Color', valor: color),
                        if (raza.isNotEmpty && raza.toLowerCase() != 'null')
                          _CaracteristicaItem(titulo: 'Raza', valor: raza),
                        if (caracteristicas.isNotEmpty &&
                            caracteristicas.toLowerCase() != 'null') ...[
                          const Divider(height: 22),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Otras características',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textoPrincipal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              caracteristicas,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),

                  // FECHA
                  const SizedBox(height: 12),
                  _TarjetaContenido(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.verdePrincipal,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Fecha de publicación',
                          style: TextStyle(
                            color: AppTheme.textoSecundario,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            fecha,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppTheme.textoPrincipal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // UBICACIÓN
                  const _TituloSeccion(
                    titulo: 'Ubicación',
                    icono: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 230,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(latitud, longitud),
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.huella',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(latitud, longitud),
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_pin,
                                  size: 50,
                                  color: AppTheme.verdePrincipal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CONTACTO
                  if (idUsuario != null &&
                      idUsuario != publicacion['id_usuario']) ...[
                    const SizedBox(height: 4),
                    FutureBuilder<Map<String, dynamic>?>(
                      future:
                          idUsuario != null &&
                              idUsuario != publicacion['id_usuario']
                          ? obtenerDatosContacto()
                          : Future.value(null),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          debugPrint(
                            'Error al cargar contacto: ${snapshot.error}',
                          );

                          return const _TarjetaContenido(
                            child: Text(
                              'No se pudieron cargar los datos de contacto.',
                              style: TextStyle(color: AppTheme.error),
                            ),
                          );
                        }

                        final contacto = snapshot.data;

                        if (contacto == null) {
                          return const _TarjetaContenido(
                            child: Text(
                              'No hay datos de contacto disponibles.',
                              style: TextStyle(color: AppTheme.textoSecundario),
                            ),
                          );
                        }

                        final nombreAutor = (contacto['nombre'] ?? '')
                            .toString();
                        final telefono = (contacto['telefono'] ?? '')
                            .toString();
                        final email = (contacto['email'] ?? '').toString();

                        final telefonoLimpio = telefono.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );

                        return _TarjetaDesplegable(
                          titulo: 'Datos de contacto',
                          icono: Icons.contact_phone_outlined,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (nombreAutor.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        color: AppTheme.verdePrincipal,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          nombreAutor,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (telefono.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        color: AppTheme.verdePrincipal,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(telefono)),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: telefonoLimpio.isEmpty
                                          ? null
                                          : () => abrirEnlaceContacto(
                                              context,
                                              Uri.parse(
                                                'https://wa.me/$telefonoLimpio',
                                              ),
                                            ),
                                      icon: const Icon(Icons.chat_outlined),
                                      label: const Text(
                                        'Contactar por WhatsApp',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (email.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        color: AppTheme.verdePrincipal,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(email)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => abrirEnlaceContacto(
                                        context,
                                        Uri(scheme: 'mailto', path: email),
                                      ),
                                      icon: const Icon(Icons.mail_outline),
                                      label: const Text('Enviar correo'),
                                    ),
                                  ),
                                ],
                                if (nombreAutor.isEmpty &&
                                    telefono.isEmpty &&
                                    email.isEmpty)
                                  const Text(
                                    'No hay datos de contacto disponibles.',
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  // ANÁLISIS INTELIGENTE
                  if (idUsuario != null && tipoUsuario == 'usuario') ...[
                    FutureBuilder<Map<String, dynamic>?>(
                      future: obtenerAnalisisGuardado(
                        idPublicacion: int.parse(
                          publicacion['id_publicacion'].toString(),
                        ),
                        rutaFoto: rutaFoto,
                      ),
                      builder: (context, snapshot) {
                        final datosAnalisis = snapshot.data;

                        final analisisRespuesta =
                            resultadoAnalisisIA?['analisis'];

                        final analisis = analisisRespuesta is Map
                            ? Map<String, dynamic>.from(analisisRespuesta)
                            : datosAnalisis ?? <String, dynamic>{};

                        final coincidenciasRespuesta =
                            resultadoAnalisisIA?['coincidencias'];

                        final coincidencias = coincidenciasRespuesta is List
                            ? coincidenciasRespuesta
                            : <dynamic>[];

                        final hayAnalisis =
                            resultadoAnalisisIA != null ||
                            datosAnalisis != null;

                        return _TarjetaDesplegable(
                          titulo: 'Análisis inteligente',
                          icono: Icons.auto_awesome,
                          children: [
                            const Text(
                              'La IA analiza las características de la mascota '
                              'para identificar posibles similitudes con otras publicaciones.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppTheme.textoPrincipal,
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (snapshot.hasError)
                              const Text(
                                'No se pudo recuperar el análisis guardado.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.error,
                                ),
                              )
                            else ...[
                              if (hayAnalisis) ...[
                              
                                

                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Posibles coincidencias',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textoPrincipal,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                if (resultadoAnalisisIA == null)
                                  const Text(
                                    'Presioná Buscar coincidencias para comparar esta mascota con otras publicaciones.',
                                    style: TextStyle(fontSize: 13),
                                  )
                                else if (coincidencias.isEmpty)
                                  const Text(
                                    'No se encontraron publicaciones similares.',
                                    style: TextStyle(fontSize: 13),
                                  )
                                else
                                  ...coincidencias.map((coincidencia) {
                                    final mascota = Map<String, dynamic>.from(
                                      coincidencia,
                                    );

                                    return Card(
  margin: const EdgeInsets.only(bottom: 10),
  child: ListTile(
    onTap: () async {
      final idCoincidencia = mascota['id_publicacion'];

      try {
        final publicacionEncontrada = await Supabase.instance.client
            .from('publicacion')
            .select()
            .eq('id_publicacion', idCoincidencia)
            .single();

        if (!context.mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetallePublicacionPage(
              publicacion: Map<String, dynamic>.from(
                publicacionEncontrada,
              ),
              idUsuario: idUsuario,
              tipoUsuario: tipoUsuario,
            ),
          ),
        );
      } catch (error) {
        debugPrint('Error al abrir coincidencia: $error');

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la publicación.'),
          ),
        );
      }
    },
                                        leading: const Icon(
                                          Icons.pets,
                                          color: AppTheme.verdePrincipal,
                                          size: 32,
                                        ),
                                       title: Text(
  mascota['nombre']?.toString().isNotEmpty == true
      ? mascota['nombre'].toString()
      : mascota['tipo'] == 'Encontrada'
          ? 'Mascota encontrada'
          : 'Nombre no informado',
),
                                   subtitle: Text(
  '${mascota['tipo']}'
  ' · ${mascota['especie'] ?? 'Especie no identificada'}'
  ' · Similitud: ${mascota['similitud'] ?? 0}%',
),
trailing: const Icon(
  Icons.chevron_right,
  color: AppTheme.verdePrincipal,
),
                                      ),
                                    );
                                  }),
                              ],
                         Column(
  children: [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: analizandoMascota
            ? null
            : () async {
                setState(() {
                  analizandoMascota = true;
                });

                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analizando fotografía...'),
                    ),
                  );

                  final resultado = await analizarMascota(
                    idPublicacion: int.parse(
                      publicacion['id_publicacion'].toString(),
                    ),
                    rutaFoto: rutaFoto,
                  );

                  if (!context.mounted) return;

                  setState(() {
                    resultadoAnalisisIA = resultado;
                    analizandoMascota = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Análisis realizado correctamente!',
                      ),
                      backgroundColor: AppTheme.verdePrincipal,
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;

                  setState(() {
                    analizandoMascota = false;
                  });

                  debugPrint(
                    'Error al analizar mascota: $error',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo analizar la fotografía.',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
        icon: const Icon(Icons.search),
        label: const Text('Buscar coincidencias'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.verdePrincipal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    ),

    if (analizandoMascota) ...[
      const SizedBox(height: 16),
      const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.verdePrincipal,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Analizando fotografía...',
        style: TextStyle(
          color: AppTheme.verdeOscuro,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Buscando posibles coincidencias. Esto puede tardar unos momentos.',
        textAlign: TextAlign.center,
      ),
    ],
  ],
),
                            ],
                          ],
                        );
                      },
                    ),
                  ],

                  // AVISTAMIENTOS
                  if (estado == 'activa') ...[
                    _TarjetaDesplegable(
                      titulo: 'Avistamientos',
                      icono: Icons.visibility_outlined,
                      children: [
                        Column(
                          children: [
                            if (idUsuario != null &&
                                tipoUsuario != 'administrador') ...[
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                leading: const Icon(
                                  Icons.add_location_alt_outlined,
                                  color: AppTheme.verdePrincipal,
                                ),
                                title: const Text(
                                  'Registrar avistamiento',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'Informar dónde viste a la mascota',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final resultado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RegistrarAvistamientoPage(
                                            idUsuario: idUsuario!,
                                            publicacion: publicacion,
                                          ),
                                    ),
                                  );

                                  if (!context.mounted) return;

                                  if (resultado == true) {
                                    // Se puede actualizar la lista al regresar.
                                  }
                                },
                              ),
                              const Divider(height: 1),
                            ],

                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              leading: const Icon(
                                Icons.map_outlined,
                                color: AppTheme.verdePrincipal,
                              ),
                              title: const Text(
                                'Ver avistamientos',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Consultar los lugares registrados',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ConsultarAvistamientosPage(
                                          publicacion: publicacion,
                                        ),
                                  ),
                                );
                              },
                            ),

                            if (idUsuario == null) ...[
                              const Divider(height: 1),
                              const Padding(
                                padding: EdgeInsets.only(top: 12, bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppTheme.verdePrincipal,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '¿Querés registrar un avistamiento? '
                                        'Iniciá sesión o registrate para informar '
                                        'dónde viste a la mascota.',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],

                  // ACCIONES DEL PROPIETARIO
                  if (esPropietario && estado == 'activa') ...[
                    const SizedBox(height: 30),
                    const _TituloSeccion(
                      titulo: 'Administrar publicación',
                      icono: Icons.settings_outlined,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditarPublicacionPage(
                                publicacion: publicacion,
                                idUsuario: idUsuario!,
                              ),
                            ),
                          );

                          if (!context.mounted) return;

                          if (resultado == true) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar publicación'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (tipo.toLowerCase() == 'perdida' ||
                        tipo.toLowerCase() == 'encontrada')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final tipoPublicacion = tipo.toLowerCase();

                            final mensajeConfirmacion =
                                tipoPublicacion == 'perdida'
                                ? '¿Confirmás que encontraste a tu mascota?'
                                : '¿Confirmás que la mascota volvió con su familia?';

                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Cerrar publicación'),
                                content: Text(mensajeConfirmacion),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('Confirmar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar != true || !context.mounted) {
                              return;
                            }

                            final idPublicacion = int.tryParse(
                              publicacion['id_publicacion'].toString(),
                            );

                            if (idPublicacion == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'El identificador de la publicación no es válido.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final resultado = await marcarMascotaEncontrada(
                              idPublicacion: idPublicacion,
                              idUsuario: idUsuario!,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: resultado['ok'] == true
                                    ? const Color(0xFF238653)
                                    : const Color(0xFFB93838),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 4),
                                content: Row(
                                  children: [
                                    Icon(
                                      resultado['ok'] == true
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        resultado['mensaje'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (resultado['ok'] == true) {
                              Navigator.pop(context, true);
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            tipo.toLowerCase() == 'perdida'
                                ? '¡La encontré!'
                                : '¡Volvió con su familia!',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF238653),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // REPORTAR
                  if (idUsuario != null &&
                      tipoUsuario != 'administrador' &&
                      estado != 'eliminada') ...[
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => enviarReporte(context),
                        icon: const Icon(
                          Icons.flag_outlined,
                          color: AppTheme.error,
                          size: 19,
                        ),
                        label: const Text(
                          'Reportar publicación',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mostrarDatoAnalisis(String titulo, dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final String texto;

    if (valor is List) {
      texto = valor.join(', ');
    } else {
      texto = valor.toString();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.verdeClaro,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.verdeOscuro,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textoPrincipal,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoSinImagen() {
    return Container(
      width: double.infinity,
      height: 290,
      color: AppTheme.verdeClaro,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          color: AppTheme.verdePrincipal,
        ),
      ),
    );
  }
}

// TÍTULO DE CADA SECCIÓN
class _TituloSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;

  const _TituloSeccion({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: AppTheme.verdePrincipal, size: 21),
        const SizedBox(width: 9),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textoPrincipal,
          ),
        ),
      ],
    );
  }
}

// TARJETA UNIFICADA
class _TarjetaContenido extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _TarjetaContenido({
    required this.child,
    this.padding = const EdgeInsets.all(17),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

// CARACTERÍSTICAS
class _CaracteristicaItem extends StatelessWidget {
  final String titulo;
  final String valor;

  const _CaracteristicaItem({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textoSecundario,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TARJETA DESPLEGABLE
class _TarjetaDesplegable extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;
  final bool inicialmenteAbierta;

  const _TarjetaDesplegable({
    required this.titulo,
    required this.icono,
    required this.children,
    this.inicialmenteAbierta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: inicialmenteAbierta,
          leading: Icon(icono, color: AppTheme.verdePrincipal),
          title: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoPrincipal,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }
}
