
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

class EditarPerfilPage extends StatefulWidget {
  final int idUsuario;
  final String nombre;
  final String telefono;
  final String email;

  const EditarPerfilPage({
    super.key,
    required this.idUsuario,
    required this.nombre,
    required this.telefono,
    required this.email,
  });

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  late final TextEditingController nombreController;
  late final TextEditingController telefonoController;

  final SupabaseClient supabase = Supabase.instance.client;

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.nombre);
    telefonoController = TextEditingController(text: widget.telefono);
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: esError
            ? const Color(0xFFB93838)
            : const Color(0xFF238653),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          mensaje,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String normalizarTelefono(String telefono) {
    return telefono.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool telefonoValido(String telefono) {
    final soloNumeros = normalizarTelefono(telefono);

    // Formato internacional argentino para WhatsApp.
    // Debe comenzar con 549 y tener 13 dígitos.
    return RegExp(r'^549\d{10}$').hasMatch(soloNumeros);
  }

  Future<void> guardarCambios() async {
    final nombre = nombreController.text.trim();
    final telefonoIngresado = telefonoController.text.trim();
    final telefono = normalizarTelefono(telefonoIngresado);
    final usuarioAutenticado = supabase.auth.currentUser;

    if (nombre.isEmpty) {
      mostrarMensaje('El nombre es obligatorio.', esError: true);
      return;
    }

    if (telefonoIngresado.isEmpty) {
      mostrarMensaje('El teléfono es obligatorio.', esError: true);
      return;
    }

    if (!telefonoValido(telefonoIngresado)) {
      mostrarMensaje(
        'Ingresá un teléfono argentino válido con código de país. '
        'Ejemplo: +54 9 2902 123456.',
        esError: true,
      );
      return;
    }

    if (usuarioAutenticado == null) {
      mostrarMensaje(
        'Iniciá sesión para modificar tu perfil.',
        esError: true,
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final resultado = await supabase
          .from('usuario')
          .update({
            'nombre': nombre,
            'telefono': telefono,
          })
          .eq('id_usuario', widget.idUsuario)
          .eq('auth_user_id', usuarioAutenticado.id)
          .select('id_usuario')
          .maybeSingle();

      if (!mounted) return;

      if (resultado == null) {
        mostrarMensaje(
          'No se pudieron actualizar los datos. Verificá los permisos '
          'de Supabase y que el perfil corresponda a tu cuenta.',
          esError: true,
        );
        return;
      }

      final datosActualizados = {
        'nombre': nombre,
        'telefono': telefono,
      };

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '¡Listo!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.verdePrincipal,
              ),
            ),
            content: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                'Tus datos fueron actualizados correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, datosActualizados);
    } catch (error) {
      debugPrint('Error al actualizar perfil: $error');

      if (!mounted) return;

      mostrarMensaje(
        'Ocurrió un error al guardar los datos. '
        'Revisá la conexión y los permisos.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 45,
                backgroundColor: AppTheme.verdeClaro,
                child: Icon(
                  Icons.edit,
                  size: 45,
                  color: AppTheme.verdePrincipal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Modificar datos personales',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Actualizá tu nombre y teléfono.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textoSecundario,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nombreController,
                enabled: !guardando,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefonoController,
                enabled: !guardando,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9+\s()-]'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+54 9 2902 123456',
                  helperText: 'Ingresá el código de país +54 9.',
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: guardando ? null : guardarCambios,
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  guardando ? 'Guardando...' : 'Guardar cambios',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: guardando
                    ? null
                    : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
