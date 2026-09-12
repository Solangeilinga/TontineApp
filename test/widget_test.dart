// Smoke test — vérifie que l'app démarre sans exception.
//
// Pourquoi ne PAS vérifier le contenu affiché (splash "MaTontine",
// bienvenue, etc.) : l'écran initial dépend d'une redirection ASYNCHRONE
// dans go_router (lib/config/app_router.dart) qui lit le token via
// flutter_secure_storage — un plugin natif indisponible dans l'environnement
// `flutter test` (VM pure, sans plateforme réelle). Résultat observé :
// `find.text('MaTontine')` échoue de façon non déterministe selon que ce
// plugin lève une exception, ne répond jamais, ou répond null — ce n'est
// pas un vrai bug de l'app, juste un test mal posé pour ce contexte.
//
// Un vrai test de ce flux nécessiterait de mocker le MethodChannel de
// flutter_secure_storage (voir commentaire en bas de fichier pour la piste).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:matontine/main.dart';

void main() {
  testWidgets(
      'TontineApp démarre et construit son widget racine sans exception',
      (tester) async {
    // Enveloppé dans ProviderScope, comme dans main.dart — sans ça, tout
    // écran utilisant Riverpod (ConsumerWidget/ref.watch) lèverait une
    // erreur "No ProviderScope found" dès qu'il essaierait de se construire.
    await tester.pumpWidget(const ProviderScope(child: TontineApp()));
    await tester.pump();
    // Laisse s'écouler le délai de 2s avant la vérification d'installation
    // PWA (voir welcome_screen.dart/gerant_home_screen.dart/membre_home_screen.dart
    // → maybeShowPwaInstallReminder) — sinon flutter_test détecte un Timer
    // encore actif à la fin du test et le fait échouer ("A Timer is still
    // pending"). PwaInstallService.shouldShowInstallReminder vaut false
    // dans l'environnement de test (VM pure, pas kIsWeb), donc rien ne
    // s'affiche ici — ce pump sert uniquement à "consommer" le timer proprement.
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

// TODO (test plus poussé, optionnel) : pour vérifier le VRAI contenu de
// l'écran initial (ex: "l'utilisateur non connecté atterrit bien sur
// WelcomeScreen"), mocker flutter_secure_storage avant pumpWidget :
//
//   FlutterSecureStoragePlatform.instance = FakeSecureStoragePlatform();
//
// (implémenter FakeSecureStoragePlatform en mémoire, ou utiliser un package
// comme `flutter_secure_storage_platform_interface` + un stub de test).
