
import 'package:flutter/material.dart';
import 'package:huella/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CambiarContrasenaPage extends StatefulWidget {
  final String email;

  const CambiarContrasenaPage({
    super.key,
    required this.email,
  });

  @override
  State<CambiarContrasenaPage> createState() =>
      _CambiarContrasenaPageState();
}

class _CambiarContrasenaPageState extends State<CambiarContrasenaPage> {
  final _formKey = GlobalKey<FormState>();

  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  bool _mostrarContrasenas = false;
  bool _guardando = false;

  @override
  void dispose() {
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final usuario = supabase.auth.currentUser;

      final emailActual = usuario?.email ?? widget.email;

      if (emailActual.isEmpty) {
        throw Exception('No se pudo obtener el correo de la cuenta.');
      }

      // Verificar la contraseña actual.
      await supabase.auth.signInWithPassword(
        email: emailActual,
        password: _contrasenaActualController.text,
      );

      // Guardar la nueva contraseña en Supabase Auth.
      await supabase.auth.updateUser(
        UserAttributes(
          password: _nuevaContrasenaController.text,
        ),
      );

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
      'La contraseña se cambió correctamente.',
      style: TextStyle(
        color: AppTheme.verdeOscuro,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);

      Navigator.pop(context);
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar la contraseña: ${error.message}'),
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
        title: const Text('Cambiar contraseña'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 60,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Actualizá tu contraseña',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresá tu contraseña actual y luego escribí la nueva.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _contrasenaActualController,
                obscureText: !_mostrarContrasenas,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarContrasenas
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarContrasenas = !_mostrarContrasenas;
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
                controller: _nuevaContrasenaController,
                obscureText: !_mostrarContrasenas,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Ingresá una nueva contraseña';
                  }
                  if (valor == _contrasenaActualController.text) {
                    return 'La nueva contraseña debe ser diferente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmarContrasenaController,
                obscureText: !_mostrarContrasenas,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Confirmá la nueva contraseña';
                  }
                  if (valor != _nuevaContrasenaController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _guardando ? null : _cambiarContrasena,
                child: _guardando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Guardar nueva contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
