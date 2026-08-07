// lib/services/pwa_install_service.dart
//
// Service de rappel d'installation PWA (Android/Chrome : prompt natif ;
// iOS Safari : instructions manuelles, aucune API d'installation
// programmatique n'existe côté Apple).
//
// ⚠️ Pattern d'import conditionnel : ce fichier n'importe JAMAIS
// directement dart:html/dart:js (qui n'existent PAS en compilation native
// Android/iOS — un import direct ferait planter la compilation mobile).
// Le bon fichier est choisi automatiquement par le compilateur selon la
// plateforme cible :
//   - Web (dart.library.html existe)   → pwa_install_service_web.dart
//   - Android/iOS/desktop (sinon)      → pwa_install_service_stub.dart (no-op)
export 'pwa_install_service_stub.dart'
    if (dart.library.html) 'pwa_install_service_web.dart';
