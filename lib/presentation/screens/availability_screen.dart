import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../domain/entities/parking_slot.dart';
import '../controllers/parking_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Cuadrícula de cajones por piso (verde libre, rojo ocupado, amarillo apartado).
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late Map<int, Future<List<ParkingSlot>>> _futures;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final c = context.read<ParkingController>();
    _futures = {
      for (var f = 1; f <= AppConstants.floors; f++) f: c.slotsOfFloor(f),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    return DefaultTabController(
      length: AppConstants.floors,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Disponibilidad'),
          bottom: TabBar(
            indicatorColor: AppColors.orange,
            labelColor: AppColors.ink,
            unselectedLabelColor: Colors.black54,
            tabs: [
              for (var f = 1; f <= AppConstants.floors; f++) Tab(text: 'Piso $f'),
            ],
          ),
        ),
        drawer: const AppDrawer(current: AppRoutes.availability),
        body: Column(
          children: [
            const _Legend(),
            if (c.current != null)
              Container(
                width: double.infinity,
                color: AppColors.reserved.withValues(alpha: 0.25),
                padding: const EdgeInsets.all(10),
                child: Text(
                    'Ya tienes el cajón ${c.current!.slotCode}. Termina esa visita para apartar otro.',
                    textAlign: TextAlign.center),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  for (var f = 1; f <= AppConstants.floors; f++)
                    _FloorGrid(
                      future: _futures[f]!,
                      enabled: c.current == null,
                      onReturn: () => setState(_load),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color, String label) => Row(children: [
          Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label),
        ]);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          dot(AppColors.free, 'Libre'),
          dot(AppColors.occupied, 'Ocupado'),
          dot(AppColors.reserved, 'Apartado'),
        ],
      ),
    );
  }
}

class _FloorGrid extends StatelessWidget {
  const _FloorGrid({
    required this.future,
    required this.enabled,
    required this.onReturn,
  });
  final Future<List<ParkingSlot>> future;
  final bool enabled;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ParkingSlot>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final slots = snap.data!;
        final free = slots.where((s) => s.status == SlotStatus.free).length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('$free de ${slots.length} lugares libres',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final wing in AppConstants.wings) ...[
              Text('Ala $wing',
                  style: const TextStyle(color: AppColors.ink, fontSize: 16)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final s in slots.where((s) => s.wing == wing))
                    _SlotTile(
                        slot: s, enabled: enabled, onReturn: onReturn),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.enabled,
    required this.onReturn,
  });
  final ParkingSlot slot;
  final bool enabled;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final color = switch (slot.status) {
      SlotStatus.free => AppColors.free,
      SlotStatus.occupied => AppColors.occupied,
      SlotStatus.reserved => AppColors.reserved,
    };
    final tappable = enabled && slot.status == SlotStatus.free;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: tappable
            ? () async {
                await Navigator.pushNamed(context, AppRoutes.reserve,
                    arguments: slot);
                onReturn();
              }
            : null,
        child: Center(
          child: Text(slot.code,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
