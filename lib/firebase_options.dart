// lib/firebase_options.dart
//
// ⚠️ FICHIER TEMPORAIRE — à REMPLACER intégralement par celui généré par
// `flutterfire configure` (voir instructions ci-dessous). En attendant :
//   - ANDROID : valeurs RÉELLES, extraites de android/app/google-services.json
//     (même projet Firebase que celui déjà utilisé) — fonctionnel dès maintenant.
//   - iOS et WEB : placeholders — Firebase.initializeApp() échouera pour ces
//     deux plateformes tant qu'ils ne sont pas remplacés (rattrapé par le
//     try/catch de main.dart, donc pas de crash : juste pas de notifications
//     push ni Crashlytics sur iOS/Web tant que non configuré).
//
// COMMENT GÉNÉRER LE VRAI FICHIER (à faire une seule fois, chez toi) :
//   1. dart pub global activate flutterfire_cli
//   2. firebase login   (si pas déjà fait — nécessite Firebase CLI installée :
//      npm install -g firebase-tools)
//   3. Depuis la racine du projet Flutter :
//      flutterfire configure --project=tontineapp-b4bab
//      → sélectionne android, ios, web quand demandé
//   4. Ça régénère CE fichier automatiquement avec les vraies valeurs pour
//      les 3 plateformes. Aucune autre modification de code nécessaire —
//      main.dart pointe déjà dessus.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne sont pas configurées pour cette plateforme (${defaultTargetPlatform.name}). '
          'Lance `flutterfire configure` pour l\'ajouter si besoin.',
        );
    }
  }

  /// ANDROID — valeurs réelles, extraites de android/app/google-services.json
  /// (projet Firebase "tontineapp-b4bab"). Équivalent à l'ancien
  /// `Firebase.initializeApp()` sans argument sur Android, donc AUCUNE
  /// régression : juste rendu explicite pour pouvoir cohabiter avec iOS/Web.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdulp3OuYeg6z-CdmkxFMrC-brCliJPHQ',
    appId: '1:405783205772:android:33210566e03d71d0c8e8a9',
    messagingSenderId: '405783205772',
    projectId: 'tontineapp-b4bab',
    storageBucket: 'tontineapp-b4bab.firebasestorage.app',
  );

  /// ⚠️ PLACEHOLDER — iOS n'a pas encore d'app enregistrée dans la console
  /// Firebase (GoogleService-Info.plist absent du projet). Remplacer via
  /// `flutterfire configure` (voir en-tête de fichier) une fois fait.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACER_VIA_FLUTTERFIRE_CONFIGURE',
    appId: 'REMPLACER_VIA_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: '405783205772',
    projectId: 'tontineapp-b4bab',
    storageBucket: 'tontineapp-b4bab.firebasestorage.app',
    iosBundleId: 'com.tontineapp.tontineapp',
  );

  /// ⚠️ PLACEHOLDER — idem pour le web. Remplacer via `flutterfire configure`.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REMPLACER_VIA_FLUTTERFIRE_CONFIGURE',
    appId: 'REMPLACER_VIA_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: '405783205772',
    projectId: 'tontineapp-b4bab',
    authDomain: 'tontineapp-b4bab.firebaseapp.com',
    storageBucket: 'tontineapp-b4bab.firebasestorage.app',
  );
}
