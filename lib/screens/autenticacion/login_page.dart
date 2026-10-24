import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../administrador/panel_administrador_page.dart';
import '../perfil/perfil_page.dart';
import '../../config/api_config.dart';


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

 final String urlLogin = '${ApiConfig.baseUrl}/login.php';

  @override
  void dispose() {
    emailController.dispose();
    contrasenaController.dispose();
    super.dispose();
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

              // ICONO DE HUELLA
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

              // TÍTULO
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

              // DESCRIPCIÓN
              const Text(
                'Ingresá a tu cuenta de HUELLA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 30),

              // CORREO
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

              // CONTRASEÑA
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

              // BOTÓN INICIAR SESIÓN
              ElevatedButton.icon(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final contrasena = contrasenaController.text.trim();
                  final emailVacio = email.isEmpty;
                  final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(email);

                  setState(() {
                    emailError = emailVacio || !emailValido;
                    contrasenaError = contrasena.isEmpty;

                    if (emailVacio) {
                      mensajeEmailError =
                          'El correo electrónico es obligatorio';
                    } else if (!emailValido) {
                      mensajeEmailError =
                          'Formato de correo electrónico inválido';
                    } else {
                      mensajeEmailError = '';
                    }
                  });

                  if (emailError || contrasenaError) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Faltan datos',
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
                              'Completá los datos correctamente para continuar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actionsPadding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }

                  try {
                    final respuesta = await http.post(
                      Uri.parse(urlLogin),
                      body: {
                        'email': emailController.text,
                        'contrasena': contrasenaController.text,
                      },
                    );

                    print('RESPUESTA REGISTRO: ${respuesta.body}');
                    print(respuesta.body);

                    if (respuesta.body.contains('"ok":true')) {
                      final datos = jsonDecode(respuesta.body);
                      final usuario = datos['usuario'];
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
                              telefono: usuario['telefono'].toString(),
                            ),
                          ),
                        );
                      }
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Datos incorrectos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            content: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'El correo electrónico o la contraseña no son correctos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                  color: AppTheme.textoSecundario,
                                ),
                              ),
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actionsPadding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 20,
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Aceptar'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } catch (e) {
                    print(e);

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Error de conexión',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          content: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'No se pudo conectar con el servidor. Verificá la conexión e intentá nuevamente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actionsPadding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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