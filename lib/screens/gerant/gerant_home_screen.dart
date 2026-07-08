// lib/screens/gerant/gerant_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/api_service.dart';
import '../../widgets/group_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/app_logo.dart';

class GerantHomeScreen extends StatefulWidget {
  const GerantHomeScreen({super.key});

  @override
  State<GerantHomeScreen> createState() => _GerantHomeScreenState();
}

class _GerantHomeScreenState extends State<GerantHomeScreen> {
  final _groupService = GroupService();
  final _apiService = ApiService();

  List<Group> _groups = [];
  Map<String, dynamic>? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final groups = await _groupService.getGroups();
      Map<String, dynamic>? dashboard;
      try {
        final res = await _apiService.dio.get('/groups/dashboard/summary');
        dashboard = res.data['data'];
      } catch (_) {}
      setState(() { _groups = groups; _dashboard = dashboard; });
    } catch (e) {
      setState(() { _error = 'Erreur de chargement'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _lockAndExit() async {
    await _apiService.lockSession();
    if (mounted) context.go('/pin-login/tenant');
  }

  @override
  Widget build(BuildContext context) {
    final activeGroups = _groups.where((g) => g.isActive).length;
    final alerts = _dashboard?['alerts'] as List? ?? [];
    final upcomingDue = _dashboard?['upcomingDue'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [

              // ── Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md,
                      AppSpacing.lg, AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                        bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      const AppLogo(size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MaTontine',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                )),
                            Text('${_groups.length} groupe(s)',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lock_outline),
                        color: AppColors.textSecondary,
                        onPressed: _lockAndExit,
                        tooltip: 'Verrouiller',
                      ),
                    ],
                  ),
                ),
              ),

              // ── Alertes (retards + dues bientôt)
              if (!_loading && (alerts.isNotEmpty || upcomingDue.isNotEmpty))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md,
                        AppSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('À votre attention',
                            style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.sm),

                        // Retards
                        ...alerts.map((a) => _AlertCard(
                          icon: Icons.warning_outlined,
                          color: AppColors.error,
                          title: a['groupName'],
                          message: a['message'],
                          members: List<String>.from(a['members'] ?? []),
                          onTap: () => context.go('/gerant/groups/${a['groupId']}'),
                        )),

                        // Dues bientôt
                        ...upcomingDue.map((a) => _AlertCard(
                          icon: Icons.schedule_outlined,
                          color: AppColors.warning,
                          title: a['groupName'],
                          message: a['message'],
                          members: const [],
                          onTap: () => context.go('/gerant/groups/${a['groupId']}'),
                        )),
                      ],
                    ),
                  ),
                ),

              // ── Stats rapides
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _loading
                      ? const Row(
                          children: [
                            Expanded(child: StatCardSkeleton()),
                            SizedBox(width: AppSpacing.md),
                            Expanded(child: StatCardSkeleton()),
                          ],
                        )
                      : Row(
                          children: [
                            _StatCard(
                              label: 'Groupes actifs',
                              value: '$activeGroups',
                              icon: Icons.group_work_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _StatCard(
                              label: 'Retards',
                              value: '${alerts.length}',
                              icon: Icons.warning_amber_outlined,
                              color: alerts.isEmpty
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ],
                        ),
                ),
              ),

              // ── Bouton créer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: AppButton(
                    label: 'Créer un nouveau groupe',
                    onPressed: () => context.go('/gerant/groups/create'),
                    icon: Icons.add,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                  child: Text('Mes groupes', style: AppTextStyles.h3),
                ),
              ),

              // ── Liste groupes
              if (_loading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const GroupCardSkeleton(),
                      childCount: 3,
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, style: AppTextStyles.body),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Réessayer',
                          onPressed: _load,
                          outlined: true,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_groups.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        const AppLogo(size: 64),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Aucun groupe pour l\'instant',
                            style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Créez votre premier groupe de tontine',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => GroupCard(
                        group: _groups[i],
                        onTap: () => context
                            .go('/gerant/groups/${_groups[i].id}'),
                      ),
                      childCount: _groups.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert card
class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final List<String> members;
  final VoidCallback onTap;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  Text(message,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
                  if (members.isNotEmpty)
                    Text(
                      members.join(', '),
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                  Text(label, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}