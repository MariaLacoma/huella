import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../publicaciones/detalle_publicacion_page.dart';

class PublicacionesAdministradorPage extends StatefulWidget {
  const PublicacionesAdministradorPage({super.key});

  @override
  State<PublicacionesAdministradorPage> createState() =>
      _PublicacionesAdministradorPageState();
}

class _PublicacionesAdministradorPageState
    extends State<PublicacionesAdministradorPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> publicaciones = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPublicaciones();
  }

  Future<void> cargarPublicaciones() async {
    try {
      final resultado = await supabase
          .from('publicacion')
          .select()
          .order('fecha_creacion', ascending: false);

      if (!mounted) return;

      setState(() {
        publicaciones = List<Map<String, dynamic>>.from(resultado);
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFFCEBEA),
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    content: const Text(
      'No se pudieron cargar las publicaciones.',
      style: TextStyle(
        color: AppTheme.error,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);

      debugPrint('Error al cargar publicaciones: $e');
    }
  }

  String obtenerEstadoVisible(String estado) {
  if (estado == 'activa') {
    return 'Activa';
  } else if (estado == 'encontrada') {
    return 'Encontrada';
  } else if (estado == 'eliminada') {
    return 'Retirada';
  }

  return estado;
}

  Future<void> cambiarEstadoPublicacion(
    int idPublicacion,
    String estadoActual,
  ) async {
    final nuevoEstado = estadoActual == 'activa' ? 'encontrada' : 'activa';

    try {
      await supabase
          .from('publicacion')
          .update({'estado': nuevoEstado})
          .eq('id_publicacion', idPublicacion);

      if (!mounted) return;

      await cargarPublicaciones();

     ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: AppTheme.verdeClaro,
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    content: Text(
     nuevoEstado == 'encontrada'
    ? 'La mascota fue encontrada.'
    : 'La publicación volvió a estar activa.',
      style: const TextStyle(
        color: AppTheme.verdeOscuro,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);
    } catch (e) {
      if (!mounted) return;

   ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFFCEBEA),
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    content: const Text(
      'No se pudo actualizar el estado de la publicación.',
      style: TextStyle(
        color: AppTheme.error,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);

      debugPrint('Error al cambiar estado: $e');
    }
  }

  Future<void> retirarPublicacion(int idPublicacion) async {
    try {
      await supabase
          .from('publicacion')
          .update({'estado': 'eliminada'})
          .eq('id_publicacion', idPublicacion);

      if (!mounted) return;

      await cargarPublicaciones();

      if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFFCEBEA),
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    content: const Text(
      'No se pudieron cargar las publicaciones.',
      style: TextStyle(
        color: AppTheme.error,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);
    } catch (e) {
      if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: const Color(0xFFFCEBEA),
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    content: Text(
      'No se pudo retirar la publicación: $e',
      style: const TextStyle(
        color: AppTheme.error,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);

      debugPrint('Error al retirar publicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar publicaciones')),
      body: RefreshIndicator(
        onRefresh: cargarPublicaciones,
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : publicaciones.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('No hay publicaciones registradas.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: publicaciones.length,
                itemBuilder: (context, index) {
                  final publicacion = publicaciones[index];

                  final nombre = (publicacion['nombre'] ?? 'Sin nombre')
                      .toString();

                  final especie = (publicacion['especie'] ?? '').toString();

                  final tipo = (publicacion['tipo'] ?? '').toString();

                  final estado = (publicacion['estado'] ?? '').toString();

                  final foto = (publicacion['foto'] ?? '').toString();

                  final rutaFoto = foto.startsWith('fotos-mascotas/')
                      ? foto.substring('fotos-mascotas/'.length)
                      : foto;

                  final urlFoto = rutaFoto.isEmpty
                      ? null
                      : supabase.storage
                            .from('fotos-mascotas')
                            .getPublicUrl(rutaFoto);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: urlFoto == null
                            ? const SizedBox(
                                width: 65,
                                height: 65,
                                child: Icon(Icons.pets),
                              )
                            : Image.network(
                                urlFoto,
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    width: 65,
                                    height: 65,
                                    child: Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textoPrincipal,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$especie · $tipo\nEstado: ${obtenerEstadoVisible(estado)}',
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (valor) async {
                          final idPublicacion = int.tryParse(
                            publicacion['id_publicacion'].toString(),
                          );

                          if (idPublicacion == null) return;

                          if (valor == 'estado') {
                            await cambiarEstadoPublicacion(
                              idPublicacion,
                              estado,
                            );
                          }

                          if (valor == 'retirar') {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Retirar publicación'),
                                content: const Text(
                                  '¿Estás seguro de que querés retirar esta publicación? '
                                  'Dejará de estar disponible, pero se conservará su registro.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext, false);
                                    },
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext, true);
                                    },
                                    child: const Text('Retirar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true) {
                              await retirarPublicacion(idPublicacion);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          if (estado != 'eliminada')
                            PopupMenuItem(
                              value: 'estado',
                              child: Row(
                                children: [
                                  const Icon(Icons.sync, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    estado == 'activa'
                                        ? 'Marcar como encontrada'
                                        : 'Marcar como activa',
                                  ),
                                ],
                              ),
                            ),
                          if (estado != 'eliminada')
                            const PopupMenuItem(
                              value: 'retirar',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Retirar publicación',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetallePublicacionPage(
                              publicacion: publicacion,
                            ),
                          ),
                        );

                        if (mounted) {
                          cargarPublicaciones();
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
