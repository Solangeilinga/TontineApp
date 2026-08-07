// lib/services/pwa_install_service_stub.dart
//
// Implémentation "vide" utilisée sur Android/iOS natif et desktop — ces
// plateformes n'ont pas de concept de "PWA installable depuis un
// navigateur", donc ce service ne fait jamais rien dessus. Choisi
// automatiquement par l'import conditionnel dans pwa_install_service.dart.

class PwaInstallService {
  static final PwaInstallService instance = PwaInstallService._();
  PwaInstallService._();

  bool get isRunningAsWebApp => false;
  bool get isIOS => false;
  bool get isAlreadyInstalled => true; // rien à proposer sur natif
  bool get canShowNativeInstallPrompt => false;
  bool get shouldShowInstallReminder => false;

  Future<bool> promptInstall() async => false;

  void markReminderDismissed() {}
}
