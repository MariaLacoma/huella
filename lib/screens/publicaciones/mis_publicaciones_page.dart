import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import 'detalle_publicacion_page.dart';

class MisPublicacionesPage extends StatefulWidget {
  final int idUsuario;
  final VoidCallback onVolverInicio;

  const MisPublicacionesPage({
    super.key,
    required this.idUsuario,
    required this.onVolverInicio,
  });

  @override
  State<MisPublicacionesPage> createState() =>
      _MisPublicacionesPageState();
}
class _MisPublicacionesPageState extends State<MisPublicacionesPage> {
  List<Map<String, dynamic>> publicaciones = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarPublicaciones();
  }

  Future<void> cargarPublicaciones() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final cliente = Supabase.instance.client;
      final usuarioAuth = cliente.auth.currentUser;

      if (usuarioAuth == null) {
        throw Exception('Debés iniciar sesión para ver tus publicaciones.');
      }

      // Obtener el ID interno del usuario autenticado.
      final perfil = await cliente
          .from('usuario')
          .select('id_usuario, estado')
          .eq('auth_user_id', usuarioAuth.id)
          .maybeSingle();

      if (perfil == null) {
        throw Exception('No se encontró tu perfil de usuario.');
      }

      if (perfil['estado'] != 'activo') {
        throw Exception('Tu cuenta no está habilitada.');
      }

      final idUsuarioReal = perfil['id_usuario'] as int;

      // Consultar las publicaciones de este usuario.
      final resultado = await cliente
          .from('publicacion')
          .select()
          .eq('id_usuario', idUsuarioReal)
          .order('fecha_creacion', ascending: false);

      if (!mounted) return;

      setState(() {
        publicaciones = resultado
            .map((fila) => Map<String, dynamic>.from(fila))
            .toList();
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'No se pudieron cargar las publicaciones.\n$e';
        cargando = false;
      });
    }
  }

  String obtenerUrlFoto(dynamic foto) {
    if (foto == null || foto.toString().trim().isEmpty) {
      return '';
    }

    String ruta = foto.toString().trim();

    if (ruta.startsWith('https://') || ruta.startsWith('http://')) {
      return ruta;
    }

    // Quitar el nombre del bucket si ya está incluido.
    const prefijo = 'fotos-mascotas/';
    if (ruta.startsWith(prefijo)) {
      ruta = ruta.substring(prefijo.length);
    }

    return Supabase.instance.client.storage
        .from('fotos-mascotas')
        .getPublicUrl(ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis publicaciones'),
        backgroundColor: AppTheme.verdePrincipal,
        foregroundColor: Colors.white,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 42,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: cargarPublicaciones,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : publicaciones.isEmpty
          ? RefreshIndicator(
              onRefresh: cargarPublicaciones,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Todavía no tenés publicaciones.')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: cargarPublicaciones,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: publicaciones.length,
                itemBuilder: (context, index) {
                  final publicacion = publicaciones[index];

                  final nombre = publicacion['nombre']?.toString() ?? '';
                  final especie = publicacion['especie']?.toString() ?? '';
                  final tipo =
                      publicacion['tipo']?.toString().toLowerCase() ?? '';
                  final estado =
                      publicacion['estado']?.toString().toLowerCase() ?? '';

                  final String tipoVisible;

                  if (tipo == 'perdida') {
                    tipoVisible = 'Mascota perdida';
                  } else if (tipo == 'encontrada') {
                    tipoVisible = 'Mascota encontrada';
                  } else {
                    tipoVisible = publicacion['tipo']?.toString() ?? '';
                  }

                  final String estadoVisible;

                  if (estado == 'eliminada') {
                    estadoVisible = 'Retirada por el administrador';
                  } else if (estado == 'encontrada' && tipo == 'perdida') {
                    estadoVisible = '¡La mascota fue encontrada!';
                  } else if (estado == 'encontrada' && tipo == 'encontrada') {
                    estadoVisible = '¡La mascota volvió con su familia!';
                  } else if (estado == 'activa' && tipo == 'perdida') {
                    estadoVisible = 'Se sigue buscando';
                  } else if (estado == 'activa' && tipo == 'encontrada') {
                    estadoVisible = 'Se busca a su familia';
                  } else {
                    estadoVisible = publicacion['estado']?.toString() ?? '';
                  }

                  final urlFoto = obtenerUrlFoto(publicacion['foto']);
                  print('Ruta guardada: ${publicacion['foto']}');
                  print('URL generada: $urlFoto');

               return Card(
  margin: const EdgeInsets.only(bottom: 16),
  elevation: 2,
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  ),
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: () async {
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => DetallePublicacionPage(
            publicacion: publicacion,
            idUsuario: widget.idUsuario,
            tipoUsuario: 'usuario',
          ),
        ),
      );

      if (resultado == true && mounted) {
        await cargarPublicaciones();
      }
    },
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: urlFoto.isEmpty
                ? Container(
                    width: 105,
                    height: 105,
                    color: AppTheme.verdeClaro,
                    child: const Icon(
                      Icons.pets,
                      size: 38,
                      color: AppTheme.verdePrincipal,
                    ),
                  )
                : Image.network(
                    urlFoto,
                    width: 105,
                    height: 105,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 105,
                        height: 105,
                        color: AppTheme.verdeClaro,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 35,
                          color: AppTheme.verdePrincipal,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nombre.isEmpty ? especie : nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tipoVisible,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textoSecundario,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estado == 'activa'
                        ? AppTheme.verdeClaro
                        : estado == 'eliminada'
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estadoVisible,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: estado == 'activa'
                          ? AppTheme.verdeOscuro
                          : estado == 'eliminada'
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.textoSecundario,
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