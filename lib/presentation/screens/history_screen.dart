import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/reservation.dart';
import '../controllers/parking_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Lista de reservas guardadas en SQLite, cargada con FutureBuilder.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      drawer: const AppDrawer(current: AppRoutes.history),
      body: FutureBuilder<List<Reservation>>(
        future: c.historyFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Aún no tienes reservas.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = items[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ReservationImage(
                      reservation: r, width: 64, height: 64),
                  title: Text('Cajón ${r.slotCode} · Piso ${r.floor}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fmt.format(r.createdAt)),
                        const SizedBox(height: 4),
                        StatusChip(r.status),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.detail,
                      arguments: r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
