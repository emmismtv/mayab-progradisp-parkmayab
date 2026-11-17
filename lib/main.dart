import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_paths.dart';
import 'core/theme.dart';
import 'data/app_database.dart';
import 'data/repositories/sqlite_repositories.dart';
import 'domain/repositories/services.dart';
import 'domain/usecases/usecases.dart';
import 'presentation/controllers/parking_controller.dart';
import 'presentation/routes.dart';
import 'services/device_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPaths.init();

  // Composición de dependencias (raíz de la aplicación).
  final db = AppDatabase.instance;
  final slotRepo = SqliteSlotRepository(db);
  final reservationRepo = SqliteReservationRepository(db);
  final location = GeolocatorLocationService();
  final geofence = CheckGeofence(location);
  final expire = ExpireStaleReservations(reservationRepo, slotRepo);

  final controller = ParkingController(
    settingsRepo: PrefsSettingsRepository(),
    slotRepo: slotRepo,
    reservationRepo: reservationRepo,
    location: location,
    checkGeofence: geofence,
    reserveSlot: ReserveSlot(slotRepo, reservationRepo, geofence),
    validateGateQr: ValidateGateQr(reservationRepo, slotRepo, expire),
    closeReservation: CloseReservation(reservationRepo, slotRepo),
    expireStale: expire,
  )..init();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: controller),
      Provider<MediaService>(create: (_) => ImagePickerMediaService()),
      Provider<SpeechService>(create: (_) => SttSpeechService()),
    ],
    child: const ParkMayabApp(),
  ));
}

class ParkMayabApp extends StatelessWidget {
  const ParkMayabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkMayab',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
