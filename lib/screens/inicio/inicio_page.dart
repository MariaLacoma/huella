import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../autenticacion/login_page.dart';
import '../autenticacion/registro_page.dart';
import '../publicaciones/crear_publicacion_page.dart';
import '../publicaciones/buscar_mascotas_page.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              // ICONO DE HUELLA
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.verdeClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  size: 70,
                  color: AppTheme.verdePrincipal,
                ),
              ),

              const SizedBox(height: 24),

              // NOMBRE DE LA APP
              const Text(
                'HUELLA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              // FRASE PRINCIPAL
              const Text(
                'Encontrá. Ayudá. Reuní.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.verdePrincipal,
                ),
              ),

              const SizedBox(height: 12),

              // DESCRIPCIÓN
              const Text(
                'Ayudamos a encontrar mascotas perdidas '
                'y conectar a las familias con sus mascotas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textoSecundario,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 35),

              // TARJETA INFORMATIVA
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.favorite_outline,
                        size: 32,
                        color: AppTheme.verdePrincipal,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '¿Perdiste o encontraste una mascota?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Podés buscar casos publicados o registrarte '
                        'para publicar una mascota y ayudar a encontrarla.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textoSecundario,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // BUSCAR
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuscarMascotasPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Buscar mascotas'),
              ),

              const SizedBox(height: 14),

              // REGISTRARSE
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistroPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Registrarme'),
              ),

              const SizedBox(height: 14),

              // INICIAR SESIÓN
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión'),
              ),

              const SizedBox(height: 25),

              const Text(
                'También podés consultar las publicaciones '
                'sin crear una cuenta.',
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
