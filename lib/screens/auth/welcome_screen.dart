// lib/screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/pin_service.dart'; // ← en haut du fichier
import '../../widgets/pwa_install_dialog.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _apiService = ApiService();
  final _pinService = PinService();

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
    // Léger délai : laisse le temps à _checkAlreadyLoggedIn() de rediriger
    // si l'utilisateur est déjà connecté, pour ne pas faire clignoter le
    // rappel d'installation juste avant une navigation immédiate. No-op sur
    // Android/iOS natif et si rien à proposer (voir PwaInstallService).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) maybeShowPwaInstallReminder(context);
      });
    });
  }

  Future<void> _checkAlreadyLoggedIn() async {
    final loggedIn = await _apiService.isLoggedIn();
    if (!loggedIn || !mounted) return;
    final userType = await _apiService.getUserType() ?? 'tenant';
    final pinSet = await _pinService.isPinSetLocally();
    if (!mounted) return;
    if (pinSet) {
      context.go('/pin-login/$userType');
    } else {
      try {
        final hasPin = await _pinService.isPinSet(userType);
        if (!mounted) return;
        context.go(hasPin ? '/pin-login/$userType' : '/set-pin/$userType');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.savings_rounded,
                              size: 54,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Nom
                      const Text(
                        'MaTontine',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // ── Sous-titre
                      Text(
                        'Gérez vos tontines en toute simplicité',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),

                      // ── Espace fixe réduit
                      const SizedBox(height: 40),

                      // ── Bouton créer compte gérant
                      ElevatedButton(
                        onPressed: () => context.go('/auth/tenant/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Créer un compte gérant'),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // ── Bouton connexion gérant
                      OutlinedButton(
                        onPressed: () => context.go('/auth/tenant/login'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          side:
                              const BorderSide(color: Colors.white, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Se connecter'),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Séparateur
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Vous êtes membre ?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Bouton rejoindre groupe
                      ElevatedButton(
                        onPressed: () => context.go('/auth/member/join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Rejoindre un groupe'),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // ── Déjà membre
                      TextButton(
                        onPressed: () => context.go('/auth/member/login'),
                        child: Text(
                          'Déjà membre ? Se connecter',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
