import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../widgets/common.dart';

/// Detalle de una reserva: imagen (Hero), datos, mapa interactivo y botón
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
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final point = LatLng(r.lat, r.lng);

    return Scaffold(
      appBar: AppBar(title: Text('Cajón ${r.slotCode}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ReservationImage(
              reservation: r,
              width: double.infinity,
              height: 220,
              radius: 16),
          const SizedBox(height: 16),
          Row(children: [
            Text('Piso ${r.floor} · Ala ${r.wing}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            StatusChip(r.status),
          ]),
          const SizedBox(height: 8),
          Text('Reservado: ${fmt.format(r.createdAt)}'),
          Text('Vigencia hasta: ${fmt.format(r.expiresAt)}'),
          const SizedBox(height: 12),
          if (r.note != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notes, color: AppColors.orange),
                title: const Text('Nota'),
                subtitle: Text(r.note!),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Ubicación donde apartaste',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: point, zoom: 16),
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
          ),
          const SizedBox(height: 4),
          Text('${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openMaps(context),
            icon: const Icon(Icons.map),
            label: const Text('Abrir en Google Maps'),
          ),
        ],
      ),
    );
  }
}
