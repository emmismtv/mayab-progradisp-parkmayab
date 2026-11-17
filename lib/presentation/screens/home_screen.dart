import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../controllers/parking_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Pantalla principal: mapa con el radio de 2 km y estado de la reserva.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    final campus = LatLng(c.settings.campus.lat, c.settings.campus.lng);
    final user = c.geofence?.position;

    return Scaffold(
      appBar: AppBar(title: const Text('ParkMayab')),
      drawer: const AppDrawer(current: AppRoutes.home),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: campus, zoom: 12.3),
              myLocationEnabled: user != null,
              myLocationButtonEnabled: false,
              circles: {
                Circle(
                  circleId: const CircleId('radio'),
                  center: campus,
                  radius: c.settings.radiusMeters,
                  fillColor: AppColors.orange.withValues(alpha: 0.15),
                  strokeColor: AppColors.orange,
                  strokeWidth: 2,
                ),
              },
              markers: {
                Marker(
                  markerId: const MarkerId('campus'),
                  position: campus,
                  infoWindow:
                      const InfoWindow(title: 'Universidad Anáhuac Mayab'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange),
                ),
              },
            ),
          ),
          _StatusPanel(controller: c),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.controller});
  final ParkingController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final cur = c.current;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _locationRow(context, c),
            const SizedBox(height: 12),
            if (cur != null) _currentCard(context, cur) else _reserveButton(context, c),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(BuildContext context, ParkingController c) {
    if (c.locating) {
      return const Row(children: [
        SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 12),
        Text('Obteniendo tu ubicación…'),
      ]);
    }
    if (c.locationError != null) {
      return Row(children: [
        const Icon(Icons.location_off, color: AppColors.occupied),
        const SizedBox(width: 8),
        Expanded(child: Text(c.locationError!)),
        TextButton(onPressed: c.refreshLocation, child: const Text('Reintentar')),
      ]);
    }
    final g = c.geofence;
    if (g == null) return const SizedBox.shrink();
    final color = g.inside ? AppColors.free : AppColors.occupied;
    return Row(children: [
      Icon(g.inside ? Icons.check_circle : Icons.warning_amber_rounded,
          color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          g.inside
              ? 'Estás a ${formatDistance(g.distanceMeters)} del campus. ¡Puedes apartar!'
              : 'Estás a ${formatDistance(g.distanceMeters)}. Debes estar a menos de 2 km.',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
      IconButton(onPressed: c.refreshLocation, icon: const Icon(Icons.refresh)),
    ]);
  }

  Widget _reserveButton(BuildContext context, ParkingController c) {
    return Column(children: [
      if (c.settings.demoMode)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Modo demostración: geocerca desactivada',
              style: TextStyle(color: AppColors.orange)),
        ),
      FilledButton.icon(
        onPressed: c.canReserve
            ? () => Navigator.pushNamed(context, AppRoutes.availability)
            : null,
        icon: const Icon(Icons.local_parking),
        label: const Text('Apartar lugar'),
      ),
    ]);
  }

  Widget _currentCard(BuildContext context, Reservation r) {
    final active = r.status == ReservationStatus.active;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange),
      ),
      child: Column(children: [
        Row(children: [
          Text('Cajón ${r.slotCode}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          StatusChip(r.status),
          const Spacer(),
          if (active)
            Row(children: [
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 4),
              CountdownText(
                  until: r.expiresAt,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Piso ${r.floor} · Ala ${r.wing}'),
        ),
        const SizedBox(height: 10),
        Row(children: [
          if (active)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.scanner),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear QR'),
              ),
            ),
          if (active) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.guide),
              icon: const Icon(Icons.directions),
              label: const Text('Mi guía'),
            ),
          ),
        ]),
      ]),
    );
  }
}
