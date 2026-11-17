/// Excepción de la aplicación con un mensaje apto para mostrarse al usuario.
/// Las capas inferiores (data/services) traducen errores técnicos a esta clase.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}
