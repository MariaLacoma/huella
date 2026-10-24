
class ApiConfig {
  // Cambiar a true para usar el servidor de Internet.
  // Dejar en false para desarrollar con XAMPP.
  static const bool usarServidorOnline = false;

  static const String servidorLocal =
      'http://10.0.2.2/huella_api';

  static const String servidorOnline =
      'https://huellaapp.great-site.net/huella_api';

  static String get baseUrl {
    return usarServidorOnline ? servidorOnline : servidorLocal;
  }
}
