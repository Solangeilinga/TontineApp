// lib/services/pwa_install_service_web.dart
//
// ⚠️ Ce fichier n'est JAMAIS compilé pour Android/iOS natif — sélectionné
// uniquement en compilation web par l'import conditionnel dans
// pwa_install_service.dart (`if (dart.library.html)`).
//
// Utilise package:web + dart:js_interop — l'API moderne recommandée depuis
// que dart:html/dart:js_util sont dépréciés. Nécessaire ici, pas juste
// "recommandé" : dart:js_util a cessé d'être résolu du tout sur les SDK
// Dart récents (confirmé par une erreur de compilation réelle en CI), donc
// l'ancienne API n'est plus une option, juste une préférence de style.
//
// Deux mécanismes bien distincts :
//   - Chrome/Edge/Android : événement navigateur `beforeinstallprompt`,
//     qu'on intercepte pour proposer NOTRE bouton "Installer" plutôt que le
//     mini-bandeau par défaut du navigateur.
//   - iOS Safari : AUCUNE API de ce type n'existe côté Apple — impossible de
//     déclencher l'installation par code. On ne peut qu'afficher des
//     instructions ("Appuie sur Partager puis Sur l'écran d'accueil").
import 'dart:js_interop';
import 'package:web/web.dart' as web;

// ── Interop typé pour les objets non-standards (absents de package:web
// car ce sont des extensions propriétaires Chrome ou iOS Safari, pas des
// APIs DOM standard) ──────────────────────────────────────────────────────

/// L'événement `beforeinstallprompt` — pas dans le DOM standard, donc pas
/// dans package:web. `prompt()` affiche le mini-bandeau natif ; `userChoice`
/// est une Promise résolue une fois l'utilisateur accepté/refusé.
extension type _BeforeInstallPromptEvent(JSObject _) implements JSObject {
  external void prompt();
  external JSPromise<_UserChoice> get userChoice;
}

extension type _UserChoice(JSObject _) implements JSObject {
  external String get outcome;
}

/// `navigator.standalone` — propriété non-standard exposée uniquement par
/// iOS Safari quand l'app tourne depuis l'écran d'accueil.
extension type _IOSNavigator(JSObject _) implements JSObject {
  external bool? get standalone;
}

class PwaInstallService {
  static final PwaInstallService instance = PwaInstallService._();

  static const _dismissedKey = 'matontine_pwa_install_dismissed';

  _BeforeInstallPromptEvent? _deferredPrompt;

  PwaInstallService._() {
    // Capturé tôt (voir main.dart, qui force l'initialisation de ce
    // singleton dès le démarrage) pour maximiser les chances que
    // `beforeinstallprompt` soit déjà intercepté au moment où un écran
    // voudrait afficher le rappel.
    web.window.addEventListener(
      'beforeinstallprompt',
      (web.Event event) {
        // Empêche le mini-bandeau natif de Chrome — on affiche notre propre
        // modal à la place, déclenché quand ET où on le décide.
        event.preventDefault();
        _deferredPrompt = event as _BeforeInstallPromptEvent;
      }.toJS,
    );
  }

  bool get isRunningAsWebApp => true;

  bool get isIOS {
    final ua = web.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
  }

  /// true si l'app tourne déjà en mode "installé" (lancée depuis l'écran
  /// d'accueil), qu'importe la plateforme — dans ce cas, ne jamais réafficher
  /// le rappel.
  bool get isAlreadyInstalled {
    final standaloneMedia =
        web.window.matchMedia('(display-mode: standalone)').matches;
    final iosNav = web.window.navigator as _IOSNavigator;
    final iosStandalone = iosNav.standalone == true;
    return standaloneMedia || iosStandalone;
  }

  /// true uniquement si Chrome/Android a effectivement proposé l'événement
  /// d'installation (rien à déclencher sinon).
  bool get canShowNativeInstallPrompt => _deferredPrompt != null;

  bool get _wasDismissed =>
      web.window.localStorage.getItem(_dismissedKey) == 'true';

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

    prompt.prompt();
    final choice = await prompt.userChoice.toDart;
    _deferredPrompt = null;

    return choice.outcome == 'accepted';
  }

  /// L'utilisateur a fermé le rappel ("Plus tard" / "Compris") — ne plus le
  /// réafficher sur ce navigateur. Stocké en localStorage (propre à ce
  /// navigateur/appareil, pas synchronisé avec le compte).
  void markReminderDismissed() {
    web.window.localStorage.setItem(_dismissedKey, 'true');
  }
}
