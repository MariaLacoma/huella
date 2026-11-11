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
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
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

// Abre WhatsApp, el teléfono o el correo.
Future<void> abrirEnlaceContacto(BuildContext context, Uri uri) async {
  try {
    final abierto = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

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

class DetallePublicacionPage extends StatelessWidget {
  final Map<String, dynamic> publicacion;
  final int? idUsuario;
  final String? tipoUsuario;

  const DetallePublicacionPage({
    super.key,
    required this.publicacion,
    this.idUsuario,
    this.tipoUsuario,
  });

  // Obtiene los datos de contacto de quien creó la publicación.
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

 Future<void> enviarReporte(BuildContext context) async {
  if (idUsuario == null) return;

  final datos = await mostrarFormularioReporte(context);

  if (datos == null) return;

  try {
    await Supabase.instance.client.from('reporte').insert({
      'id_usuario': idUsuario,
      'id_publicacion': publicacion['id_publicacion'],
      'motivo': datos['motivo'],
      'descripcion': (datos['descripcion'] as String).isEmpty
          ? null
          : datos['descripcion'],
    });

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
    final nombre = (publicacion['nombre'] ?? '').toString().isEmpty
        ? 'Sin nombre'
        : publicacion['nombre'].toString();

    final tipo = (publicacion['tipo'] ?? '').toString();
    final especie = (publicacion['especie'] ?? '').toString();
    final sexo = (publicacion['sexo'] ?? '').toString();
    final descripcion = (publicacion['descripcion'] ?? '').toString();
    final fecha = (publicacion['fecha'] ?? '').toString();
    final estado = (publicacion['estado'] ?? '').toString().toLowerCase();

    final String estadoVisible;

    if (estado == 'eliminada') {
      estadoVisible = 'Retirada por el administrador';
    } else if (estado == 'encontrada') {
      estadoVisible = tipo.toLowerCase() == 'perdida'
          ? '¡La mascota fue encontrada!'
          : '¡La mascota volvió con su familia!';
    } else if (estado == 'activa') {
      estadoVisible = tipo.toLowerCase() == 'perdida'
          ? 'Se sigue buscando'
          : 'Se busca a su familia';
    } else {
      estadoVisible = estado;
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
      appBar: AppBar(title: const Text('Detalle de publicación')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (urlFoto != null)
              Image.network(
                urlFoto,
                width: double.infinity,
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 280,
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 60),
                    ),
                  );
                },
              )
            else
              const SizedBox(
                height: 280,
                child: Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 60),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
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
                        size: 20,
                        color: AppTheme.verdePrincipal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sexo == 'null' || sexo.isEmpty
                              ? especie
                              : '$especie · $sexo',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.verdeClaro),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: AppTheme.verdePrincipal,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Descripción',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textoPrincipal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          descripcion,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icono: Icons.calendar_today_outlined,
                          titulo: 'Fecha',
                          valor: fecha,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icono: Icons.circle,
                          titulo: 'Estado',
                          valor: estadoVisible,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 250,
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
                  const SizedBox(height: 24),

                  // Datos de contacto de quien publicó el aviso.
                  FutureBuilder<Map<String, dynamic>?>(
                    future: idUsuario == null ? null : obtenerDatosContacto(),
                    builder: (context, snapshot) {
                      if (idUsuario == null) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
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

                        return const Text(
                          'No se pudieron cargar los datos de contacto.',
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      final contacto = snapshot.data;

                      if (contacto == null) {
                        return const SizedBox.shrink();
                      }

                      final nombreAutor = (contacto['nombre'] ?? '').toString();
                      final telefono = (contacto['telefono'] ?? '').toString();
                      final email = (contacto['email'] ?? '').toString();

                      final telefonoLimpio = telefono.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );

                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.verdeClaro),
                        ),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.contact_phone_outlined,
                            color: AppTheme.verdePrincipal,
                          ),
                          title: const Text(
                            'Datos de contacto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textoPrincipal,
                            ),
                          ),
                          subtitle: const Text('Tocá para ver cómo contactar'),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            18,
                            0,
                            18,
                            18,
                          ),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textoPrincipal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (telefono.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    color: AppTheme.verdePrincipal,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      telefono,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
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
                                  label: const Text('Contactar por WhatsApp'),
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
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
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
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Editar publicación propia.
                  if (idUsuario != null &&
                      publicacion['id_usuario'].toString() ==
                          idUsuario.toString() &&
                      estado == 'activa')
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

                  // Cerrar una publicación propia.
                  if (idUsuario != null &&
                      publicacion['id_usuario'].toString() ==
                          idUsuario.toString() &&
                      estado == 'activa' &&
                      (tipo.toLowerCase() == 'perdida' ||
                          tipo.toLowerCase() == 'encontrada'))
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Reportar publicación (solo usuarios registrados).
                  if (idUsuario != null &&
                      tipoUsuario != 'administrador' &&
                      estado != 'eliminada')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => enviarReporte(context),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Reportar publicación'),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Avistamientos de publicaciones activas.
                  if (estado == 'activa') ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Avistamientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.verdeClaro),
                        ),
                        child: Column(
                          children: [
                            if (idUsuario != null) ...[
                              ListTile(
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppTheme.verdePrincipal,
                                ),
                                title: const Text('Registrar avistamiento'),
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
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                            ],
                            ListTile(
                              leading: const Icon(
                                Icons.visibility_outlined,
                                color: AppTheme.verdePrincipal,
                              ),
                              title: const Text('Ver avistamientos'),
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
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              const Padding(
                                padding: EdgeInsets.all(16),
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
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _InfoCard({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: AppTheme.verdePrincipal),
          const SizedBox(height: 10),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}
