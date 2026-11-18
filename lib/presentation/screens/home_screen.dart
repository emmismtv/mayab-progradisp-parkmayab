import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../controllers/parking_controller.dart';
import '../controllers/shell_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Inicio: bienvenida, estado de la geocerca o pase activo, mapa,
/// disponibilidad por piso y accesos rápidos.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    final shell = context.read<ShellController>();

    return Scaffold(
      appBar: brandAppBar(context, title: 'ParkMayab'),
      drawer: const AppDrawer(),
      body: RefreshIndicator.adaptive(
        onRefresh: c.refreshAll,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 20),
            Pad(Row(children: [
              const ProfileAvatar(radius: 26),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('¡Bienvenido!', style: AppText.slab(size: 20)),
                Text(c.profile.firstName,
                    style: const TextStyle(
                        color: AppColors.grey, fontSize: 16)),
              ]),
            ])),
            const SizedBox(height: 20),
            Pad(Text.rich(TextSpan(
              style: const TextStyle(fontSize: 16, color: AppColors.grey),
              children: [
                const TextSpan(text: 'Tu estacionamiento en\n'),
                TextSpan(
                    text: 'la Anáhuac Mayab',
                    style: AppText.slab(size: 16, weight: FontWeight.w700)),
              ],
            ))),
            const SectionTag('Tu lugar', top: 16),
            Pad(c.current != null
                ? ReservationPassCard(
                    reservation: c.current!,
                    footer: _PassActions(
                        active:
                            c.current!.status == ReservationStatus.active),
                  )
                : const _GeofenceCard()),
            const SectionTag('Ubicación'),
            const Pad(_CampusMap()),
            const SectionTag('Disponibilidad hoy'),
            const _OccupancyStrip(),
            const SizedBox(height: 24),
            Pad(Text('Descubre',
                style: AppText.slab(size: 17, color: AppColors.grey))),
            const SizedBox(height: 12),
            Pad(GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                ActionTile(
                    icon: Icons.add_location_alt_outlined,
                    title: 'Apartar',
                    subtitle: 'Lugar',
                    onTap: () => shell.go(Tabs.spots)),
                ActionTile(
                    icon: Icons.qr_code_scanner,
                    title: 'Escanear',
                    subtitle: 'Pluma',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.scanner)),
                ActionTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Mi pase',
                    subtitle: 'Digital',
                    onTap: () => shell.go(Tabs.pass)),
                ActionTile(
                    icon: Icons.history,
                    title: 'Historial',
                    subtitle: 'Visitas',
                    onTap: () => shell.go(Tabs.history)),
                ActionTile(
                    icon: Icons.badge_outlined,
                    title: 'Mi perfil',
                    subtitle: 'Anáhuac',
                    onTap: () => shell.go(Tabs.profile)),
                ActionTile(
                    icon: Icons.tune,
                    title: 'Ajustes',
                    subtitle: 'App',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.settings)),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

class _PassActions extends StatelessWidget {
  const _PassActions({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final white = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.orange,
      minimumSize: const Size.fromHeight(44),
    );
    return Row(children: [
      if (active) ...[
        Expanded(
          child: FilledButton.icon(
            style: white,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scanner),
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text('Escanear'),
          ),
        ),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 1.5),
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: () => context.read<ShellController>().go(Tabs.pass),
          icon: const Icon(Icons.directions, size: 20),
          label: const Text('Cómo llegar'),
        ),
      ),
    ]);
  }
}

/// Tarjeta de geocerca: indica si el alumno puede apartar.
class _GeofenceCard extends StatelessWidget {
  const _GeofenceCard();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    final g = c.geofence;

    final (IconData icon, Color color, String title, String subtitle) =
        c.locating
            ? (Icons.my_location, AppColors.grey, 'Buscando tu ubicación…',
                'Usamos el GPS para saber si estás cerca.')
            : c.locationError != null
                ? (Icons.location_off, AppColors.occupied,
                    'Sin ubicación', c.locationError!)
                : g == null
                    ? (Icons.my_location, AppColors.grey, 'Ubicación', '')
                    : g.inside
                        ? (Icons.check_circle, AppColors.free,
                            'Estás cerca del campus',
                            'A ${formatDistance(g.distanceMeters)}. ¡Ya puedes apartar!')
                        : (Icons.near_me_disabled, AppColors.occupied,
                            'Fuera del radio',
                            'Estás a ${formatDistance(g.distanceMeters)}. Acércate a menos de 2 km.');

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: c.locating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                  : Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.slab(size: 16)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.grey)),
                ],
              ),
            ),
            IconButton(
              onPressed: c.locating ? null : c.refreshLocation,
              icon: const Icon(Icons.refresh, color: AppColors.grey),
            ),
          ]),
          if (c.settings.demoMode)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: InfoChip(Icons.science_outlined, 'Modo demostración'),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: c.canReserve
                ? () => context.read<ShellController>().go(Tabs.spots)
                : null,
            icon: const Icon(Icons.local_parking),
            label: const Text('Apartar lugar'),
          ),
        ],
      ),
    );
  }
}

/// Vista previa del mapa con el radio de 2 km.
class _CampusMap extends StatelessWidget {
  const _CampusMap();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    final campus = LatLng(c.settings.campus.lat, c.settings.campus.lng);
    final g = c.geofence;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 200,
        child: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: campus, zoom: 12.2),
            myLocationEnabled: g != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
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
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange),
              ),
            },
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 8)
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school_outlined,
                    size: 16, color: AppColors.orange),
                const SizedBox(width: 6),
                Text(
                    g == null
                        ? 'Radio de 2 km'
                        : 'A ${formatDistance(g.distanceMeters)} del campus',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Tarjetas horizontales con lugares libres por piso.
class _OccupancyStrip extends StatelessWidget {
  const _OccupancyStrip();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    return SizedBox(
      height: 132,
      child: FutureBuilder<List<FloorOccupancy>>(
        future: c.occupancyFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return Pad(Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final floors = snap.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: floors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final f = floors[i];
              final ratio = f.total == 0 ? 0.0 : f.free / f.total;
              final color = ratio > 0.4
                  ? AppColors.free
                  : ratio > 0.15
                      ? AppColors.reserved
                      : AppColors.occupied;
              return SizedBox(
                width: 150,
                child: SoftCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => context
                      .read<ShellController>()
                      .go(Tabs.spots, floor: f.floor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Piso ${f.floor}', style: AppText.slab(size: 15)),
                      const Spacer(),
                      Text('${f.free}',
                          style: AppText.slab(size: 28, color: color)),
                      Text('libres de ${f.total}',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          color: color,
                          backgroundColor: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
