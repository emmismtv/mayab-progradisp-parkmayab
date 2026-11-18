import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_paths.dart';
import '../../core/theme.dart';
import '../../domain/entities/reservation.dart';
import '../controllers/parking_controller.dart';
import '../controllers/shell_controller.dart';
import '../routes.dart';

// ---------------------------------------------------------------------------
// Navegación
// ---------------------------------------------------------------------------

/// Regresa a la pantalla principal y cambia de pestaña.
void goToTab(BuildContext context, int tab, {int? floor}) {
  final shell = context.read<ShellController>();
  Navigator.of(context).popUntil((r) => r.isFirst);
  shell.go(tab, floor: floor);
}

/// AppBar institucional: marca + título + avatar del alumno.
/// `dark` usa el estilo negro de las pantallas de detalle.
PreferredSizeWidget brandAppBar(
  BuildContext context, {
  required String title,
  bool dark = false,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    backgroundColor: dark ? AppColors.black : AppColors.orange,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(width: 10),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    ),
    actions: [
      ...?actions,
      Padding(
        padding: const EdgeInsets.only(right: 14, left: 4),
        child: GestureDetector(
          onTap: () => goToTab(context, Tabs.profile),
          child: const ProfileAvatar(radius: 18, bordered: true),
        ),
      ),
    ],
    bottom: bottom,
  );
}

/// Marca de la app ("P" de ParkMayab con contorno, estilo institucional).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 30, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text('P',
          style: AppText.slab(
              size: size * 0.58, color: color, weight: FontWeight.w800)),
    );
  }
}

/// Drawer principal para navegar entre secciones.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ParkingController>().profile;
    final current = context.watch<ShellController>().index;

    Widget tab(IconData icon, String label, int index) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          selected: current == index,
          selectedColor: AppColors.orange,
          selectedTileColor: AppColors.orange.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            Navigator.pop(context);
            goToTab(context, index);
          },
        );

    Widget route(IconData icon, String label, String name) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, name);
          },
        );

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.orangeGradient),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileAvatar(radius: 32, bordered: true),
                const SizedBox(height: 12),
                Text(profile.name,
                    style: AppText.slab(size: 18, color: Colors.white)),
                Text(profile.email,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                tab(Icons.home_outlined, 'Inicio', Tabs.home),
                tab(Icons.local_parking, 'Lugares', Tabs.spots),
                tab(Icons.confirmation_number_outlined, 'Mi pase', Tabs.pass),
                tab(Icons.history, 'Historial', Tabs.history),
                tab(Icons.person_outline, 'Perfil', Tabs.profile),
                const Divider(height: 24),
                route(Icons.qr_code_scanner, 'Escanear QR de la pluma',
                    AppRoutes.scanner),
                route(Icons.settings_outlined, 'Ajustes', AppRoutes.settings),
              ],
            ),
          ),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Universidad Anáhuac Mayab',
                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes visuales
// ---------------------------------------------------------------------------

/// Etiqueta naranja pegada al borde izquierdo ("Próximos eventos").
class SectionTag extends StatelessWidget {
  const SectionTag(this.text, {super.key, this.top = 24});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: top, bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
        decoration: const BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(10)),
        ),
        child: Text(text,
            style: AppText.slab(
                size: 13, color: Colors.white, weight: FontWeight.w600)),
      ),
    );
  }
}

/// Relleno horizontal estándar de las pantallas.
class Pad extends StatelessWidget {
  const Pad(this.child, {super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), child: child);
}

/// Chip gris con ícono (fecha, piso, ala…).
class InfoChip extends StatelessWidget {
  const InfoChip(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.ink),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Tarjeta blanca con sombra suave.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Mosaico del menú "Descubre".
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.ink),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Avatar del alumno (foto o iniciales).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.radius = 20, this.bordered = false});
  final double radius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParkingController>().profile;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.tan,
      foregroundImage:
          p.photoFile == null ? null : FileImage(AppPaths.photo(p.photoFile!)),
      child: Text(p.initials,
          style: AppText.slab(size: radius * 0.75, color: AppColors.ink)),
    );
    if (!bordered) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: avatar,
    );
  }
}

