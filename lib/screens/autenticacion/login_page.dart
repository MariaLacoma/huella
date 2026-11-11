
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../administrador/panel_administrador_page.dart';
import '../perfil/perfil_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final contrasenaController = TextEditingController();

  bool emailError = false;
  bool contrasenaError = false;
  String mensajeEmailError = '';
  bool _ocultarContrasena = true;
  bool _cargando = false;

  @override
  void dispose() {
    emailController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = emailController.text.trim();
    final contrasena = contrasenaController.text;

    final emailVacio = email.isEmpty;
    final emailValido =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    setState(() {
      emailError = emailVacio || !emailValido;
      contrasenaError = contrasena.isEmpty;

      if (emailVacio) {
        mensajeEmailError = 'El correo electrónico es obligatorio';
      } else if (!emailValido) {
        mensajeEmailError = 'Formato de correo electrónico inválido';
      } else {
        mensajeEmailError = '';
      }
    });

    if (emailError || contrasenaError) {
      _mostrarMensaje(
        'Faltan datos',
        'Completá los datos correctamente para continuar.',
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final respuesta =
          await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: contrasena,
      );

      final usuarioAuth = respuesta.user;

      if (usuarioAuth == null) {
        _mostrarMensaje(
          'Datos incorrectos',
          'No se pudo iniciar sesión. Verificá tu correo y contraseña.',
        );
        return;
      }

      final usuario = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario, nombre, email, telefono, tipo, estado')
          .eq('auth_user_id', usuarioAuth.id)
          .maybeSingle();

      if (usuario == null) {
        await Supabase.instance.client.auth.signOut();

        _mostrarMensaje(
          'Perfil no encontrado',
          'La cuenta inició sesión, pero no se encontró su perfil en HUELLA.',
        );
        return;
      }

      if (usuario['estado'] != 'activo') {
        await Supabase.instance.client.auth.signOut();

        _mostrarMensaje(
          'Cuenta no disponible',
          'Tu cuenta no está habilitada para ingresar.',
        );
        return;
      }

      if (!mounted) return;

      final tipo = usuario['tipo'].toString();

      if (tipo == 'administrador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PanelAdministrador(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilPage(
              idUsuario: usuario['id_usuario'],
              nombre: usuario['nombre'].toString(),
              email: usuario['email'].toString(),
              telefono: usuario['telefono']?.toString() ?? '',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'No se pudo iniciar sesión',
        e.message,
      );
    } catch (e) {
      debugPrint('ERROR LOGIN SUPABASE: $e');

      if (!mounted) return;

      _mostrarMensaje(
        'Error de conexión',
        'No se pudo completar el inicio de sesión. Intentá nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String titulo, String mensaje) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: titulo == 'Datos incorrectos' ||
                      titulo == 'Error de conexión' ||
                      titulo == 'No se pudo iniciar sesión'
                  ? Colors.red
                  : AppTheme.verdePrincipal,
            ),
          ),
          content: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppTheme.textoSecundario,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 25),

              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppTheme.verdeClaro,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 55,
                    color: AppTheme.verdePrincipal,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Iniciar sesión',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Ingresá a tu cuenta de HUELLA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textoSecundario,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: emailError ? mensajeEmailError : null,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: contrasenaController,
                obscureText: _ocultarContrasena,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarContrasena
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarContrasena = !_ocultarContrasena;
                      });
                    },
                  ),
                  errorText: contrasenaError
                      ? 'La contraseña es obligatoria'
                      : null,
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: _cargando ? null : _iniciarSesion,
                icon: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _cargando ? 'Ingresando...' : 'Iniciar sesión',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Cancelar'),
              ),

              const SizedBox(height: 20),

              const Text(
                'Si todavía no tenés una cuenta, podés registrarte desde HUELLA.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textoSecundario,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
