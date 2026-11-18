import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/services.dart';
import '../controllers/parking_controller.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Perfil del alumno: foto, tarjeta naranja con datos y accesos.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    final source = await showCupertinoModalPopup<PhotoSource>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Foto de perfil'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, PhotoSource.camera),
            child: const Text('Tomar foto'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, PhotoSource.gallery),
            child: const Text('Elegir de la galería'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final controller = context.read<ParkingController>();
    try {
      final file = await context.read<MediaService>().pickPhoto(source);
      if (file == null) return;
      await controller.saveProfile(controller.profile.copyWith(photoFile: file));
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParkingController>().profile;

    return Scaffold(
      appBar: brandAppBar(context, title: 'Perfil', dark: true),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          Center(
            child: Stack(children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x33000000), blurRadius: 20),
                  ],
                ),
                child: const ProfileAvatar(radius: 64, bordered: true),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Material(
                  color: AppColors.orange,
                  shape: const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 3)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _changePhoto(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.photo_camera,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.orangeGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 28),
                Text('ID: ${p.studentId}',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(p.email,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _MenuTile(
            icon: Icons.edit_outlined,
            label: 'Editar mis datos',
            onTap: () => _editProfile(context, p),
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Versión 1.0.0',
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, UserProfile p) async {
    final name = TextEditingController(text: p.name);
    final id = TextEditingController(text: p.studentId);
    final email = TextEditingController(text: p.email);
    final controller = context.read<ParkingController>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mis datos', style: AppText.slab(size: 20)),
            const SizedBox(height: 16),
            TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre completo')),
            const SizedBox(height: 12),
            TextField(
                controller: id,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID / Matrícula')),
            const SizedBox(height: 12),
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'Correo institucional')),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                try {
                  await controller.saveProfile(p.copyWith(
                    name: name.text.trim(),
                    studentId: id.text.trim(),
                    email: email.text.trim(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                } on AppException catch (e) {
                  if (ctx.mounted) showSnack(ctx, e.message, error: true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.orange),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
        onTap: onTap,
      ),
      const Divider(),
    ]);
  }
}
