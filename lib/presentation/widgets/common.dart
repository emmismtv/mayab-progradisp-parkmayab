import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_paths.dart';
import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../routes.dart';

/// Drawer principal compartido por las pantallas de primer nivel.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, String route) => ListTile(
          leading: Icon(icon, color: AppColors.brown),
          title: Text(label),
          selected: current == route,
          selectedColor: AppColors.orange,
          onTap: () {
            Navigator.pop(context); // cierra el drawer
            if (current == route) return;
            if (route == AppRoutes.home) {
              Navigator.popUntil(context, (r) => r.isFirst);
            } else {
              Navigator.pushNamed(context, route);
            }
          },
        );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppColors.brown,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 24, 20, 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.orange,
                  child: Icon(Icons.local_parking,
                      color: Colors.white, size: 32),
                ),
                SizedBox(height: 12),
                Text('ParkMayab',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('Universidad Anáhuac Mayab',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          item(Icons.map_outlined, 'Inicio', AppRoutes.home),
          item(Icons.grid_view, 'Disponibilidad', AppRoutes.availability),
          item(Icons.qr_code_scanner, 'Escanear QR de la pluma',
              AppRoutes.scanner),
          item(Icons.directions, 'Mi guía al cajón', AppRoutes.guide),
          item(Icons.history, 'Historial', AppRoutes.history),
          const Divider(),
          item(Icons.settings_outlined, 'Ajustes', AppRoutes.settings),
        ],
      ),
    );
  }
}

/// Miniatura/imagen de una reserva. El `Hero` comparte la imagen entre la
/// lista y el detalle para una transición fluida.
class ReservationImage extends StatelessWidget {
  const ReservationImage({
    super.key,
    required this.reservation,
    this.width,
    this.height,
    this.radius = 12,
  });

  final Reservation reservation;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final file = reservation.photoFile;
    final Widget image = file == null
        ? Container(
            width: width,
            height: height,
            color: AppColors.brown.withValues(alpha: 0.12),
            child: const Icon(Icons.directions_car_filled,
                color: AppColors.brown, size: 36),
          )
        : Image.file(
            AppPaths.photo(file),
            width: width,
            height: height,
            fit: BoxFit.cover,
            // Si el archivo ya no existe, se muestra un ícono.
            errorBuilder: (_, _, _) => Container(
              width: width,
              height: height,
              color: Colors.black12,
              child: const Icon(Icons.broken_image_outlined),
            ),
          );
    return Hero(
      tag: 'reservation-photo-${reservation.id}',
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: image),
    );
  }
}

/// Etiqueta de color con el estado de la reserva.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReservationStatus.active => ('Apartado', AppColors.reserved),
      ReservationStatus.used => ('Estacionado', AppColors.free),
      ReservationStatus.completed => ('Finalizado', Colors.blueGrey),
      ReservationStatus.expired => ('Expirado', AppColors.occupied),
      ReservationStatus.cancelled => ('Cancelado', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color.withValues(alpha: 1),
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }
}

/// Cuenta regresiva (mm:ss) hasta que expira la reserva.
class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.until, this.style});
  final DateTime until;
  final TextStyle? style;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.until.difference(DateTime.now());
    if (left.isNegative) return Text('Expirada', style: widget.style);
    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$m:$s', style: widget.style);
  }
}

String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.occupied : AppColors.brown,
    ));
}
