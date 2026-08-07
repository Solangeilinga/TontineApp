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

Future<void> main() async {
  // runZonedGuarded capture aussi les erreurs asynchrones non catchées
  // (en dehors du build Flutter) — sans ça, elles disparaissent
  // silencieusement et Crashlytics ne les voit jamais.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

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
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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