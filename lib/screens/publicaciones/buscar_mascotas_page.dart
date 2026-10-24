import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:latlong2/latlong.dart';

import 'ubicacion_publicacion_page.dart';

import 'detalle_publicacion_page.dart';

import '../../theme/app_theme.dart';

import '../../config/api_config.dart';

class BuscarMascotasPage extends StatefulWidget {
  final int? idUsuario;

  const BuscarMascotasPage({super.key, this.idUsuario});

  @override
  State<BuscarMascotasPage> createState() => _BuscarMascotasPageState();
}

class _BuscarMascotasPageState extends State<BuscarMascotasPage> {
  final buscarController = TextEditingController();

  String tipoSeleccionado = 'Todos';
  String especieSeleccionada = 'Todas';
  LatLng? ubicacionSeleccionada;
  double radioSeleccionado = 5;

  List<dynamic> publicaciones = [];
  List<dynamic> publicacionesFiltradas = [];
  bool cargando = false;
  bool mostrarFiltros = false;

  @override
  void initState() {
    super.initState();
    buscarPublicaciones();
  }

  Future<void> buscarPublicaciones() async {
    setState(() {
      cargando = true;
    });

    final url = Uri.parse('${ApiConfig.baseUrl}/buscar_publicaciones.php');

    final respuesta = await http.get(url);

    if (!mounted) return;

    final datos = jsonDecode(respuesta.body);
    if (datos['ok'] == true) {
      setState(() {
        publicaciones = datos['publicaciones'];
        cargando = false;
      });

      aplicarFiltros();
    } else {
      setState(() {
        publicaciones = [];
        publicacionesFiltradas = [];
        cargando = false;
      });
    }
  }

