// lib/widgets/privacy_policy_link.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_constants.dart';
import '../config/app_theme.dart';

/// Ouvre la politique de confidentialité (site vitrine) dans le navigateur.
/// Centralisé ici pour ne pas dupliquer la logique url_launcher dans
/// chaque écran qui a besoin du lien (inscription gérant/membre, profils).
Future<void> openPrivacyPolicy(BuildContext context) async {
  final uri = Uri.parse(AppConstants.privacyPolicyUrl);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Impossible d'ouvrir le lien.")),
    );
  }
}

/// TextSpan cliquable "politique de confidentialité", à insérer dans un
/// RichText existant (ex: à côté du lien CGU sur les écrans d'inscription).
///
/// Note : le TapGestureRecognizer n'est pas conservé/disposé explicitement
/// ici — c'est le même pattern déjà utilisé pour le lien CGU existant dans
/// ce projet (voir tenant_register_screen.dart), donc pas une régression
/// introduite ici. Une vraie correction consisterait à convertir l'écran en
/// StatefulWidget avec un recognizer stocké en champ + dispose(), pour LES
/// DEUX liens (CGU et confidentialité) — hors scope de cet ajout ponctuel.
TextSpan privacyPolicyTextSpan(BuildContext context,
    {String text = 'politique de confidentialité'}) {
  return TextSpan(
    text: text,
    style: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () => openPrivacyPolicy(context),
  );
}

/// Petit widget standalone (bouton texte) pour les écrans de profil, où il
/// n'y a pas de RichText existant à côté duquel s'accrocher.
class PrivacyPolicyLinkButton extends StatelessWidget {
  const PrivacyPolicyLinkButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => openPrivacyPolicy(context),
      icon: const Icon(Icons.privacy_tip_outlined, size: 18),
      label: const Text('Politique de confidentialité'),
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
    );
  }
}
