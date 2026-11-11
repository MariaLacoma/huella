
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CambiarCorreoPage extends StatefulWidget {
  final String email;

  const CambiarCorreoPage({
    super.key,
    required this.email,
  });

  @override
  State<CambiarCorreoPage> createState() => _CambiarCorreoPageState();
}

class _CambiarCorreoPageState extends State<CambiarCorreoPage> {
  final _formKey = GlobalKey<FormState>();

  final _contrasenaController = TextEditingController();
  final _nuevoCorreoController = TextEditingController();
  final _confirmarCorreoController = TextEditingController();

  bool _guardando = false;
  bool _mostrarContrasena = false;

  @override
  void dispose() {
    _contrasenaController.dispose();
    _nuevoCorreoController.dispose();
    _confirmarCorreoController.dispose();
    super.dispose();
  }

  Future<void> _cambiarCorreo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final usuario = supabase.auth.currentUser;

      if (usuario == null || usuario.email == null) {
        throw Exception('No se pudo obtener la cuenta autenticada.');
      }

      // Verificar la contraseña actual.
      await supabase.auth.signInWithPassword(
        email: usuario.email!,
        password: _contrasenaController.text,
      );

      // Solicitar el cambio de correo en Supabase Auth.
      await supabase.auth.updateUser(
        UserAttributes(
          email: _nuevoCorreoController.text.trim(),
        ),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Solicitud enviada'),
            content: const Text(
              'Se solicitó el cambio de correo electrónico. '
              'Revisá tu nueva dirección y seguí las instrucciones '
              'del mensaje de confirmación de Supabase. '
              'El cambio puede quedar pendiente hasta que confirmes.',
            ),
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

      Navigator.pop(context);
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar el correo: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar correo electrónico'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 60,
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Actualizar correo electrónico',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresá tu contraseña actual y la nueva dirección '
                  'de correo que querés utilizar para iniciar sesión.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                TextFormField(
                  initialValue: widget.email,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Correo actual',
                    prefixIcon: Icon(Icons.email_outlined),
                    suffixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _contrasenaController,
                  enabled: !_guardando,
                  obscureText: !_mostrarContrasena,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarContrasena
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarContrasena = !_mostrarContrasena;
                        });
                      },
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Ingresá tu contraseña actual';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nuevoCorreoController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo correo electrónico',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresá el nuevo correo';
                    }

                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(valor.trim())) {
                      return 'Ingresá un correo válido';
                    }

                    if (valor.trim().toLowerCase() ==
                        widget.email.trim().toLowerCase()) {
                      return 'El nuevo correo debe ser diferente';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmarCorreoController,
                  enabled: !_guardando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nuevo correo',
                    prefixIcon: Icon(Icons.mark_email_read_outlined),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Confirmá el nuevo correo';
                    }

                    if (valor.trim().toLowerCase() !=
                        _nuevoCorreoController.text.trim().toLowerCase()) {
                      return 'Los correos no coinciden';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _guardando ? null : _cambiarCorreo,
                  icon: _guardando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _guardando ? 'Enviando solicitud...' : 'Cambiar correo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
