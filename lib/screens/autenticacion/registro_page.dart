

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/app_theme.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});
  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final telefonoController = TextEditingController();
  final contrasenaController = TextEditingController();

  final String urlRegistro = 'http://10.0.2.2/huella_api/registro.php';
  bool nombreError = false;
  bool emailError = false;
  bool contrasenaError = false;
  bool _ocultarContrasena = true;

  String mensajeEmailError = '';
  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    telefonoController.dispose();
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
              const SizedBox(height: 20),

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
                'Crear cuenta',
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
                'Registrate para ayudar a encontrar mascotas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 30),

              // NOMBRE
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre y apellido *',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: nombreError
                      ? 'El nombre y apellido son obligatorios'
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              // CORREO
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: emailError ? mensajeEmailError : null,
                ),
              ),

              const SizedBox(height: 16),

              // TELÉFONO
              TextField(
                controller: telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // CONTRASEÑA
              TextField(
                controller: contrasenaController,
                obscureText: _ocultarContrasena,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
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
                      ? 'Este campo es obligatorio'
                      : null,
                ),
              ),

              const SizedBox(height: 25),

              // BOTÓN REGISTRARSE
              ElevatedButton.icon(
                onPressed: () async {
                  final partesNombre = nombreController.text.trim().split(
                    RegExp(r'\s+'),
                  );

                  final email = emailController.text.trim();
                  final emailVacio = email.isEmpty;

                  final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(email);

                  setState(() {
                    nombreError = partesNombre.length < 2;
                    emailError = emailVacio || !emailValido;
                    contrasenaError = contrasenaController.text.trim().isEmpty;

                    if (emailVacio) {
                      mensajeEmailError = 'Este campo es obligatorio';
                    } else if (!emailValido) {
                      mensajeEmailError =
                          'Formato de correo electrónico inválido';
                    } else {
                      mensajeEmailError = '';
                    }
                  });

                  if (nombreError || emailError || contrasenaError) {
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
                              'Completá los campos obligatorios para continuar.',
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
                    print('ESTOY EJECUTANDO EL REGISTRO');

                    final respuesta = await http.post(
                      Uri.parse(urlRegistro),
                      body: {
                        'nombre': nombreController.text,
                        'email': emailController.text,
                        'telefono': telefonoController.text,
                        'contrasena': contrasenaController.text,
                      },
                    );

                    print('RESPUESTA REGISTRO: ${respuesta.body}');

                    if (respuesta.body.contains('"ok":true')) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              '¡Registro exitoso!',
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
                                'Tu cuenta de HUELLA fue creada correctamente.',
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
                                  Navigator.pop(context);
                                },
                                child: const Text('Aceptar'),
                              ),
                            ],
                          );
                        },
                      );

                      nombreController.clear();
                      emailController.clear();
                      telefonoController.clear();
                      contrasenaController.clear();
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Error en el registro',
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
                                'No se pudo registrar el usuario. Por favor, intentá nuevamente.',
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
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'Registrarme',
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
                'Los campos marcados con * son obligatorios.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
