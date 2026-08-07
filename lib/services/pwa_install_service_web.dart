// lib/services/pwa_install_service_web.dart
//
// ⚠️ Ce fichier n'est JAMAIS compilé pour Android/iOS natif — sélectionné
// uniquement en compilation web par l'import conditionnel dans
// pwa_install_service.dart (`if (dart.library.html)`). dart:html et
// dart:js_util n'existent pas en compilation native, d'où la précaution.
//
// Deux mécanismes bien distincts :
//   - Chrome/Edge/Android : événement navigateur `beforeinstallprompt`,
//     qu'on intercepte pour proposer NOTRE bouton "Installer" plutôt que le
//     mini-bandeau par défaut du navigateur.
//   - iOS Safari : AUCUNE API de ce type n'existe côté Apple — impossible de
//     déclencher l'installation par code. On ne peut qu'afficher des
//     instructions ("Appuie sur Partager puis Sur l'écran d'accueil").
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

class PwaInstallService {
  static final PwaInstallService instance = PwaInstallService._();

  static const _dismissedKey = 'matontine_pwa_install_dismissed';

  Object? _deferredPrompt;

  PwaInstallService._() {
    // Capturé tôt (voir main.dart, qui force l'initialisation de ce
    // singleton dès le démarrage) pour maximiser les chances que
    // `beforeinstallprompt` soit déjà intercepté au moment où un écran
    // voudrait afficher le rappel.
    html.window.addEventListener('beforeinstallprompt', (html.Event event) {
      // Empêche le mini-bandeau natif de Chrome — on affiche notre propre
      // modal à la place, déclenché quand ET où on le décide.
      event.preventDefault();
      _deferredPrompt = event;
    });
  }

  bool get isRunningAsWebApp => true;

  bool get isIOS {
    final ua = html.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
  }

  /// true si l'app tourne déjà en mode "installé" (lancée depuis l'écran
  /// d'accueil), qu'importe la plateforme — dans ce cas, ne jamais réafficher
  /// le rappel.
  bool get isAlreadyInstalled {
    final standaloneMedia =
        html.window.matchMedia('(display-mode: standalone)').matches;
    // Propriété non-standard spécifique à iOS Safari — absente de l'API
    // typée de dart:html, d'où l'accès dynamique via js_util.
    final iosStandalone =
        js_util.getProperty(html.window.navigator, 'standalone') == true;
    return standaloneMedia || iosStandalone;
  }

  /// true uniquement si Chrome/Android a effectivement proposé l'événement
  /// d'installation (rien à déclencher sinon).
  bool get canShowNativeInstallPrompt => _deferredPrompt != null;

  bool get _wasDismissed =>
      html.window.localStorage[_dismissedKey] == 'true';

  /// Combine toutes les conditions : pas déjà installé, pas déjà rejeté par
  /// l'utilisateur, et (sur Chrome/Android) le navigateur a bien proposé
  /// l'installation — sur iOS, les instructions manuelles restent toujours
  /// proposables (pas besoin d'attendre un événement navigateur).
  bool get shouldShowInstallReminder {
    if (isAlreadyInstalled) return false;
    if (_wasDismissed) return false;
    if (isIOS) return true;
    return canShowNativeInstallPrompt;
  }

  /// Déclenche le prompt natif du navigateur (Chrome/Android uniquement).
  /// Retourne true si l'utilisateur a accepté l'installation.
  /// Sans effet sur iOS (pas d'API équivalente) — utiliser les instructions
  /// manuelles à la place côté UI (voir shouldShowInstallReminder + isIOS).
  Future<bool> promptInstall() async {
    final prompt = _deferredPrompt;
    if (prompt == null) return false;

    js_util.callMethod(prompt, 'prompt', []);
    final choice = await js_util
        .promiseToFuture(js_util.getProperty(prompt, 'userChoice'));
    _deferredPrompt = null;

    final outcome = js_util.getProperty(choice, 'outcome');
    return outcome == 'accepted';
  }

  /// L'utilisateur a fermé le rappel ("Plus tard" / "Compris") — ne plus le
  /// réafficher sur ce navigateur. Stocké en localStorage (propre à ce
  /// navigateur/appareil, pas synchronisé avec le compte).
  void markReminderDismissed() {
    html.window.localStorage[_dismissedKey] = 'true';
  }
}
