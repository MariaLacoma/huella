import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

import '../publicaciones/detalle_publicacion_page.dart';

class ReportesAdministradorPage extends StatefulWidget {
  const ReportesAdministradorPage({super.key});

  @override
  State<ReportesAdministradorPage> createState() =>
      _ReportesAdministradorPageState();
}

class _ReportesAdministradorPageState extends State<ReportesAdministradorPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> reportes = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarReportes();
  }

 Future<void> cargarReportes() async {
  if (!mounted) return;

  setState(() {
    cargando = true;
    error = null;
  });

  try {
    final resultado = await supabase
        .from('reporte')
        .select('*, publicacion(estado)')
        .order('fecha_creacion', ascending: false);

    if (!mounted) return;

    setState(() {
      reportes = List<Map<String, dynamic>>.from(resultado);
      cargando = false;
    });
  } on PostgrestException catch (e) {
    debugPrint('Error de Supabase: ${e.message}');

    if (!mounted) return;

    setState(() {
      cargando = false;
      error =
          'No se pudieron consultar los reportes. '
          'Verificá los permisos en Supabase.';
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      cargando = false;
      error = e.toString();
    });
  }
}

  Future<void> verPublicacion(int idPublicacion) async {
    try {
      final usuarioAuth = supabase.auth.currentUser;

      if (usuarioAuth == null) {
        throw Exception('No hay una sesión iniciada.');
      }

      final usuario = await supabase
          .from('usuario')
          .select('id_usuario')
          .eq('auth_user_id', usuarioAuth.id)
          .maybeSingle();

      if (usuario == null) {
        throw Exception('No se encontró el usuario administrador.');
      }

      final idUsuario = usuario['id_usuario'] as int;

      final resultado = await supabase
          .from('publicacion')
          .select()
          .eq('id_publicacion', idPublicacion)
          .maybeSingle();

      if (!mounted) return;

      if (resultado == null) {
       ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: AppTheme.verdeClaro,
    behavior: SnackBarBehavior.floating,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    content: const Text(
      'La publicación ya no existe.',
      style: TextStyle(
        color: AppTheme.verdeOscuro,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallePublicacionPage(
            publicacion: resultado,
            idUsuario: idUsuario,
            tipoUsuario: 'administrador',
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
      'No se pudo abrir la publicación: $e',
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

  Future<void> retirarPublicacionDesdeReporte(
    int idPublicacion,
    int idReporte,
  ) async {
    try {
      await supabase
          .from('publicacion')
          .update({'estado': 'eliminada'})
          .eq('id_publicacion', idPublicacion);

      await supabase
          .from('reporte')
          .update({'estado': 'revisado'})
          .eq('id_reporte', idReporte);

      if (!mounted) return;

      await cargarReportes();

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
      'Publicación retirada y reporte marcado como revisado.',
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
        'No se pudo completar la operación: $e',
        style: const TextStyle(
          color: AppTheme.error,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  debugPrint('Error al retirar publicación desde reporte: $e');
}
  }

  Future<void> marcarComoRevisado(int idReporte) async {
    try {
      await supabase
          .from('reporte')
          .update({'estado': 'revisado'})
          .eq('id_reporte', idReporte)
          .select()
          .single();

      if (!mounted) return;

      await cargarReportes();

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
      'Reporte marcado como revisado.',
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
        'No se pudo actualizar el reporte: $e',
        style: const TextStyle(
          color: AppTheme.error,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  debugPrint('Error al actualizar reporte: $e');
}
}  

  String formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha';

    final fechaConvertida = DateTime.tryParse(fecha.toString());

    if (fechaConvertida == null) return 'Sin fecha';

    return '${fechaConvertida.day.toString().padLeft(2, '0')}/'
        '${fechaConvertida.month.toString().padLeft(2, '0')}/'
        '${fechaConvertida.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.verdeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag,
                  size: 45,
                  color: AppTheme.verdePrincipal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reportes recibidos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reportes realizados por los usuarios de HUELLA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                    ? Center(
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
                            ElevatedButton.icon(
                              onPressed: cargarReportes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : reportes.isEmpty
                    ? const Center(
                        child: Text('Todavía no hay reportes recibidos.'),
                      )
                    : RefreshIndicator(
                        onRefresh: cargarReportes,
                        child: ListView.builder(
                          itemCount: reportes.length,
                          itemBuilder: (context, index) {
                            final reporte = reportes[index];
                            final estadoPublicacion =
    reporte['publicacion']?['estado']?.toString();

final publicacionRetirada = estadoPublicacion == 'eliminada';
debugPrint('Estado: $estadoPublicacion');
debugPrint('¿Está retirada?: $publicacionRetirada');
                            debugPrint('Estado de publicación: ${reporte['publicacion']}');

                            final motivo =
                                reporte['motivo']?.toString() ?? 'Sin motivo';

                            final descripcion =
                                reporte['descripcion']?.toString() ??
                                'Sin descripción';

                            final estado =
                                reporte['estado']?.toString() ?? 'pendiente';

                            final idUsuario =
                                reporte['id_usuario']?.toString() ??
                                'No disponible';

                            final idPublicacion =
                                reporte['id_publicacion']?.toString() ??
                                'No disponible';

                            final idReporte = int.tryParse(
                              reporte['id_reporte'].toString(),
                            );

                            final revisado = estado == 'revisado';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          revisado
                                              ? Icons.check_circle
                                              : Icons.pending_actions,
                                          color: revisado
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Reporte #${reporte['id_reporte']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textoPrincipal,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          revisado ? 'Revisado' : 'Pendiente',
                                          style: TextStyle(
                                            color: revisado
                                                ? Colors.green
                                                : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    Text('Motivo: $motivo'),
                                    const SizedBox(height: 6),
                                    Text('Descripción: $descripcion'),
                                    const SizedBox(height: 6),
                                    Text('Usuario que reportó: $idUsuario'),
                                    Text('Publicación: #$idPublicacion'),
                                    Text(
                                      'Fecha: ${formatearFecha(reporte['fecha_creacion'])}',
                                    ),
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            final id = int.tryParse(
                                              reporte['id_publicacion']
                                                  .toString(),
                                            );

                                            if (id != null) {
                                              verPublicacion(id);
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                          ),
                                          label: const Text('Ver publicación'),
                                          style: TextButton.styleFrom(
                                            alignment: Alignment.centerLeft,
                                          ),
                                        ),

                                        if (!revisado && idReporte != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              marcarComoRevisado(idReporte);
                                            },
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                            ),
                                            label: const Text(
                                              'Marcar como revisado',
                                            ),
                                            style: TextButton.styleFrom(
                                              alignment: Alignment.centerLeft,
                                            ),
                                          ),

                                        if (idReporte != null && !publicacionRetirada)
                                          TextButton.icon(
                                            onPressed: () async {
                                              final id = int.tryParse(
                                                reporte['id_publicacion']
                                                    .toString(),
                                              );

                                              if (id == null) return;

                                              final confirmar =
                                                  await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
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
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                              child: const Text(
                                                                'Cancelar',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                              child: const Text(
                                                                'Retirar',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );

                                              if (confirmar != true) return;

                                              try {
                                                await supabase
                                                    .from('publicacion')
                                                    .update({
                                                      'estado': 'eliminada',
                                                    })
                                                    .eq('id_publicacion', id);

                                                if (!mounted) return;

                                                await cargarReportes();

                                                if (!mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'La publicación fue retirada correctamente.',
                                                        ),
                                                      ),
                                                    );
                                              } catch (e) {
                                                if (!mounted) return;

                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'No se pudo retirar la publicación: $e',
                                                    ),
                                                  ),
                                                );

                                                debugPrint(
                                                  'Error al retirar publicación: $e',
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: const Text(
                                              'Retirar publicación',
                                            ),
                                            style: TextButton.styleFrom(
                                              alignment: Alignment.centerLeft,
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
