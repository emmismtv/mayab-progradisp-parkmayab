import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_paths.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/repositories/services.dart';
import '../controllers/parking_controller.dart';
import '../widgets/common.dart';

/// Formulario de nueva reserva: foto (cámara/galería), nota dictada por voz
/// y captura del GPS al guardar.
class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key, required this.slot});
  final ParkingSlot slot;

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  final _noteCtrl = TextEditingController();
  String? _photoFile;
  bool _saving = false;
  bool _listening = false;
  String _noteBeforeDictation = '';

  late final MediaService _media = context.read<MediaService>();
  late final SpeechService _speech = context.read<SpeechService>();

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
          final prefix = _noteBeforeDictation.isEmpty
              ? ''
              : '$_noteBeforeDictation ';
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
    setState(() => _saving = true);
    final controller = context.read<ParkingController>();
    try {
      await controller.reserve(
        slotId: widget.slot.id,
        photoFile: _photoFile,
        note: _noteCtrl.text,
      );
      if (!mounted) return;
      Navigator.popUntil(context, (r) => r.isFirst);
      showSnack(context,
          'Cajón ${widget.slot.code} apartado. Escanea el QR de la pluma al llegar.');
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) showSnack(context, 'Ocurrió un error inesperado.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slot;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.free,
                child: Icon(Icons.local_parking, color: Colors.white),
              ),
              title: Text('Cajón ${s.code}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Piso ${s.floor} · Ala ${s.wing}\n'
                  'Tendrás 15 minutos para llegar.'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Foto de tu vehículo (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_photoFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(AppPaths.photo(_photoFile!),
                  height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(PhotoSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(PhotoSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Nota del vehículo (escribe o dicta)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ej. Auto gris, placas YUC-123',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                onPressed: _toggleDictation,
                tooltip: 'Dictar',
                icon: Icon(_listening ? Icons.stop_circle : Icons.mic,
                    color: _listening ? AppColors.occupied : AppColors.orange),
              ),
            ),
          ),
          if (_listening)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Escuchando… habla ahora',
                  style: TextStyle(color: AppColors.occupied)),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: const Text('Confirmar y capturar ubicación'),
          ),
        ],
      ),
    );
  }
}