  void aplicarFiltros() {
    print('Texto buscado: "${buscarController.text}"');
    setState(() {
      publicacionesFiltradas = publicaciones.where((publicacion) {
        bool coincideTipo =
            tipoSeleccionado == 'Todos' ||
            publicacion['tipo'] == tipoSeleccionado;

        bool coincideEspecie =
            especieSeleccionada == 'Todas' ||
            publicacion['especie'] == especieSeleccionada;
        bool coincideTexto =
            buscarController.text.isEmpty ||
            publicacion['nombre'].toString().toLowerCase().contains(
              buscarController.text.toLowerCase(),
            ) ||
            publicacion['descripcion'].toString().toLowerCase().contains(
              buscarController.text.toLowerCase(),
            );

        bool coincideUbicacion = true;

        if (ubicacionSeleccionada != null) {
          final distancia = Distance();

          final ubicacionPublicacion = LatLng(
            double.parse(publicacion['latitud'].toString()),
            double.parse(publicacion['longitud'].toString()),
          );

          final distanciaKm = distancia.as(
            LengthUnit.Kilometer,
            ubicacionSeleccionada!,
            ubicacionPublicacion,
          );

          coincideUbicacion = distanciaKm <= radioSeleccionado;
        }

        return coincideTipo &&
            coincideEspecie &&
            coincideUbicacion &&
            coincideTexto;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Buscar mascotas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: buscarController,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                hintText: 'Nombre o descripción',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (texto) {
                aplicarFiltros();
              },
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: () {
                setState(() {
                  mostrarFiltros = !mostrarFiltros;
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: AppTheme.verdePrincipal),
                  const SizedBox(width: 8),
                  const Text(
                    'Filtrar por',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoPrincipal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    mostrarFiltros
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.verdePrincipal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (mostrarFiltros) ...[
              const Text(
                'Tipo de publicación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: tipoSeleccionado,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'Perdida', child: Text('Perdida')),
                  DropdownMenuItem(
                    value: 'Encontrada',
                    child: Text('Encontrada'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;
                  setState(() {
                    tipoSeleccionado = valor;
                  });
                  aplicarFiltros();
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Especie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: especieSeleccionada,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                  DropdownMenuItem(value: 'Perro', child: Text('Perro')),
                  DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (valor) {
                  if (valor == null) return;
                  setState(() {
                    especieSeleccionada = valor;
                  });
                  aplicarFiltros();
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: () async {
                  final ubicacion = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UbicacionPublicacionPage(
                        latitudInicial:
                            ubicacionSeleccionada?.latitude ?? -46.4397,
                        longitudInicial:
                            ubicacionSeleccionada?.longitude ?? -67.5197,
                      ),
                    ),
                  );

                  if (ubicacion != null) {
                    setState(() {
                      ubicacionSeleccionada = ubicacion;
                    });

                    aplicarFiltros();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ubicacionSeleccionada == null
                              ? 'Seleccionar ubicación'
                              : 'Ubicación seleccionada',
                          style: TextStyle(
                            color: ubicacionSeleccionada == null
                                ? AppTheme.textoSecundario
                                : AppTheme.textoPrincipal,
                          ),
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

              const SizedBox(height: 16),

              if (ubicacionSeleccionada != null) ...[
                const SizedBox(height: 16),

                const Text(
                  'Radio de búsqueda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textoPrincipal,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<double>(
                  initialValue: radioSeleccionado,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 km')),
                    DropdownMenuItem(value: 5, child: Text('5 km')),
                    DropdownMenuItem(value: 10, child: Text('10 km')),
                    DropdownMenuItem(value: 20, child: Text('20 km')),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      radioSeleccionado = valor;
                    });
                    aplicarFiltros();
                  },
                ),
              ],
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      buscarController.clear();
                      tipoSeleccionado = 'Todos';
                      especieSeleccionada = 'Todas';
                      ubicacionSeleccionada = null;
                      radioSeleccionado = 5;
                    });

                    aplicarFiltros();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar filtros'),
                ),
              ),
            ],

            const SizedBox(height: 28),

            if (cargando) const Center(child: CircularProgressIndicator()),

            if (!cargando && publicacionesFiltradas.isEmpty)
              Center(
                child: Text(
                  publicaciones.isEmpty
                      ? 'No hay publicaciones para mostrar.'
                      : 'No se encontraron mascotas con esos criterios.',
                  textAlign: TextAlign.center,
                ),
              ),

            if (!cargando && publicacionesFiltradas.isNotEmpty)
              SizedBox(
                height: 430,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: publicacionesFiltradas.length,
                  itemBuilder: (context, index) {
                    final publicacion = publicacionesFiltradas[index];

                    return SizedBox(
                      width: 300,
                      child: Card(
                        margin: const EdgeInsets.only(right: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            final resultado = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetallePublicacionPage(
                                  publicacion: publicacion,
                                  idUsuario: widget.idUsuario,
                                ),
                              ),
                            );

                            if (resultado == true && mounted) {
                              await buscarPublicaciones();
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                '${ApiConfig.baseUrl}/${publicacion['foto']}',
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 50,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      publicacion['nombre']
                                              .toString()
                                              .trim()
                                              .isNotEmpty
                                          ? publicacion['nombre']
                                          : publicacion['tipo']
                                                    .toString()
                                                    .toLowerCase() ==
                                                'encontrada'
                                          ? publicacion['especie']
                                                        .toString()
                                                        .toLowerCase() ==
                                                    'gato'
                                                ? 'Gato encontrado'
                                                : publicacion['especie']
                                                          .toString()
                                                          .toLowerCase() ==
                                                      'perro'
                                                ? 'Perro encontrado'
                                                : 'Mascota encontrada'
                                          : 'Nombre no informado',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textoPrincipal,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                publicacion['tipo']
                                                        .toString()
                                                        .toLowerCase() ==
                                                    'perdida'
                                                ? Colors.orange.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            publicacion['tipo']
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  publicacion['tipo']
                                                          .toString()
                                                          .toLowerCase() ==
                                                      'perdida'
                                                  ? Colors.orange.shade800
                                                  : Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          publicacion['especie'].toString(),
                                          style: const TextStyle(
                                            color: AppTheme.textoSecundario,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      publicacion['descripcion'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textoPrincipal,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Fecha: ${publicacion['fecha']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textoSecundario,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
