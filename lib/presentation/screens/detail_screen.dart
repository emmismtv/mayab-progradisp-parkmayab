import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../widgets/common.dart';

/// Detalle de una visita: imagen (Hero), datos, mapa interactivo y botón
/// para abrir Google Maps con las coordenadas guardadas.
class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.reservation});
  final Reservation reservation;

  Future<void> _openMaps(BuildContext context) async {
    final r = reservation;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${r.lat},${r.lng}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showSnack(context, 'No se pudo abrir Google Maps.', error: true);
      }
    } catch (_) {
      if (context.mounted) {
        showSnack(context, 'No se pudo abrir Google Maps.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final point = LatLng(r.lat, r.lng);

    return Scaffold(
      appBar: brandAppBar(context, title: 'Detalle de visita', dark: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ReservationImage(
            reservation: r,
            width: double.infinity,
            height: 260,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(height: 16),
          Pad(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Cajón ${r.slotCode}',
                    style: AppText.slab(size: 24)),
              ),
              StatusLabel(r.status),
            ],
          )),
          const SizedBox(height: 14),
          Pad(Wrap(spacing: 8, runSpacing: 8, children: [
            InfoChip(Icons.calendar_today_outlined,
                DateFormat('dd MMM yyyy', 'es').format(r.createdAt)),
            InfoChip(Icons.schedule, DateFormat('HH:mm').format(r.createdAt)),
            InfoChip(Icons.layers_outlined, 'Piso ${r.floor}'),
            InfoChip(Icons.signpost_outlined, 'Ala ${r.wing}'),
            InfoChip(Icons.timer_outlined,
                'Vence ${DateFormat('HH:mm').format(r.expiresAt)}'),
          ])),
          const SectionTag('Nota del vehículo'),
          Pad(Text(r.note ?? 'Sin nota.',
              style: TextStyle(
                  fontSize: 15,
                  color: r.note == null ? AppColors.grey : AppColors.ink))),
          const SectionTag('Ubicación al apartar'),
          Pad(ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 230,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: point, zoom: 16),
                zoomControlsEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('reserva'),
                    position: point,
                    infoWindow: InfoWindow(title: 'Cajón ${r.slotCode}'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange),
                  ),
                },
                // Permite mover el mapa dentro de un ListView.
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
              ),
            ),
          )),
          const SizedBox(height: 8),
          Pad(Row(children: [
            const Icon(Icons.gps_fixed, size: 16, color: AppColors.grey),
            const SizedBox(width: 6),
            Text('${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}',
                style: const TextStyle(color: AppColors.grey)),
          ])),
          const SizedBox(height: 16),
          Pad(FilledButton.icon(
            onPressed: () => _openMaps(context),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Abrir en Google Maps'),
          )),
        ],
      ),
    );
  }
}
