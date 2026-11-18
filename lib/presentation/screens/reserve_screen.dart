import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_paths.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/repositories/services.dart';
import '../controllers/parking_controller.dart';
import '../controllers/shell_controller.dart';
import '../widgets/common.dart';

/// Formulario de nueva reserva: foto (cámara/galería), nota dictada por voz
/// y captura del GPS al confirmar.
class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key, required this.slot});
  final ParkingSlot slot;

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  final _noteCtrl = TextEditingController();
  String? _photoFile;
  bool _listening = false;
  String _noteBeforeDictation = '';

  late final MediaService _media;
  late final SpeechService _speech;

  @override
  void initState() {
    super.initState();
    _media = context.read<MediaService>();
    _speech = context.read<SpeechService>();
  }

  @override
  void dispose() {
    _speech.stop();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(PhotoSource source) async {
    try {
      final file = await _media.pickPhoto(source);
      if (file != null) setState(() => _photoFile = file);
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _toggleDictation() async {
    HapticFeedback.lightImpact();
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    _noteBeforeDictation = _noteCtrl.text.trim();
    try {
      setState(() => _listening = true);
      await _speech.start(
        (text) {
          final prefix =
              _noteBeforeDictation.isEmpty ? '' : '$_noteBeforeDictation ';
          _noteCtrl.text = '$prefix$text';
          _noteCtrl.selection =
              TextSelection.collapsed(offset: _noteCtrl.text.length);
        },
        onDone: () {
          if (mounted) setState(() => _listening = false);
        },
      );
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _listening = false);
        showSnack(context, e.message, error: true);
      }
    }
  }

  Future<void> _save() async {
    if (_listening) await _speech.stop();
    if (!mounted) return;
    final controller = context.read<ParkingController>();
    try {
      await controller.reserve(
        slotId: widget.slot.id,
        photoFile: _photoFile,
        note: _noteCtrl.text,
      );
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      goToTab(context, Tabs.pass);
      showSnack(context,
          '¡Listo! Cajón ${widget.slot.code} apartado por ${AppConstants.reservationMinutes} minutos.');
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Ocurrió un error inesperado.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slot;
    final g = context.watch<ParkingController>().geofence;

    return Scaffold(
      appBar: brandAppBar(context, title: 'Nueva reserva', dark: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SlotBanner(slot: s),
          const SizedBox(height: 16),
          Pad(Wrap(spacing: 8, runSpacing: 8, children: [
            InfoChip(Icons.layers_outlined, 'Piso ${s.floor}'),
            InfoChip(Icons.signpost_outlined, 'Ala ${s.wing}'),
            const InfoChip(Icons.timer_outlined,
                '${AppConstants.reservationMinutes} min para llegar'),
            const InfoChip(Icons.login, 'Entrada 1'),
          ])),
          const SectionTag('Foto de tu vehículo'),
          Pad(_PhotoPicker(
            photoFile: _photoFile,
            onCamera: () => _pick(PhotoSource.camera),
            onGallery: () => _pick(PhotoSource.gallery),
            onRemove: () => setState(() => _photoFile = null),
          )),
          const SectionTag('Nota del vehículo'),
          Pad(TextField(
            controller: _noteCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'Ej. Auto gris, placas YUC-123, junto a la columna'),
          )),
          const SizedBox(height: 12),
          Pad(_MicButton(listening: _listening, onTap: _toggleDictation)),
          const SectionTag('Ubicación'),
          Pad(Row(children: [
            const Icon(Icons.gps_fixed, color: AppColors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                g == null
                    ? 'Al confirmar registraremos tu ubicación GPS.'
                    : 'Estás a ${formatDistance(g.distanceMeters)} del campus. '
                        'Tu ubicación se guardará con la reserva.',
                style: const TextStyle(color: AppColors.grey),
              ),
            ),
          ])),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SlideToConfirm(
              label: 'Desliza para apartar', onConfirm: _save),
        ),
      ),
    );
  }
}

class _SlotBanner extends StatelessWidget {
  const _SlotBanner({required this.slot});
  final ParkingSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(gradient: AppColors.orangeGradient),
      child: Stack(children: [
        Positioned(
          right: -30,
          bottom: -40,
          child: Icon(Icons.local_parking,
              size: 220, color: Colors.white.withValues(alpha: 0.12)),
        ),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('CAJÓN SELECCIONADO',
                style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
            Text(slot.code,
                style: AppText.slab(
                    size: 60, color: Colors.white, weight: FontWeight.w800)),
            Text('Piso ${slot.floor} · Ala ${slot.wing}',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ]),
        ),
      ]),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoFile,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });
  final String? photoFile;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: photoFile == null
            ? Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.line, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 40, color: AppColors.grey),
                    SizedBox(height: 8),
                    Text('Agrega una foto (opcional)',
                        style: TextStyle(color: AppColors.grey)),
                    Text('Te ayudará a encontrar tu auto',
                        style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  ],
                ),
              )
            : Stack(children: [
                Image.file(AppPaths.photo(photoFile!),
                    height: 200, width: double.infinity, fit: BoxFit.cover),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.black54),
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Cámara'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galería'),
          ),
        ),
      ]),
    ]);
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});
  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = listening ? AppColors.occupied : AppColors.orange;
    return Row(children: [
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: listening ? 18 : 8,
                spreadRadius: listening ? 4 : 0,
              ),
            ],
          ),
          child: Icon(listening ? Icons.stop_rounded : Icons.mic_none,
              color: Colors.white, size: 28),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(listening ? 'Escuchando…' : 'Dictar nota',
                style: AppText.slab(size: 15, color: color)),
            Text(
                listening
                    ? 'Habla ahora; toca de nuevo para terminar.'
                    : 'Toca el micrófono y describe tu vehículo.',
                style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      ),
    ]);
  }
}
