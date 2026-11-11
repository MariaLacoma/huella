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
                  Icons.people,
                  size: 45,
                  color: AppTheme.verdePrincipal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Usuarios registrados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usuarios registrados en HUELLA',
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
                              onPressed: cargarUsuarios,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : usuarios.isEmpty
                    ? const Center(
                        child: Text('Todavía no hay usuarios registrados.'),
                      )
                    : RefreshIndicator(
                        onRefresh: cargarUsuarios,
                        child: ListView.builder(
                          itemCount: usuarios.length,
                          itemBuilder: (context, index) {
                            final usuario = usuarios[index];

                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppTheme.verdeClaro,
                                  child: Icon(
                                    Icons.person,
                                    color: AppTheme.verdePrincipal,
                                  ),
                                ),
                                title: Text(
                                  usuario['nombre']?.toString() ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textoPrincipal,
                                  ),
                                ),
                                subtitle: Text(
                                  '${usuario['email'] ?? 'Sin correo'}\n'
                                  'Rol: ${usuario['tipo'] ?? 'Sin rol'}'
                                  ' · Estado: ${usuario['estado'] ?? 'Sin estado'}',
                                  style: const TextStyle(
                                    color: AppTheme.textoSecundario,
                                  ),
                                ),
                                isThreeLine: true,
                               trailing: usuario['tipo'] == 'usuario'
    ? IconButton(
        icon: Icon(
          usuario['estado'] == 'activo'
              ? Icons.block
              : Icons.check_circle,
          color: usuario['estado'] == 'activo'
              ? Colors.red
              : Colors.green,
        ),
        tooltip: usuario['estado'] == 'activo'
            ? 'Bloquear usuario'
            : 'Habilitar usuario',
        onPressed: () => cambiarEstadoUsuario(usuario),
      )
    : null,
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
