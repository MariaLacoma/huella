import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ubicacion_publicacion_page.dart';
import 'detalle_publicacion_page.dart';
import '../../theme/app_theme.dart';

class BuscarMascotasPage extends StatefulWidget {
  final int? idUsuario;

  const BuscarMascotasPage({super.key, this.idUsuario});

  @override
  State<BuscarMascotasPage> createState() => _BuscarMascotasPageState();
}

class _BuscarMascotasPageState extends State<BuscarMascotasPage> {
  final buscarController = TextEditingController();

  String tipoSeleccionado = 'Todos';
  String fechaSeleccionada = 'Todas las fechas';
  String especieSeleccionada = 'Todas';
  String sexoSeleccionado = 'Todos';
  String tamanoSeleccionado = 'Todos';
  String edadSeleccionada = 'Todas';
  String colorSeleccionado = 'Todos';
  String razaSeleccionada = 'Todas';

  LatLng? ubicacionSeleccionada;
  double radioSeleccionado = 5;

  List<Map<String, dynamic>> publicaciones = [];
  List<Map<String, dynamic>> publicacionesFiltradas = [];

  bool cargando = false;
  bool mostrarFiltros = false;
  String? mensajeError;

  @override
  void initState() {
    super.initState();
    buscarPublicaciones();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  Future<void> buscarPublicaciones() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      mensajeError = null;
    });

    try {
      final resultado = await Supabase.instance.client
          .from('publicacion')
          .select()
          .neq('estado', 'eliminada')
          .order('fecha_creacion', ascending: false);

      if (!mounted) return;

      setState(() {
        publicaciones = resultado
            .map((fila) => Map<String, dynamic>.from(fila))
            .toList();
        cargando = false;
      });

      aplicarFiltros();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        publicaciones = [];
        publicacionesFiltradas = [];
        cargando = false;
        mensajeError = 'No se pudieron cargar las publicaciones.\n$e';
      });
    }
  }

  String normalizarTexto(dynamic valor) {
    return (valor ?? '').toString().trim().toLowerCase();
  }

  DateTime? obtenerFecha(dynamic valor) {
    if (valor == null) return null;

    return DateTime.tryParse(valor.toString());
  }

  bool coincideFecha(dynamic fechaPublicacion) {
    if (fechaSeleccionada == 'Todas las fechas') {
      return true;
    }

    final fecha = obtenerFecha(fechaPublicacion);

    if (fecha == null) return false;

    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaSeleccionada == 'Hoy') {
      return fechaSinHora == hoySinHora;
    }

    if (fechaSeleccionada == 'Últimos 7 días') {
      final desde = hoySinHora.subtract(const Duration(days: 6));

      return !fechaSinHora.isBefore(desde) && !fechaSinHora.isAfter(hoySinHora);
    }

    if (fechaSeleccionada == 'Últimos 30 días') {
      final desde = hoySinHora.subtract(const Duration(days: 29));

      return !fechaSinHora.isBefore(desde) && !fechaSinHora.isAfter(hoySinHora);
    }

    if (fechaSeleccionada == 'Mes pasado') {
      final primerDiaMesActual = DateTime(hoy.year, hoy.month, 1);

      final primerDiaMesPasado = DateTime(hoy.year, hoy.month - 1, 1);

      return !fechaSinHora.isBefore(primerDiaMesPasado) &&
          fechaSinHora.isBefore(primerDiaMesActual);
    }

    return true;
  }

  List<String> obtenerOpcionesDinamicas(String campo, String opcionInicial) {
    final valores = publicaciones
        .map((publicacion) => (publicacion[campo] ?? '').toString().trim())
        .where((valor) => valor.isNotEmpty)
        .toSet()
        .toList();

    valores.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [opcionInicial, ...valores];
  }

  Widget construirFiltro({
    required String titulo,
    required String valor,
    required List<String> opciones,
    required ValueChanged<String?> alCambiar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textoPrincipal,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          decoration: const InputDecoration(),
          items: opciones.map((opcion) {
            return DropdownMenuItem<String>(value: opcion, child: Text(opcion));
          }).toList(),
          onChanged: alCambiar,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void aplicarFiltros() {
    final texto = buscarController.text.trim().toLowerCase();

    final resultado = publicaciones.where((publicacion) {
      final camposBusqueda = [
        publicacion['nombre'],
        publicacion['especie'],
        publicacion['sexo'],
        publicacion['tamano'],
        publicacion['edad'],
        publicacion['color'],
        publicacion['raza'],
        publicacion['caracteristicas'],
        publicacion['descripcion'],
      ];

      final coincideTexto =
          texto.isEmpty ||
          camposBusqueda.any((campo) => normalizarTexto(campo).contains(texto));

      final coincideTipo =
          tipoSeleccionado == 'Todos' ||
          normalizarTexto(publicacion['tipo']) ==
              normalizarTexto(tipoSeleccionado);

      final coincideEspecie =
          especieSeleccionada == 'Todas' ||
          normalizarTexto(publicacion['especie']) ==
              normalizarTexto(especieSeleccionada);

      final coincideSexo =
          sexoSeleccionado == 'Todos' ||
          normalizarTexto(publicacion['sexo']) ==
              normalizarTexto(sexoSeleccionado);

      final coincideTamano =
          tamanoSeleccionado == 'Todos' ||
          normalizarTexto(publicacion['tamano']) ==
              normalizarTexto(tamanoSeleccionado);

      final coincideEdad =
          edadSeleccionada == 'Todas' ||
          normalizarTexto(publicacion['edad']) ==
              normalizarTexto(edadSeleccionada);

      final color = normalizarTexto(publicacion['color']);

      final coincideColor =
          colorSeleccionado == 'Todos' ||
          (colorSeleccionado == 'Otro' &&
              ![
                'blanco',
                'negro',
                'marrón',
                'gris',
                'amarillo',
                'combinado',
              ].contains(color)) ||
          color == normalizarTexto(colorSeleccionado);

      final raza = normalizarTexto(publicacion['raza']);

      final coincideRaza =
          razaSeleccionada == 'Todas' ||
          (razaSeleccionada == 'Raza conocida' &&
              raza != 'mestizo' &&
              raza != 'desconocida' &&
              raza.isNotEmpty) ||
          raza == normalizarTexto(razaSeleccionada);

      final coincideFechaHecho = coincideFecha(publicacion['fecha']);

      bool coincideUbicacion = true;

      if (ubicacionSeleccionada != null) {
        final latitud = double.tryParse(
          (publicacion['latitud'] ?? '').toString(),
        );

        final longitud = double.tryParse(
          (publicacion['longitud'] ?? '').toString(),
        );

        if (latitud == null || longitud == null) {
          coincideUbicacion = false;
        } else {
          final distanciaKm = const Distance().as(
            LengthUnit.Kilometer,
            ubicacionSeleccionada!,
            LatLng(latitud, longitud),
          );

          coincideUbicacion = distanciaKm <= radioSeleccionado;
        }
      }

      return coincideTexto &&
          coincideTipo &&
          coincideEspecie &&
          coincideSexo &&
          coincideTamano &&
          coincideEdad &&
          coincideColor &&
          coincideRaza &&
          coincideFechaHecho &&
          coincideUbicacion;
    }).toList();

    if (!mounted) return;

    setState(() {
      publicacionesFiltradas = resultado;
    });
  }

  void limpiarFiltros() {
    setState(() {
      buscarController.clear();

      tipoSeleccionado = 'Todos';
      fechaSeleccionada = 'Todas las fechas';
      especieSeleccionada = 'Todas';
      sexoSeleccionado = 'Todos';
      tamanoSeleccionado = 'Todos';
      edadSeleccionada = 'Todas';
      colorSeleccionado = 'Todos';
      razaSeleccionada = 'Todas';

      ubicacionSeleccionada = null;
      radioSeleccionado = 5;
    });

    aplicarFiltros();
  }

  String obtenerUrlFoto(dynamic foto) {
    if (foto == null || foto.toString().trim().isEmpty) {
      return '';
    }

    String ruta = foto.toString().trim();

    if (ruta.startsWith('https://') || ruta.startsWith('http://')) {
      return ruta;
    }

    const prefijo = 'fotos-mascotas/';

    if (ruta.startsWith(prefijo)) {
      ruta = ruta.substring(prefijo.length);
    }

    return Supabase.instance.client.storage
        .from('fotos-mascotas')
        .getPublicUrl(ruta);
  }

  String obtenerNombreMascota(Map<String, dynamic> publicacion) {
    final nombre = (publicacion['nombre'] ?? '').toString().trim();

    if (nombre.isNotEmpty) return nombre;

    final tipo = (publicacion['tipo'] ?? '').toString().toLowerCase();

    final especie = (publicacion['especie'] ?? '').toString().toLowerCase();

    if (tipo == 'encontrada') {
      if (especie == 'gato') return 'Gato encontrado';
      if (especie == 'perro') return 'Perro encontrado';
      return 'Mascota encontrada';
    }

    return 'Nombre no informado';
  }

  Widget construirFoto(Map<String, dynamic> publicacion) {
    final urlFoto = obtenerUrlFoto(publicacion['foto']);

    if (urlFoto.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 50,
            color: AppTheme.verdePrincipal,
          ),
        ),
      );
    }

    return Image.network(
      urlFoto,
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
              color: AppTheme.verdePrincipal,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
                labelText: 'Buscar mascota',
                hintText: 'Nombre, especie, raza, color o característica',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => aplicarFiltros(),
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
              construirFiltro(
                titulo: 'Tipo de publicación',
                valor: tipoSeleccionado,
                opciones: const ['Todos', 'Perdida', 'Encontrada'],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => tipoSeleccionado = valor);
                  aplicarFiltros();
                },
              ),

              construirFiltro(
                titulo: 'Fecha en que se perdió o encontró',
                valor: fechaSeleccionada,
                opciones: const [
                  'Todas las fechas',
                  'Hoy',
                  'Últimos 7 días',
                  'Últimos 30 días',
                  'Mes pasado',
                ],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => fechaSeleccionada = valor);
                  aplicarFiltros();
                },
              ),

              construirFiltro(
                titulo: 'Especie',
                valor: especieSeleccionada,
                opciones: const ['Todas', 'Perro', 'Gato', 'Otro'],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => especieSeleccionada = valor);
                  aplicarFiltros();
                },
              ),

              construirFiltro(
                titulo: 'Sexo',
                valor: sexoSeleccionado,
                opciones: const ['Todos', 'Macho', 'Hembra', 'No identificado'],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => sexoSeleccionado = valor);
                  aplicarFiltros();
                },
              ),

              construirFiltro(
                titulo: 'Tamaño',
                valor: tamanoSeleccionado,
                opciones: const [
                  'Todos',
                  'Pequeño',
                  'Mediano',
                  'Grande',
                  'Desconocido',
                ],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => tamanoSeleccionado = valor);
                  aplicarFiltros();
                },
              ),

              construirFiltro(
                titulo: 'Edad aproximada',
                valor: edadSeleccionada,
                opciones: const [
                  'Todas',
                  'Cachorro',
                  'Joven',
                  'Adulto',
                  'Adulto mayor',
                  'Desconocida',
                ],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => edadSeleccionada = valor);
                  aplicarFiltros();
                },
              ),

              construirFiltro(
                titulo: 'Color',
                valor: colorSeleccionado,
                opciones: const [
                  'Todos',
                  'Blanco',
                  'Negro',
                  'Marrón',
                  'Gris',
                  'Amarillo',
                  'Combinado',
                  'Otro',
                ],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => colorSeleccionado = valor);
                  aplicarFiltros();
                },
              ),

              construirFiltro(
                titulo: 'Raza',
                valor: razaSeleccionada,
                opciones: const [
                  'Todas',
                  'Mestizo',
                  'Raza conocida',
                  'Desconocida',
                ],
                alCambiar: (valor) {
                  if (valor == null) return;
                  setState(() => razaSeleccionada = valor);
                  aplicarFiltros();
                },
              ),

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
                  final ubicacion = await Navigator.push<LatLng>(
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

                  if (ubicacion != null && mounted) {
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
                    DropdownMenuItem(value: 1.0, child: Text('1 km')),
                    DropdownMenuItem(value: 5.0, child: Text('5 km')),
                    DropdownMenuItem(value: 10.0, child: Text('10 km')),
                    DropdownMenuItem(value: 20.0, child: Text('20 km')),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;
                    setState(() => radioSeleccionado = valor);
                    aplicarFiltros();
                  },
                ),
              ],

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: limpiarFiltros,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar filtros'),
                ),
              ),
            ],

            const SizedBox(height: 28),

            if (cargando) const Center(child: CircularProgressIndicator()),

            if (!cargando && mensajeError != null) ...[
              Text(mensajeError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: buscarPublicaciones,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],

            if (!cargando &&
                mensajeError == null &&
                publicacionesFiltradas.isEmpty)
              Center(
                child: Text(
                  publicaciones.isEmpty
                      ? 'No hay publicaciones para mostrar.'
                      : 'No se encontraron mascotas con esos criterios.',
                  textAlign: TextAlign.center,
                ),
              ),

            if (!cargando &&
                mensajeError == null &&
                publicacionesFiltradas.isNotEmpty)
              SizedBox(
                height: 430,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: publicacionesFiltradas.length,
                  itemBuilder: (context, index) {
                    final publicacion = publicacionesFiltradas[index];

                    final tipo = (publicacion['tipo'] ?? '').toString();

                    final tipoEsPerdida = tipo.toLowerCase() == 'perdida';

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
                              construirFoto(publicacion),

                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      obtenerNombreMascota(publicacion),
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
                                            color: tipoEsPerdida
                                                ? Colors.orange.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            tipo.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: tipoEsPerdida
                                                  ? Colors.orange.shade800
                                                  : Colors.green.shade800,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Text(
                                          (publicacion['especie'] ?? '')
                                              .toString(),
                                          style: const TextStyle(
                                            color: AppTheme.textoSecundario,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      (publicacion['descripcion'] ?? '')
                                          .toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textoPrincipal,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      'Fecha: ${(publicacion['fecha'] ?? '').toString()}',
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
