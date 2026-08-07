// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/push_service.dart';
import 'services/pwa_install_service.dart';

Future<void> main() async {
  // runZonedGuarded capture aussi les erreurs asynchrones non catchées
  // (en dehors du build Flutter) — sans ça, elles disparaissent
  // silencieusement et Crashlytics ne les voit jamais.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Force l'initialisation IMMÉDIATE du service d'installation PWA — sa
    // classe attache l'écouteur `beforeinstallprompt` dans son constructeur,
    // qui ne s'exécute qu'au premier accès à `.instance` (static final =
    // paresseux). Avant ce correctif, ce premier accès n'avait lieu que 2
    // secondes après l'affichage de l'écran (voir welcome_screen.dart) —
    // largement trop tard : Chrome émet cet événement bien avant, et un
    // navigateur ne le rejoue jamais à un écouteur attaché en retard.
    // Résultat concret observé : le bouton d'installation n'apparaissait
    // jamais, alors que Chrome DevTools confirmait le site "Installable".
    // No-op immédiat et inoffensif sur Android/iOS natif (implémentation
    // stub, voir pwa_install_service_stub.dart).
    PwaInstallService.instance;

    // URLs web propres (matontine.netlify.app/gerant/home au lieu de
    // .../#/gerant/home). Sans effet sur mobile (no-op sur Android/iOS).
    // Nécessite la redirection SPA côté Netlify (voir netlify.toml) — sinon
    // un rafraîchissement de page sur une route profonde renverrait un 404.
    usePathUrlStrategy();

    // Locale
    await initializeDateFormatting('fr_FR', null);

    // Initialiser l'API service
    ApiService().init();

    // Firebase + Push notifications + Crashlytics
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await PushService().init();

      // Crashlytics ne supporte PAS le web du tout (aucune implémentation
      // native pour ce plugin) — l'appeler quand même y lève une
      // MissingPluginException à chaque chargement (rattrapée par le
      // catch ci-dessous, mais bruyante et inutile). On ne câble donc
      // Crashlytics que sur Android/iOS, où il fonctionne réellement.
      if (!kIsWeb) {
        // Auparavant : aucun crash reporting configuré (firebase_crashlytics
        // n'était même pas une dépendance) — un crash en production n'était
        // visible nulle part. Ces deux lignes redirigent toutes les erreurs
        // Flutter (build/layout/paint) vers Crashlytics.
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        // Erreurs Dart non gérées en dehors du framework Flutter (isolate
        // racine) — captées par la zone englobante ci-dessous.
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        // En debug, Crashlytics n'est utile à personne et complique le
        // développement local (pas de vraies clés Firebase requises non
        // plus) — désactivé explicitement hors release.
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(kReleaseMode);
      }
    } catch (e) {
      debugPrint('⚠️ Firebase non disponible: $e');
      // L'app continue sans notifications push ni Crashlytics
    }

    // ProviderScope : racine de l'arbre de providers Riverpod. Doit
    // envelopper TOUTE l'app pour que n'importe quel écran puisse lire un
    // provider avec `ref.watch(...)` (ConsumerWidget/ConsumerStatefulWidget)
    // ou y accéder ponctuellement via `ProviderScope.containerOf(context)`.
    runApp(const ProviderScope(child: TontineApp()));
  }, (error, stack) {
    // Même précaution que plus haut : Crashlytics n'existe pas sur web.
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('❌ Erreur non gérée (web, non remontée à Crashlytics): $error');
    }
  });
}

class TontineApp extends StatelessWidget {
  const TontineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaTontine',
      theme: AppTheme.theme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}