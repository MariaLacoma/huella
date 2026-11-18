import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> usuarios = [];
  bool cargando = true;
  String? error;
  bool esAdministrador = false;
  String? idAdministradorAuth;

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cambiarEstadoUsuario(Map<String, dynamic> usuario) async {
    final id = usuario['id_usuario'];
    final estadoActual = usuario['estado']?.toString();

    final nuevoEstado = estadoActual == 'activo' ? 'bloqueado' : 'activo';

    try {
      await supabase
          .from('usuario')
          .update({'estado': nuevoEstado})
          .eq('id_usuario', id);

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
      'Usuario ${nuevoEstado == 'activo' ? 'habilitado' : 'bloqueado'} correctamente.',
      style: const TextStyle(
        color: AppTheme.verdeOscuro,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);

      await cargarUsuarios();
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
      'No se pudo actualizar el usuario: $e',
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

  Future<void> cargarUsuarios() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final autenticado = supabase.auth.currentUser;
      idAdministradorAuth = autenticado?.id;

      if (autenticado == null) {
        throw Exception('Iniciá sesión para consultar los usuarios.');
      }

      // Comprobar el rol de la cuenta autenticada.
      final perfil = await supabase
          .from('usuario')
          .select('tipo')
          .eq('auth_user_id', autenticado.id)
          .maybeSingle();

      if (perfil == null) {
        throw Exception('No se encontró el perfil asociado a tu cuenta.');
      }

      final tipo = (perfil['tipo'] ?? '').toString().trim().toLowerCase();

      if (tipo != 'administrador' && tipo != 'admin') {
        esAdministrador = false;
        throw Exception('Tu cuenta no tiene permisos de administrador.');
      }

      esAdministrador = true;

      // Obtener los usuarios registrados.
      final resultado = await supabase
          .from('usuario')
          .select('id_usuario, nombre, email, tipo, estado')
          .order('nombre');

      if (!mounted) return;

      setState(() {
        usuarios = List<Map<String, dynamic>>.from(resultado);
        cargando = false;
      });
    } on PostgrestException catch (e) {
      debugPrint('Error de Supabase al consultar usuarios: ${e.message}');
      debugPrint('Código: ${e.code}');

      if (!mounted) return;

      setState(() {
        cargando = false;
        error =
            'No se pudieron consultar los usuarios. '
            'Verificá los permisos de lectura en Supabase.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Usuarios registrados'),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: cargando
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
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
                              Text(
                                error!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: cargarUsuarios,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : usuarios.isEmpty
                          ? const Center(
                              child: Text(
                                'Todavía no hay usuarios registrados.',
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: cargarUsuarios,
                              child: ListView.builder(
                                itemCount: usuarios.length,
                                itemBuilder: (context, index) {
                                  final usuario = usuarios[index];

                                  return Card(
                                    elevation: 1,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: AppTheme.verdeClaro,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const CircleAvatar(
                                            radius: 23,
                                            backgroundColor:
                                                AppTheme.verdeClaro,
                                            child: Icon(
                                              Icons.person_outline,
                                              color: AppTheme.verdePrincipal,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  usuario['nombre']
                                                          ?.toString() ??
                                                      'Sin nombre',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppTheme
                                                        .textoPrincipal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  usuario['email']
                                                          ?.toString() ??
                                                      'Sin correo',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme
                                                        .textoSecundario,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 6,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 9,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .verdeClaro,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        (usuario['tipo']
                                                                        ?.toString()
                                                                        .toLowerCase() ==
                                                                    'admin' ||
                                                                usuario['tipo']
                                                                        ?.toString()
                                                                        .toLowerCase() ==
                                                                    'administrador')
                                                            ? 'Administrador'
                                                            : 'Usuario',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppTheme
                                                              .verdeOscuro,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 9,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: usuario[
                                                                    'estado'] ==
                                                                'activo'
                                                            ? AppTheme
                                                                .verdeClaro
                                                            : const Color(
                                                                0xFFFCEBEA,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        'Estado: ${usuario['estado']?.toString() ?? 'Sin estado'}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: usuario[
                                                                      'estado'] ==
                                                                  'activo'
                                                              ? AppTheme
                                                                  .verdeOscuro
                                                              : AppTheme.error,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (usuario['tipo'] == 'usuario')
                                            IconButton(
                                              icon: Icon(
                                                usuario['estado'] == 'activo'
                                                    ? Icons.block
                                                    : Icons.check_circle,
                                                color:
                                                    usuario['estado'] ==
                                                            'activo'
                                                        ? AppTheme.error
                                                        : AppTheme
                                                            .verdePrincipal,
                                              ),
                                              tooltip:
                                                  usuario['estado'] == 'activo'
                                                      ? 'Bloquear usuario'
                                                      : 'Habilitar usuario',
                                              onPressed: () =>
                                                  cambiarEstadoUsuario(usuario),
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

