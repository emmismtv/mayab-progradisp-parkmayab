import '../../core/constants.dart';
import 'geo_point.dart';

/// Preferencias del usuario / configuración del campus.
class AppSettings {
  final bool demoMode;
  final GeoPoint campus;
  final double radiusMeters;

  const AppSettings({
    required this.demoMode,
    required this.campus,
    required this.radiusMeters,
  });

  factory AppSettings.defaults() => const AppSettings(
        demoMode: false,
        campus: GeoPoint(
            AppConstants.defaultCampusLat, AppConstants.defaultCampusLng),
        radiusMeters: AppConstants.defaultRadiusMeters,
      );

  AppSettings copyWith({bool? demoMode, GeoPoint? campus}) => AppSettings(
        demoMode: demoMode ?? this.demoMode,
        campus: campus ?? this.campus,
        radiusMeters: radiusMeters,
      );
}
