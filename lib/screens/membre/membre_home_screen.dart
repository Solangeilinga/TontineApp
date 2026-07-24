// lib/screens/membre/membre_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/skeleton_loader.dart';

class MembreHomeScreen extends StatefulWidget {
  const MembreHomeScreen({super.key});

  @override
  State<MembreHomeScreen> createState() => _MembreHomeScreenState();
}

class _MembreHomeScreenState extends State<MembreHomeScreen> {
  final _groupService = GroupService();
  final _apiService = ApiService();

  List<Group> _groups = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadUnreadCount();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final groups = await _groupService.getMemberGroups();
      if (!mounted) return;
      setState(() { _groups = groups; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Erreur de chargement'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await _apiService.dio.get('/notifications/unread-count');
      if (!mounted) return;
      setState(() { _unreadCount = res.data['data']['count'] ?? 0; });
    } catch (_) {
      // silencieux — le badge reste simplement à 0 en cas d'erreur réseau
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_load(), _loadUnreadCount()]);
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                        bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bonjour 👋',
                                style: AppTextStyles.caption),
                            const SizedBox(height: 2),
                            const Text('Mes tontines',
                                style: AppTextStyles.h2),
                          ],
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            color: AppColors.textSecondary,
                            onPressed: () async {
                              await context.push('/membre/notifications');
                              _loadUnreadCount();
                            },
                            tooltip: 'Notifications',
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.surface, width: 1.5),
                                ),
                                child: Text(
                                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.lock_outline),
                        color: AppColors.textSecondary,
                        onPressed: () async {
                          await _apiService.lockSession();
                          if (mounted) context.go('/pin-login/user');
                        },
                        tooltip: 'Verrouiller',
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bouton rejoindre
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    label: 'Rejoindre un autre groupe',
                    onPressed: () => context.go('/auth/member/join'),
                    icon: Icons.add,
                    outlined: true,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                      AppSpacing.lg, AppSpacing.sm),
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
                        const Icon(Icons.group_off_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Vous n\'êtes dans aucun groupe',
                            style: AppTextStyles.h4),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Utilisez un code d\'invitation\npour rejoindre un groupe',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Rejoindre un groupe',
                          onPressed: () =>
                              context.go('/auth/member/join'),
                          icon: Icons.add,
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
                      (ctx, i) => _MembreGroupCard(
                        group: _groups[i],
                        onTap: () => context
                            .go('/membre/groups/${_groups[i].id}'),
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

class _MembreGroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const _MembreGroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.savings_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: AppTextStyles.h4),
                        const SizedBox(height: 2),
                        Text(
                          group.frequencyLabel,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberCount ?? 0} membres',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.savings_outlined,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${group.amount.toStringAsFixed(0)} ${group.currency}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}