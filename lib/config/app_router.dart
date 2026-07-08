// lib/config/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/pin_service.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/tenant_register_screen.dart';
import '../screens/auth/tenant_login_screen.dart';
import '../screens/auth/member_join_screen.dart';
import '../screens/auth/member_login_screen.dart';
import '../screens/auth/set_pin_screen.dart';
import '../screens/auth/pin_login_screen.dart';
import '../screens/gerant/gerant_home_screen.dart';
import '../screens/gerant/create_group_screen.dart';
import '../screens/gerant/edit_group_screen.dart';
import '../screens/gerant/group_detail_screen.dart';
import '../screens/membre/membre_home_screen.dart';
import '../screens/membre/membre_group_detail_screen.dart';
import '../screens/membre/membre_notifications_screen.dart';

class AppRouter {
  static final _apiService = ApiService();
  static final _pinService = PinService();

  static final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      if (loc == '/splash') {
        final loggedIn = await _apiService.isLoggedIn();
        print('🚀 Splash — loggedIn: $loggedIn');

        if (!loggedIn) return '/welcome';

        final userType = await _apiService.getUserType() ?? 'tenant';
        print('🚀 Splash — userType: $userType');

        final pinSetLocally = await _pinService.isPinSetLocally();
        print('🚀 Splash — pinSetLocally: $pinSetLocally');

        if (pinSetLocally) return '/pin-login/$userType';

        try {
          final hasPin = await _pinService.isPinSet(userType);
          print('🚀 Splash — pinSetAPI: $hasPin');
          if (hasPin) return '/pin-login/$userType';
        } catch (e) {
          print('❌ Erreur isPinSet: $e');
        }

        return '/set-pin/$userType';
      }

      if (loc.startsWith('/gerant')) {
        final loggedIn = await _apiService.isLoggedIn();
        final userType = await _apiService.getUserType();
        if (!loggedIn || userType != 'tenant') return '/welcome';
      }

      if (loc.startsWith('/membre')) {
        final loggedIn = await _apiService.isLoggedIn();
        final userType = await _apiService.getUserType();
        if (!loggedIn || userType != 'user') return '/welcome';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),

      // ── PIN
      GoRoute(
        path: '/set-pin/:userType',
        builder: (_, state) => SetPinScreen(
          userType: state.pathParameters['userType']!,
        ),
      ),
      GoRoute(
        path: '/pin-login/:userType',
        builder: (_, state) => PinLoginScreen(
          userType: state.pathParameters['userType']!,
        ),
      ),

      // ── Auth Gérant
      GoRoute(
        path: '/auth/tenant/register',
        builder: (_, __) => const TenantRegisterScreen(),
      ),
      GoRoute(
        path: '/auth/tenant/login',
        builder: (_, __) => const TenantLoginScreen(),
      ),

      // ── Auth Membre
      GoRoute(
        path: '/auth/member/join',
        builder: (_, __) => const MemberJoinScreen(),
      ),
      GoRoute(
        path: '/auth/member/login',
        builder: (_, __) => const MemberLoginScreen(),
      ),

      // ── Gérant
      GoRoute(
        path: '/gerant/home',
        builder: (_, __) => const GerantHomeScreen(),
      ),
      GoRoute(
        path: '/gerant/groups/create',
        builder: (_, __) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/gerant/groups/:id',
        builder: (_, state) => GroupDetailScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/gerant/groups/:id/edit',
        builder: (_, state) => EditGroupScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),

      // ── Membre
      GoRoute(
        path: '/membre/home',
        builder: (_, __) => const MembreHomeScreen(),
      ),
      GoRoute(
        path: '/membre/groups/:id',
        builder: (_, state) => MembreGroupDetailScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/membre/notifications',
        builder: (_, __) => const MembreNotificationsScreen(),
      ),
    ],
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B6B3A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.savings_rounded,
                    size: 54,
                    color: Color(0xFF1B6B3A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'MaTontine',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gérez vos tontines facilement',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}