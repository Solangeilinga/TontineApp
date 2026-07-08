// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'services/api_service.dart';
import 'services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale
  await initializeDateFormatting('fr_FR', null);

  // Initialiser l'API service
  ApiService().init();

  // Firebase + Push notifications
  try {
    await Firebase.initializeApp();
    await PushService().init();
  } catch (e) {
    print('⚠️ Firebase non disponible: $e');
    // L'app continue sans notifications push
  }

  runApp(const TontineApp());
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