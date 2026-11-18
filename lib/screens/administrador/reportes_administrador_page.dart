
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

class _ReportesAdministradorPageState
    extends State<ReportesAdministradorPage> {
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
            backgroundColor: const Color(0xFFFCEBEA),
            behavior: SnackBarBehavior.floating,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: const Text(
              'La publicación ya no existe.',
              style: TextStyle(
                color: AppTheme.error,
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

      if (mounted) {
        await cargarReportes();
      }
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

  Widget construirDato(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textoSecundario,
          ),
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textoPrincipal,
              ),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes recibidos'),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 42,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: cargarReportes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarReportes,
                  child: reportes.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: const [
                            SizedBox(height: 120),
                            Icon(
                              Icons.flag_outlined,
                              size: 60,
                              color: AppTheme.verdePrincipal,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Todavía no hay reportes recibidos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: reportes.length,
                          itemBuilder: (context, index) {
                            final reporte = reportes[index];

                            final motivo =
                                reporte['motivo']?.toString() ??
                                    'Sin motivo';

                            final descripcion =
                                reporte['descripcion']?.toString() ??
                                    'Sin descripción';

                            final estado =
                                reporte['estado']?.toString() ??
                                    'pendiente';

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

                            final publicacionRelacion =
                                reporte['publicacion'];

                            final estadoPublicacion =
                                publicacionRelacion is Map
                                    ? publicacionRelacion['estado']
                                        ?.toString()
                                    : null;

                            final publicacionRetirada =
                                estadoPublicacion == 'eliminada';

                            final idPublicacionNumero =
                                int.tryParse(idPublicacion);

                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: AppTheme.verdeClaro,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag_outlined,
                                          size: 22,
                                          color: AppTheme.verdePrincipal,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Reporte #${reporte['id_reporte']}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textoPrincipal,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: revisado
                                                ? AppTheme.verdeClaro
                                                : const Color(0xFFFFF3E0),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            revisado
                                                ? 'Revisado'
                                                : 'Pendiente',
                                            maxLines: 1,
                                            softWrap: false,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1,
                                              fontWeight: FontWeight.w600,
                                              color: revisado
                                                  ? AppTheme.verdeOscuro
                                                  : Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(
                                      color: AppTheme.verdeClaro,
                                    ),
                                    const SizedBox(height: 8),

                                    construirDato('Motivo', motivo),
                                    construirDato(
                                      'Descripción',
                                      descripcion,
                                    ),
                                    construirDato(
                                      'Usuario que reportó',
                                      idUsuario,
                                    ),
                                    construirDato(
                                      'Publicación',
                                      '#$idPublicacion',
                                    ),
                                    construirDato(
                                      'Fecha',
                                      formatearFecha(
                                        reporte['fecha_creacion'],
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                    const Divider(
                                      color: AppTheme.verdeClaro,
                                    ),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextButton.icon(
                                          onPressed:
                                              idPublicacionNumero == null
                                                  ? null
                                                  : () {
                                                      verPublicacion(
                                                        idPublicacionNumero,
                                                      );
                                                    },
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                          ),
                                          label: const Text(
                                            'Ver publicación',
                                          ),
                                          style: TextButton.styleFrom(
                                            alignment:
                                                Alignment.centerLeft,
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
                                              alignment:
                                                  Alignment.centerLeft,
                                              foregroundColor:
                                                  AppTheme.verdeOscuro,
                                            ),
                                          ),

                                        if (idReporte != null &&
                                            idPublicacionNumero != null &&
                                            !publicacionRetirada)
                                          TextButton.icon(
                                            onPressed: () async {
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
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                          dialogContext,
                                                          true,
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Retirar',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmar != true) return;

                                              await retirarPublicacionDesdeReporte(
                                                idPublicacionNumero,
                                                idReporte,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: const Text(
                                              'Retirar publicación',
                                            ),
                                            style: TextButton.styleFrom(
                                              alignment:
                                                  Alignment.centerLeft,
                                              foregroundColor: Colors.red,
                                            ),
                                          ),

                                        if (publicacionRetirada)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 18,
                                                  color: AppTheme
                                                      .textoSecundario,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Publicación retirada',
                                                  style: TextStyle(
                                                    fontSize: 13,
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
                            );
                          },
                        ),
                ),
    );
  }
}
