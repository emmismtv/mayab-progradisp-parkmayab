/// Datos del alumno que usa la app (se muestran en Inicio, Drawer y Perfil).
class UserProfile {
  final String name;
  final String studentId;
  final String email;

  /// Solo el nombre del archivo; ver [AppPaths].
  final String? photoFile;

  const UserProfile({
    required this.name,
    required this.studentId,
    required this.email,
    this.photoFile,
  });

  factory UserProfile.defaults() => const UserProfile(
        name: 'Alumno Anáhuac',
        studentId: '00000000',
        email: 'alumno@anahuac.mx',
      );

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  UserProfile copyWith({
    String? name,
    String? studentId,
    String? email,
    String? photoFile,
  }) =>
      UserProfile(
        name: name ?? this.name,
        studentId: studentId ?? this.studentId,
        email: email ?? this.email,
        photoFile: photoFile ?? this.photoFile,
      );
}
