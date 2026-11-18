import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../controllers/parking_controller.dart';
import '../controllers/shell_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// "Mi pase": cajón asignado e indicaciones paso a paso para llegar.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ParkingController>().current;

    return Scaffold(
      appBar: brandAppBar(context, title: 'Mi pase'),
      drawer: const AppDrawer(),
      body: r == null
          ? EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: 'Sin pase activo',
              message:
                  'Aparta un lugar y aquí verás tu cajón y cómo llegar a él.',
              action: FilledButton(
                onPressed: () =>
                    context.read<ShellController>().go(Tabs.spots),
                child: const Text('Apartar lugar'),
              ),
            )
          : _GuideBody(reservation: r),
    );
  }
}

class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.reservation});
  final Reservation reservation;

  List<(IconData, String, String)> _steps(Reservation r) {
    final parked = r.status == ReservationStatus.used;
    final number = int.parse(r.slotCode.split('-').last);
    return [
      (
        Icons.qr_code_scanner,
        parked ? 'Entrada registrada' : 'Escanea la pluma',
        parked
            ? 'La pluma de la Entrada 1 se abrió con tu pase.'
            : 'Al llegar, escanea el código QR de la pluma de la Entrada 1.'
      ),
      (
        Icons.stairs_outlined,
        r.floor == 1 ? 'Planta baja' : 'Sube al piso ${r.floor}',
        r.floor == 1
            ? 'Avanza por el carril principal del piso 1.'
            : 'Toma la rampa de la derecha hasta el piso ${r.floor}.'
      ),
      (
        r.wing == 'A' ? Icons.turn_left : Icons.turn_right,
        'Ala ${r.wing}',
        'Gira a la ${r.wing == 'A' ? 'izquierda' : 'derecha'} hacia el pasillo del ala ${r.wing}.'
      ),
      (
        Icons.local_parking,
        'Cajón ${r.slotCode}',
        number <= AppConstants.slotsPerWing ~/ 2
            ? 'Tu cajón está al inicio del pasillo.'
            : 'Tu cajón está al fondo del pasillo.'
      ),
    ];
  }

  Future<void> _close(BuildContext context) async {
    final active = reservation.status == ReservationStatus.active;
    final ok = await confirmDialog(
      context,
      title: active ? '¿Cancelar reserva?' : '¿Salir del estacionamiento?',
      message: active
          ? 'El cajón ${reservation.slotCode} quedará libre para alguien más.'
          : 'Se registrará tu salida y el cajón quedará libre.',
      confirmLabel: active ? 'Cancelar reserva' : 'Salir',
      destructive: active,
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<ParkingController>().closeCurrent(reservation);
      HapticFeedback.mediumImpact();
      if (!context.mounted) return;
      context.read<ShellController>().go(Tabs.home);
      showSnack(context,
          active ? 'Reserva cancelada.' : '¡Buen viaje! Visita finalizada.');
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final active = r.status == ReservationStatus.active;
    final steps = _steps(r);
    // El primer paso ya está hecho si el alumno pasó la pluma.
    final doneUntil = active ? -1 : 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 16),
        Pad(ReservationPassCard(reservation: r)),
        const SectionTag('Cómo llegar'),
        for (var i = 0; i < steps.length; i++)
          Pad(_TimelineStep(
            icon: steps[i].$1,
            title: steps[i].$2,
            text: steps[i].$3,
            done: i <= doneUntil,
            isLast: i == steps.length - 1,
          )),
        const SizedBox(height: 16),
        if (active)
          Pad(FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.scanner),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR de la pluma'),
          )),
        const SizedBox(height: 10),
        Pad(OutlinedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.detail, arguments: r),
          icon: const Icon(Icons.info_outline),
          label: const Text('Ver detalle y mapa'),
        )),
        const SizedBox(height: 6),
        Pad(TextButton.icon(
          style: TextButton.styleFrom(
              foregroundColor: AppColors.occupied,
              minimumSize: const Size.fromHeight(48)),
          onPressed: () => _close(context),
          icon: Icon(active ? Icons.close : Icons.logout),
          label: Text(active ? 'Cancelar reserva' : 'Salir del estacionamiento'),
        )),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.text,
    required this.done,
    required this.isLast,
  });
  final IconData icon;
  final String title;
  final String text;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.free : AppColors.orange;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(done ? Icons.check : icon,
                  color: Colors.white, size: 20),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.line),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.slab(size: 16)),
                  const SizedBox(height: 2),
                  Text(text, style: const TextStyle(color: AppColors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
