import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../controllers/parking_controller.dart';
import '../controllers/shell_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Historial de visitas guardadas en SQLite, cargado con FutureBuilder.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();

    return Scaffold(
      appBar: brandAppBar(context, title: 'Historial'),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Reservation>>(
        future: c.historyFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Algo salió mal',
              message: '${snap.error}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: 'Aún no tienes visitas',
              message: 'Tus reservas aparecerán aquí con su foto y ubicación.',
              action: FilledButton(
                onPressed: () =>
                    context.read<ShellController>().go(Tabs.spots),
                child: const Text('Apartar mi primer lugar'),
              ),
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: c.refreshReservation,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
              itemCount: items.length + 1,
              separatorBuilder: (_, i) =>
                  i == 0 ? const SizedBox.shrink() : const SizedBox(height: 16),
              itemBuilder: (context, i) => i == 0
                  ? const SectionTag('Mis visitas', top: 12)
                  : Pad(_VisitCard(reservation: items[i - 1])),
            ),
          );
        },
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.detail, arguments: r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ReservationImage(
              reservation: r,
              width: double.infinity,
              height: 150,
              borderRadius: BorderRadius.zero,
            ),
            Positioned(
                left: 12, top: 12, child: StatusLabel(r.status, filled: true)),
          ]),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cajón ${r.slotCode} · Piso ${r.floor}',
                    style: AppText.slab(size: 17)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  InfoChip(Icons.calendar_today_outlined,
                      DateFormat('dd MMM yyyy', 'es').format(r.createdAt)),
                  InfoChip(Icons.schedule,
                      DateFormat('HH:mm').format(r.createdAt)),
                ]),
                if (r.note != null) ...[
                  const SizedBox(height: 8),
                  Text(r.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
