// lib/screens/legal/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text("Conditions d'utilisation"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "MaTontine est un outil de suivi. L'application ne détient, "
                      "ne reçoit et ne transfère jamais l'argent des cotisations.",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _section(
              '1. Ce que fait MaTontine',
              "MaTontine permet de créer des groupes de tontine, d'inviter des membres, "
              "de suivre l'ordre de rotation et de déclarer qui a payé sa cotisation ou "
              "reçu sa mise. C'est un carnet de suivi numérique, pas un service financier.",
            ),
            _section(
              "2. Ce que MaTontine ne fait pas",
              "MaTontine ne reçoit, ne détient et ne transfère jamais d'argent. "
              "Tous les paiements (espèces, Mobile Money, etc.) se font directement "
              "entre les membres, en dehors de l'application.",
            ),
            _section(
              '3. Votre responsabilité',
              "Vous êtes seul responsable du choix des personnes avec qui vous créez "
              "ou rejoignez une tontine, et de la remise ou réception effective de "
              "l'argent. MaTontine ne peut pas vérifier que les déclarations faites "
              "dans l'app (« reçu », « payé ») correspondent à une remise d'argent réelle.",
            ),
            _section(
              'Notre recommandation',
              "Ne créez ou ne rejoignez une tontine qu'avec des personnes que vous "
              "connaissez et en qui vous avez confiance. Une tontine repose sur la "
              "confiance entre ses membres, quel que soit l'outil utilisé pour la suivre.",
            ),
            _section(
              '4. En cas de litige',
              "MaTontine ne tranche pas les litiges entre membres. L'application "
              "conserve un journal horodaté des actions (qui a marqué quoi et quand), "
              "consultable par le gérant, qui peut servir de preuve en cas de désaccord.",
            ),
            _section(
              '5. Votre compte',
              "Votre compte est protégé par un code PIN à 4 chiffres. Vous êtes "
              "responsable de garder ce code confidentiel et de sécuriser votre téléphone.",
            ),
            _section(
              '6. Modifications',
              "Ces conditions peuvent évoluer. En cas de changement important, "
              "vous en serez informé dans l'application.",
            ),

            const SizedBox(height: AppSpacing.lg),
            Text(
              'Dernière mise à jour : ${DateTime.now().year}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(body, style: AppTextStyles.body),
          ],
        ),
      );
}