
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'mi_cuenta_page.dart';
import '../publicaciones/buscar_mascotas_page.dart';
import '../publicaciones/crear_publicacion_page.dart';
import '../publicaciones/mis_publicaciones_page.dart';

class PerfilPage extends StatefulWidget {
  final int idUsuario;
  final String nombre;
  final String email;
  final String telefono;

  const PerfilPage({
    super.key,
    required this.idUsuario,
    required this.nombre,
    required this.email,
    required this.telefono,
  });

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  int indiceActual = 0;
  int _actualizacionPublicaciones = 0;


 @override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (indiceActual != 0) {
        setState(() {
          indiceActual = 0;
        });
      }
    },
    child: Scaffold(
      backgroundColor: AppTheme.fondo,
      body: IndexedStack(
        index: indiceActual,
       children: [
  _construirInicio(),

  BuscarMascotasPage(
      key: ValueKey(_actualizacionPublicaciones),
    idUsuario: widget.idUsuario,
    onVolverInicio: () {
      setState(() {
        indiceActual = 0;
      });
    },
  ),

  MisPublicacionesPage(
      key: ValueKey(_actualizacionPublicaciones),
    idUsuario: widget.idUsuario,
    onVolverInicio: () {
      setState(() {
        indiceActual = 0;
      });
    },
  ),

  MiCuentaPage(
    idUsuario: widget.idUsuario,
    nombre: widget.nombre,
    email: widget.email,
    telefono: widget.telefono,
  ),
],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indiceActual,
        onTap: (indice) {
          setState(() {
            indiceActual = indice;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.verdePrincipal,
        unselectedItemColor: AppTheme.textoSecundario,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Mis publicaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Mi cuenta',
          ),
        ],
      ),
    ),
  );
}
 

Widget _construirInicio() {
  return Scaffold(
    backgroundColor: AppTheme.fondo,
    appBar: AppBar(
      title: const Text(
        'HUELLA',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppTheme.fondo,
      foregroundColor: AppTheme.textoPrincipal,
      elevation: 0,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            Text(
              '¡Hola, ${widget.nombre}!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textoPrincipal,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Estamos para ayudar a reunir mascotas con sus familias.',
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: AppTheme.textoSecundario,
              ),
            ),

            const SizedBox(height: 24),

            // ILUSTRACIÓN DE MASCOTAS
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: AppTheme.verdeClaro,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 18,
                    right: 25,
                    child: Icon(
                      Icons.favorite,
                      size: 35,
                      color: AppTheme.verdePrincipal.withValues(alpha: 0.25),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 25,
                    child: Icon(
                      Icons.pets,
                      size: 42,
                      color: AppTheme.verdePrincipal.withValues(alpha: 0.25),
                    ),
                  ),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 105,
                        color: AppTheme.verdePrincipal,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Cada mascota merece volver a casa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.verdeOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // NUEVA PUBLICACIÓN
            Material(
              color: AppTheme.verdePrincipal,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
               onTap: () async {
  final resultado = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => CrearPublicacionPage(
        idUsuario: widget.idUsuario,
      ),
    ),
  );

  if (resultado == true) {
setState(() {
  _actualizacionPublicaciones++;
});
  }
},
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nueva publicación',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Publicá una mascota perdida o encontrada',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _elementoInformativo(String texto) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppTheme.verdePrincipal,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textoSecundario,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _opcionPrincipal({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.verdeClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  size: 28,
                  color: AppTheme.verdePrincipal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
