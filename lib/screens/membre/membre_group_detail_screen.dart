// lib/screens/membre/membre_group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/contribution.dart';
import '../../models/member.dart';
import '../../services/group_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/skeleton_loader.dart';

class MembreGroupDetailScreen extends StatefulWidget {
  final String groupId;
  const MembreGroupDetailScreen({super.key, required this.groupId});

  @override
  State<MembreGroupDetailScreen> createState() =>
      _MembreGroupDetailScreenState();
}

class _MembreGroupDetailScreenState extends State<MembreGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final _groupService = GroupService();
  late TabController _tabController;

  Map<String, dynamic>? _turns;
  List<Contribution> _contribs = [];
  Map<String, dynamic>? _recap;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final turns = await _groupService.getMemberTurns(widget.groupId);
      final contribs =
          await _groupService.getMemberContributions(widget.groupId);
      Map<String, dynamic>? recap;
      try {
        recap = await _groupService.getCycleRecap(widget.groupId);
      } catch (_) {}

      setState(() {
        _turns = turns;
        _contribs = contribs;
        _recap = recap;
      });
    } catch (_) {
    } finally {
      setState(() { _loading = false; });
    }
  }

  List<GroupMember> get _members {
    final list = _turns?['members'] as List? ?? [];
    return list.map((j) => GroupMember.fromJson(j)).toList();
  }

  int get _myTurn => _turns?['myTurn'] ?? 0;

  Map<String, dynamic>? get _groupInfo => _turns?['group'];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon groupe')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonLoader(height: 100, borderRadius: 14),
              SizedBox(height: AppSpacing.md),
              MemberListSkeleton(count: 4),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/membre/home')),
        title: Text(_groupInfo?['name'] ?? 'Mon groupe'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Mon tour'),
            Tab(text: 'Membres'),
            Tab(text: 'Cotisations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyTurnTab(
            myTurn: _myTurn,
            members: _members,
            recap: _recap,
            groupInfo: _groupInfo,
          ),
          _MembersListTab(members: _members, myTurn: _myTurn),
          _MyContributionsTab(
            contribs: _contribs,
            recap: _recap,
          ),
        ],
      ),
    );
  }
}

// ── Onglet Mon tour
class _MyTurnTab extends StatelessWidget {
  final int myTurn;
  final List<GroupMember> members;
  final Map<String, dynamic>? recap;
  final Map<String, dynamic>? groupInfo;

  const _MyTurnTab({
    required this.myTurn,
    required this.members,
    this.recap,
    this.groupInfo,
  });

