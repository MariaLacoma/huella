
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
    final nuevoEstado =
        estadoActual == 'activa' ? 'encontrada' : 'activa';

    try {
      await supabase
          .from('publicacion')
          .update({'estado': nuevoEstado})
          .eq('id_publicacion', idPublicacion);

      if (!mounted) return;

      await cargarPublicaciones();

      if (!mounted) return;

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
          backgroundColor: AppTheme.verdeClaro,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'La publicación fue retirada correctamente.',
            style: TextStyle(
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
      appBar: AppBar(
        title: const Text('Gestionar publicaciones'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarPublicaciones,
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : publicaciones.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 140),
                      Icon(
                        Icons.pets_outlined,
                        size: 64,
                        color: AppTheme.verdePrincipal
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'No hay publicaciones registradas',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textoPrincipal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Cuando se publiquen mascotas, aparecerán aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: publicaciones.length,
                    itemBuilder: (context, index) {
                      final publicacion = publicaciones[index];

                      final nombre =
                          (publicacion['nombre'] ?? 'Sin nombre')
                              .toString();

                      final especie =
                          (publicacion['especie'] ?? '').toString();

                      final tipo =
                          (publicacion['tipo'] ?? '').toString();

                      final estado =
                          (publicacion['estado'] ?? '').toString();

                      final foto =
                          (publicacion['foto'] ?? '').toString();

                      final rutaFoto =
                          foto.startsWith('fotos-mascotas/')
                              ? foto.substring(
                                  'fotos-mascotas/'.length,
                                )
                              : foto;

                      final urlFoto = rutaFoto.isEmpty
                          ? null
                          : supabase.storage
                              .from('fotos-mascotas')
                              .getPublicUrl(rutaFoto);

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppTheme.verdeClaro,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetallePublicacionPage(
                                  publicacion: publicacion,
                                ),
                              ),
                            );

                            if (mounted) {
                              cargarPublicaciones();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: urlFoto == null
                                      ? Container(
                                          width: 68,
                                          height: 68,
                                          color: AppTheme.verdeClaro,
                                          child: const Icon(
                                            Icons.pets,
                                            color:
                                                AppTheme.verdePrincipal,
                                            size: 30,
                                          ),
                                        )
                                      : Image.network(
                                          urlFoto,
                                          width: 68,
                                          height: 68,
                                          fit: BoxFit.contain,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 68,
                                              height: 68,
                                              color:
                                                  AppTheme.verdeClaro,
                                              child: const Icon(
                                                Icons
                                                    .image_not_supported,
                                                color: AppTheme
                                                    .verdePrincipal,
                                              ),
                                            );
                                          },
                                        ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              AppTheme.textoPrincipal,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '$especie · $tipo',
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color:
                                              AppTheme.textoSecundario,
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                   Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  ),
  decoration: BoxDecoration(
    color: estado == 'eliminada'
        ? const Color(0xFFFCEBEA)
        : AppTheme.verdeClaro,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    obtenerEstadoVisible(estado),
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.visible,
    style: TextStyle(
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w600,
      color: estado == 'eliminada'
          ? AppTheme.error
          : AppTheme.verdeOscuro,
    ),
  ),
),
                                    ],
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color:
                                        AppTheme.textoSecundario,
                                  ),
                                  onSelected: (valor) async {
                                    final idPublicacion =
                                        int.tryParse(
                                      publicacion['id_publicacion']
                                          .toString(),
                                    );

                                    if (idPublicacion == null) return;

                                    if (valor == 'estado') {
                                      await cambiarEstadoPublicacion(
                                        idPublicacion,
                                        estado,
                                      );
                                    }

                                    if (valor == 'retirar') {
                                      final confirmar =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) =>
                                            AlertDialog(
                                          title: const Text(
                                            'Retirar publicación',
                                          ),
                                          content: const Text(
                                            '¿Estás seguro de que querés retirar esta publicación? '
                                            'Dejará de estar disponible, pero se conservará su registro.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  false,
                                                );
                                              },
                                              child: const Text(
                                                'Cancelar',
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  true,
                                                );
                                              },
                                              child: const Text(
                                                'Retirar',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmar == true) {
                                        await retirarPublicacion(
                                          idPublicacion,
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (estado != 'eliminada') ...[
                                      PopupMenuItem(
                                        value: 'estado',
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.sync,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              estado == 'activa'
                                                  ? 'Marcar como encontrada'
                                                  : 'Marcar como activa',
                                            ),
                                          ],
                                        ),
                                      ),
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
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (estado == 'eliminada')
                                      const PopupMenuItem(
                                        enabled: false,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 20,
                                              color: AppTheme
                                                  .textoSecundario,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Publicación retirada',
                                              style: TextStyle(
                                                color: AppTheme
                                                    .textoSecundario,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
