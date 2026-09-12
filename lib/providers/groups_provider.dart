// lib/providers/groups_provider.dart
//
// Providers Riverpod pour les données de l'écran d'accueil gérant.
//
// Portée volontairement limitée à cet écran pour l'instant (voir discussion
// avec l'utilisateur) : la navigation de cette app utilise `context.go(...)`
// sans ShellRoute, ce qui détruit et recrée l'écran d'accueil à chaque
// retour — le problème classique de "liste de groupes périmée après
// modification ailleurs" ne se manifeste donc pas vraiment ici aujourd'hui.
// Cette base sert de patron réutilisable pour les prochains écrans, et
// deviendra immédiatement utile si une navigation persistante (barre de
// navigation en bas, StatefulShellRoute) est introduite un jour : il
// suffira alors d'appeler `ref.invalidate(groupsProvider)` après une
// mutation, où que ce soit dans l'app, pour que l'accueil se resynchronise
// automatiquement sans réécrire de logique de rechargement manuelle.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/api_service.dart';

/// Liste des groupes du gérant connecté.
///
/// `autoDispose` : le provider est détruit quand plus aucun écran ne
/// l'observe (ex: après avoir quitté l'écran d'accueil), pour ne pas garder
/// des données en mémoire inutilement. Il sera recréé (et donc re-fetché)
/// à la prochaine observation — comportement équivalent à l'ancien
/// `initState() → _load()`, mais avec en plus la possibilité d'invalider
/// depuis n'importe où dans l'app tant qu'il reste observé.
final groupsProvider = FutureProvider.autoDispose<List<Group>>((ref) async {
  return GroupService().getGroups();
});

/// Résumé du tableau de bord (alertes de retard, échéances à venir).
/// Séparé de `groupsProvider` : les deux se rafraîchissent indépendamment,
/// et un échec de cet appel ne doit pas empêcher d'afficher les groupes
/// (voir le try/catch silencieux — comportement identique à l'ancien code).
final dashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final res = await ApiService().dio.get('/groups/dashboard/summary');
    return res.data['data'] as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
});
