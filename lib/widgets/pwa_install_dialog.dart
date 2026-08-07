// lib/widgets/pwa_install_dialog.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/pwa_install_service.dart';

/// À appeler une fois depuis initState() (via postFrameCallback) des écrans
/// d'atterrissage principaux (accueil gérant, accueil membre, écran de
/// bienvenue). No-op silencieux sur Android/iOS natif (PwaInstallService
/// stub) et sur web si déjà installé / déjà refusé / rien à proposer.
void maybeShowPwaInstallReminder(BuildContext context) {
  final service = PwaInstallService.instance;
  if (!service.shouldShowInstallReminder) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _PwaInstallDialog(),
  );
}

class _PwaInstallDialog extends StatelessWidget {
  const _PwaInstallDialog();

  @override
  Widget build(BuildContext context) {
    final service = PwaInstallService.instance;
    final isIOS = service.isIOS;

    return AlertDialog(
      icon: const Icon(Icons.add_to_home_screen, color: AppColors.primary, size: 36),
      title: const Text('Installer MaTontine'),
      content: isIOS
          ? const _IOSInstructions()
          : const Text(
              "Installe MaTontine sur ton téléphone pour y accéder directement "
              "depuis ton écran d'accueil, comme une vraie application.",
            ),
      actions: [
        TextButton(
          onPressed: () {
            service.markReminderDismissed();
            Navigator.of(context).pop();
          },
          child: const Text('Plus tard'),
        ),
        if (isIOS)
          FilledButton(
            onPressed: () {
              service.markReminderDismissed();
              Navigator.of(context).pop();
            },
            child: const Text("J'ai compris"),
          )
        else
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await service.promptInstall();
              // Que l'utilisateur accepte ou refuse le prompt natif, on ne
              // le réaffiche plus ensuite — sinon on le harcèle à chaque
              // visite s'il a dit non une fois.
              service.markReminderDismissed();
            },
            child: const Text('Installer'),
          ),
      ],
    );
  }
}

class _IOSInstructions extends StatelessWidget {
  const _IOSInstructions();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sur iPhone, l'installation se fait en 2 étapes depuis Safari :"),
        const SizedBox(height: 12),
        _Step(icon: Icons.ios_share, text: 'Appuie sur le bouton Partager'),
        const SizedBox(height: 8),
        _Step(icon: Icons.add_box_outlined, text: "Choisis « Sur l'écran d'accueil »"),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Step({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }
}