/// Imagen de una reserva. El `Hero` comparte la imagen entre la lista y el
/// detalle para una transición fluida.
class ReservationImage extends StatelessWidget {
  const ReservationImage({
    super.key,
    required this.reservation,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final Reservation reservation;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final file = reservation.photoFile;
    final placeholder = Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(gradient: AppColors.orangeGradient),
      child: Stack(children: [
        Positioned(
          right: -20,
          bottom: -30,
          child: Icon(Icons.local_parking,
              size: (height ?? 80) * 0.9,
              color: Colors.white.withValues(alpha: 0.15)),
        ),
        Center(
          child: Icon(Icons.directions_car_filled,
              color: Colors.white, size: (height ?? 80) * 0.35),
        ),
      ]),
    );
    final Widget image = file == null
        ? placeholder
        : Image.file(
            AppPaths.photo(file),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          );
    return Hero(
      tag: 'reservation-photo-${reservation.id}',
      child: ClipRRect(borderRadius: borderRadius, child: image),
    );
  }
}

(String, Color) statusStyle(ReservationStatus status) => switch (status) {
      ReservationStatus.active => ('Apartado', AppColors.reserved),
      ReservationStatus.used => ('Estacionado', AppColors.free),
      ReservationStatus.completed => ('Finalizado', AppColors.grey),
      ReservationStatus.expired => ('Expirado', AppColors.occupied),
      ReservationStatus.cancelled => ('Cancelado', AppColors.grey),
    };

/// Estado con contorno, estilo "SIN COSTO".
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.status, {super.key, this.filled = false});
  final ReservationStatus status;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800)),
    );
  }
}

/// Pase digital naranja con el cajón asignado.
class ReservationPassCard extends StatelessWidget {
  const ReservationPassCard({super.key, required this.reservation, this.footer});
  final Reservation reservation;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final active = r.status == ReservationStatus.active;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.orangeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          right: -24,
          top: -24,
          child: Icon(Icons.local_parking,
              size: 150, color: Colors.white.withValues(alpha: 0.12)),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('TU CAJÓN',
                    style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusStyle(r.status).$1,
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ]),
              Text(r.slotCode,
                  style: AppText.slab(
                      size: 48, color: Colors.white, weight: FontWeight.w800)),
              Row(children: [
                _passInfo(Icons.layers_outlined, 'Piso ${r.floor}'),
                const SizedBox(width: 16),
                _passInfo(Icons.signpost_outlined, 'Ala ${r.wing}'),
                const Spacer(),
                if (active) ...[
                  const Icon(Icons.timer_outlined,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  CountdownText(
                      until: r.expiresAt,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ]),
              if (footer != null) ...[const SizedBox(height: 16), footer!],
            ],
          ),
        ),
      ]),
    );
  }

  Widget _passInfo(IconData icon, String text) => Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ]);
}

/// Botón "Desliza para…" como en la app institucional.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.color = AppColors.free,
  });
  final String label;
  final Future<void> Function() onConfirm;
  final Color color;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  static const _height = 60.0;
  static const _knob = 52.0;
  double _dx = 0;
  bool _dragging = false;
  bool _busy = false;

  Future<void> _end(double max) async {
    _dragging = false;
    if (_dx < max * 0.85) {
      setState(() => _dx = 0);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _dx = max;
      _busy = true;
    });
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _dx = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final max = c.maxWidth - _knob - 8;
      final progress = max <= 0 ? 0.0 : (_dx / max).clamp(0.0, 1.0);
      return Container(
        height: _height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(_height / 2),
        ),
        child: Stack(children: [
          Center(
            child: Opacity(
              opacity: 1 - progress * 0.8,
              child: Text(_busy ? 'Procesando…' : widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          AnimatedPositioned(
            duration:
                _dragging ? Duration.zero : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: 4 + _dx,
            top: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: _busy
                  ? null
                  : (d) => setState(() {
                        _dragging = true;
                        _dx = (_dx + d.delta.dx).clamp(0, max);
                      }),
              onHorizontalDragEnd: _busy ? null : (_) => _end(max),
              child: Container(
                width: _knob,
                height: _knob,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: _busy
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: widget.color))
                    : Icon(Icons.chevron_right_rounded,
                        color: widget.color, size: 32),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

/// Estado vacío con ícono, texto y acción.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.orange),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppText.slab(size: 20), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 15)),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ]),
      ),
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

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.occupied : AppColors.ink,
    ));
}

/// Diálogo de confirmación con apariencia nativa (Cupertino en iOS).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  Widget action(String label, bool value, {bool danger = false}) => isIOS
      ? CupertinoDialogAction(
          isDestructiveAction: danger,
          isDefaultAction: !value,
          onPressed: () => Navigator.pop(context, value),
          child: Text(label),
        )
      : TextButton(
          onPressed: () => Navigator.pop(context, value),
          child: Text(label,
              style: TextStyle(color: danger ? AppColors.occupied : null)),
        );

  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (_) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        action('Volver', false),
        action(confirmLabel, true, danger: destructive),
      ],
    ),
  );
  return result ?? false;
}
