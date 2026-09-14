
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
void main() {
  runApp(const HuellaApp());
}

class HuellaApp extends StatelessWidget {
  const HuellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HUELLA',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const RegistroPage(),
    );
  }
}

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

    final String urlRegistro =
      'http://10.0.2.2/huella_api/registro.php';

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
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('HUELLA'),
        backgroundColor: const Color(0xFF16A085),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.pets,
              size: 70,
              color: Color(0xFF16A085),
            ),

            const SizedBox(height: 15),

            const Text(
              'Crear cuenta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2933),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Registrate para ayudar a encontrar mascotas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: contrasenaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: () async {
                      final respuesta = await http.post(
                        Uri.parse(urlRegistro),
                        body: {
                          'nombre': nombreController.text,
                          'email': emailController.text,
                          'telefono': telefonoController.text,
                          'contrasena': contrasenaController.text,
                        },
                      );

                      print(respuesta.body);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A085),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Registrarme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}