  @override
  Widget build(BuildContext context) {
    final total = members.length;
    final membersAfterMe =
        members.where((m) => m.orderTurn > myTurn).length;
    final membersBeforeMe =
        members.where((m) => m.orderTurn < myTurn).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carte mon tour — sans gradient, sans emojis
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Mon tour',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'N° $myTurn / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Date estimée
          _EstimatedDateCard(
            myTurn: myTurn,
            members: members,
            groupInfo: groupInfo,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Stats avant/après
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.arrow_upward,
                  label: 'Avant moi',
                  value: '$membersBeforeMe',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _InfoCard(
                  icon: Icons.arrow_downward,
                  label: 'Apres moi',
                  value: '$membersAfterMe',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Récap du cycle
          if (recap != null && recap!['recap'] != null) ...[
            const Text('Cycle en cours', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cotisations recues',
                          style: AppTextStyles.body),
                      Text(
                        '${recap!['recap']['receivedCount']}/${recap!['recap']['totalMembers']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (recap!['recap']['completionRate'] as num) / 100,
                      backgroundColor: AppColors.border,
                      color: AppColors.success,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total collecte',
                          style: AppTextStyles.body),
                      Text(
                        Formatters.amount(
                          (recap!['recap']['totalReceived'] as num).toDouble(),
                          recap!['group']['currency'],
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Ordre des tours
          if (members.isNotEmpty) ...[
            const Text('Ordre des tours', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            ...members.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: m.orderTurn == myTurn
                        ? AppColors.primarySurface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: m.orderTurn == myTurn
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: m.orderTurn == myTurn
                              ? AppColors.primary
                              : AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${m.orderTurn}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: m.orderTurn == myTurn
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.user.name,
                          style: TextStyle(
                            fontWeight: m.orderTurn == myTurn
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: m.orderTurn == myTurn
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (m.orderTurn == myTurn)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Moi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Date estimée
class _EstimatedDateCard extends StatelessWidget {
  final int myTurn;
  final List<GroupMember> members;
  final Map<String, dynamic>? groupInfo;

  const _EstimatedDateCard({
    required this.myTurn,
    required this.members,
    this.groupInfo,
  });

  Duration _getFrequencyDuration() {
    final desc = groupInfo?['description'] as String? ?? '';

    final regexDays = RegExp(r'Tous les (\d+) jour');
    final regexWeeks = RegExp(r'Tous les (\d+) semaine');
    final regexMonths = RegExp(r'Tous les (\d+) mois');

    if (regexDays.hasMatch(desc)) {
      final n = int.parse(regexDays.firstMatch(desc)!.group(1)!);
      return Duration(days: n);
    } else if (regexWeeks.hasMatch(desc)) {
      final n = int.parse(regexWeeks.firstMatch(desc)!.group(1)!);
      return Duration(days: n * 7);
    } else if (regexMonths.hasMatch(desc)) {
      final n = int.parse(regexMonths.firstMatch(desc)!.group(1)!);
      return Duration(days: n * 30);
    }

    return const Duration(days: 30);
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final turnsToWait = myTurn - 1;
    final frequency = _getFrequencyDuration();
    final estimatedDate = DateTime.now().add(
      Duration(days: frequency.inDays * turnsToWait),
    );

    final membersBeforeMe = members
        .where((m) => m.orderTurn < myTurn)
        .toList()
      ..sort((a, b) => a.orderTurn.compareTo(b.orderTurn));

    String mainText;
    String subText;
    IconData icon;
    Color color;

    if (turnsToWait <= 0) {
      mainText = "C'est votre tour !";
      subText = 'Vous etes le premier a recevoir la mise';
      icon = Icons.workspace_premium_outlined;
      color = AppColors.accent;
    } else {
      mainText = 'Vers le ${_formatDate(estimatedDate)}';
      subText = turnsToWait == 1
          ? '${membersBeforeMe.isNotEmpty ? membersBeforeMe.first.user.name : ""} recoit avant vous'
          : '$turnsToWait personne(s) recoivent avant vous';
      icon = Icons.calendar_month_outlined;
      color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quand est-ce que je recois ?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mainText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subText, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet Membres
class _MembersListTab extends StatelessWidget {
  final List<GroupMember> members;
  final int myTurn;

  const _MembersListTab({required this.members, required this.myTurn});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(
        child: Text('Aucun membre', style: AppTextStyles.body),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final m = members[i];
        final isMe = m.orderTurn == myTurn;

        return Container(
          decoration: BoxDecoration(
            color: isMe ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMe ? AppColors.primary : AppColors.border,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isMe ? AppColors.primary : AppColors.surfaceAlt,
              child: Text(
                '${m.orderTurn}',
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  m.user.name,
                  style: TextStyle(
                    fontWeight:
                        isMe ? FontWeight.w700 : FontWeight.w500,
                    color: isMe
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Moi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'Tour N°${m.orderTurn}',
              style: AppTextStyles.caption,
            ),
            trailing: isMe
                ? const Icon(Icons.workspace_premium_outlined,
                    color: AppColors.accent, size: 20)
                : null,
          ),
        );
      },
    );
  }
}

// ── Onglet Mes cotisations
class _MyContributionsTab extends StatelessWidget {
  final List<Contribution> contribs;
  final Map<String, dynamic>? recap;

  const _MyContributionsTab({required this.contribs, this.recap});

  Color _statusColor(String status) {
    switch (status) {
      case 'RECEIVED': return AppColors.success;
      case 'LATE': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'RECEIVED': return Icons.check_circle_outline;
      case 'LATE': return Icons.warning_outlined;
      default: return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (contribs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined,
                size: 56, color: AppColors.textHint),
            SizedBox(height: AppSpacing.md),
            Text('Aucune cotisation pour l\'instant',
                style: AppTextStyles.h4),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Vos cotisations apparaitront ici\nquand le gerant creera un cycle',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final received = contribs.where((c) => c.isReceived).length;
    final pending = contribs.where((c) => c.isPending).length;
    final late = contribs.where((c) => c.isLate).length;
    final totalPaid =
        (received * (contribs.isNotEmpty ? contribs.first.amount : 0.0))
            .toDouble();
    final currency = recap?['group']?['currency'] ?? 'XOF';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Mon bilan
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mon bilan', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _StatPill(
                      label: 'Payees',
                      value: '$received',
                      color: AppColors.success),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: 'En attente',
                      value: '$pending',
                      color: AppColors.warning),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: 'En retard',
                      value: '$late',
                      color: AppColors.error),
                ],
              ),
              if (received > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Total paye : ${Formatters.amount(totalPaid, currency)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        const Text('Historique', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),

        ...contribs.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: c.isLate
                      ? AppColors.error.withOpacity(0.3)
                      : AppColors.border,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(c.status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(c.status),
                    color: _statusColor(c.status),
                    size: 20,
                  ),
                ),
                title: Text(
                  Formatters.amount(c.amount, currency),
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Echeance : ${Formatters.date(c.dueDate)}',
                      style: AppTextStyles.caption,
                    ),
                    if (c.paidDate != null)
                      Text(
                        'Payee le : ${Formatters.date(c.paidDate!)}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(c.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(c.status),
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

// ── Widgets helpers
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}