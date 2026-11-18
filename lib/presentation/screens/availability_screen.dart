import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../domain/entities/parking_slot.dart';
import '../controllers/parking_controller.dart';
import '../controllers/shell_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Plano del piso: alas A y B a los lados del carril central.
class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingController>();
    final shell = context.watch<ShellController>();

    return Scaffold(
      appBar: brandAppBar(context, title: 'Lugares'),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: shell.floor,
                thumbColor: AppColors.orange,
                backgroundColor: AppColors.surface,
                onValueChanged: (v) {
                  if (v == null) return;
                  HapticFeedback.selectionClick();
                  shell.selectFloor(v);
                },
                children: {
                  for (var f = 1; f <= AppConstants.floors; f++)
                    f: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Piso $f',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: shell.floor == f
                                  ? Colors.white
                                  : AppColors.ink)),
                    ),
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LegendDot(AppColors.free, 'Libre'),
                _LegendDot(AppColors.occupied, 'Ocupado'),
                _LegendDot(AppColors.reserved, 'Apartado'),
              ],
            ),
          ),
          if (c.current != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.reserved.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppColors.reserved),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Ya tienes el cajón ${c.current!.slotCode}. Termina esa visita para apartar otro.'),
                ),
              ]),
            ),
          Expanded(
            child: FutureBuilder<List<ParkingSlot>>(
              future: c.slotsOfFloor(shell.floor),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }
                return RefreshIndicator.adaptive(
                  onRefresh: c.refreshReservation,
                  child: _FloorPlan(
                    slots: snap.data!,
                    enabled: c.current == null && c.canReserve,
                    canReserve: c.canReserve,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ]);
}

class _FloorPlan extends StatelessWidget {
  const _FloorPlan({
    required this.slots,
    required this.enabled,
    required this.canReserve,
  });
  final List<ParkingSlot> slots;
  final bool enabled;
  final bool canReserve;

  @override
  Widget build(BuildContext context) {
    final free = slots.where((s) => s.status == SlotStatus.free).length;
    final wings = AppConstants.wings;

    Widget wing(String w) => Column(children: [
          Text('Ala $w', style: AppText.slab(size: 15)),
          const SizedBox(height: 8),
          for (final s in slots.where((s) => s.wing == w))
            _SlotTile(slot: s, enabled: enabled),
        ]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(children: [
          Text('$free', style: AppText.slab(size: 26, color: AppColors.free)),
          const SizedBox(width: 6),
          Text('de ${slots.length} lugares libres',
              style: const TextStyle(color: AppColors.grey, fontSize: 15)),
        ]),
        if (!canReserve)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Acércate a menos de 2 km del campus para apartar.',
                style: TextStyle(color: AppColors.occupied)),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: wing(wings.first)),
              const _Lane(),
              Expanded(child: wing(wings.last)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.login, color: AppColors.grey, size: 18),
          SizedBox(width: 6),
          Text('Entrada y rampa', style: TextStyle(color: AppColors.grey)),
        ]),
      ],
    );
  }
}

/// Carril central con flechas de circulación.
class _Lane extends StatelessWidget {
  const _Lane();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Column(children: [
        const SizedBox(height: 30),
        for (var i = 0; i < 10; i++)
          SizedBox(
            height: 58,
            child: Center(
              child: i.isEven
                  ? Container(width: 3, height: 26, color: AppColors.tan)
                  : const Icon(Icons.keyboard_double_arrow_up,
                      color: AppColors.tan),
            ),
          ),
      ]),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.enabled});
  final ParkingSlot slot;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final (Color color, Color bg, IconData? icon) = switch (slot.status) {
      SlotStatus.free => (AppColors.free, Colors.white, null),
      SlotStatus.occupied => (
          AppColors.occupied,
          AppColors.occupied.withValues(alpha: 0.12),
          Icons.directions_car_filled
        ),
      SlotStatus.reserved => (
          AppColors.reserved,
          AppColors.reserved.withValues(alpha: 0.15),
          Icons.bookmark
        ),
    };
    final tappable = enabled && slot.status == SlotStatus.free;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: tappable
              ? () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, AppRoutes.reserve,
                      arguments: slot);
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
              ],
              Text(slot.code,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
