// lib/screens/gerant/audit_log_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/group_service.dart';
import '../../widgets/skeleton_loader.dart';

class AuditLogScreen extends StatefulWidget {
  final String groupId;
  const AuditLogScreen({super.key, required this.groupId});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _groupService = GroupService();
  List<Map<String, dynamic>> _logs = [];
  bool _isTruncated = false;
  int _totalCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _groupService.getAuditLog(widget.groupId);
      setState(() {
        _logs = result['logs'] as List<Map<String, dynamic>>;
        _isTruncated = result['isTruncated'] as bool;
        _totalCount = result['totalCount'] as int;
      });
    } catch (_) {
      setState(() {
        _error = 'Erreur de chargement';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'GROUP_CREATED':
        return Icons.add_circle_outline;
      case 'GROUP_UPDATED':
        return Icons.edit_outlined;
      case 'GROUP_ARCHIVED':
        return Icons.archive_outlined;
      case 'GROUP_UNARCHIVED':
        return Icons.unarchive_outlined;
      case 'MEMBER_ADDED':
        return Icons.person_add_outlined;
      case 'MEMBER_UPDATED':
        return Icons.edit_outlined;
      case 'MEMBER_REMOVED':
        return Icons.person_remove_outlined;
      case 'TURN_ORDER_UPDATED':
        return Icons.swap_vert;
      case 'CYCLE_CONTRIBUTIONS_CREATED':
        return Icons.add_card_outlined;
      case 'CONTRIBUTION_MARKED_RECEIVED':
        return Icons.check_circle_outline;
      case 'CONTRIBUTION_MARKED_LATE':
        return Icons.warning_outlined;
      case 'TURN_MARKED_RECEIVED':
        return Icons.workspace_premium_outlined;
      case 'CYCLE_CLOSED':
        return Icons.flag_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _colorFor(String action) {
    switch (action) {
      case 'MEMBER_REMOVED':
      case 'GROUP_ARCHIVED':
      case 'CONTRIBUTION_MARKED_LATE':
        return AppColors.error;
      case 'CONTRIBUTION_MARKED_RECEIVED':
      case 'TURN_MARKED_RECEIVED':
      case 'CYCLE_CLOSED':
        return AppColors.success;
      case 'MEMBER_ADDED':
      case 'GROUP_CREATED':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _describeMetadata(Map<String, dynamic> log) {
    final meta = log['metadata'] as Map<String, dynamic>?;
    if (meta == null) return '';

    switch (log['action']) {
      case 'MEMBER_ADDED':
      case 'MEMBER_REMOVED':
        return meta['memberName'] ?? '';
      case 'CONTRIBUTION_MARKED_RECEIVED':
      case 'CONTRIBUTION_MARKED_LATE':
        return meta['memberName'] ?? '';
      case 'TURN_MARKED_RECEIVED':
        return '${meta['memberName'] ?? ''} — Tour N°${meta['turnNumber'] ?? ''} '
            '(Cycle N°${meta['cycleNumber'] ?? ''})';
      case 'CYCLE_CLOSED':
        return 'Cycle N°${meta['cycleNumber'] ?? ''}';
      case 'CYCLE_CONTRIBUTIONS_CREATED':
        return '${meta['count'] ?? ''} cotisation(s) — Cycle N°${meta['cycleNumber'] ?? ''}';
      case 'GROUP_CREATED':
      case 'GROUP_UPDATED':
        return meta['name'] ?? '';
      default:
        return '';
    }
  }

  String _formatDateTime(String iso) {
    final date = DateTime.parse(iso).toLocal();
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} à $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text("Journal d'audit"),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: MemberListSkeleton(count: 6),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, style: AppTextStyles.body),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 56, color: AppColors.textHint),
                          SizedBox(height: AppSpacing.md),
                          Text('Aucune action enregistrée pour l\'instant',
                              style: AppTextStyles.h4),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _logs.length + (_isTruncated ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          if (_isTruncated && i == 0) {
                            return _UpsellBanner(
                              totalCount: _totalCount,
                              shownCount: _logs.length,
                              onTap: () => context.push('/gerant/subscription'),
                            );
                          }
                          final log = _logs[_isTruncated ? i - 1 : i];
                          final color = _colorFor(log['action'] as String);
                          final detail = _describeMetadata(log);

                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_iconFor(log['action'] as String),
                                      color: color, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log['actionLabel'] ?? log['action'],
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      if (detail.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(detail,
                                            style: AppTextStyles.caption),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '${log['actorName'] ?? ''} · ${_formatDateTime(log['createdAt'])}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// Bannière incitant à passer au plan Pro quand le journal d'audit est
/// tronqué (plans FREE/STARTER ne voient que les entrées récentes).
class _UpsellBanner extends StatelessWidget {
  final int totalCount;
  final int shownCount;
  final VoidCallback onTap;

  const _UpsellBanner({
    required this.totalCount,
    required this.shownCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vous voyez $shownCount action(s) sur $totalCount. '
                'Passez au plan Pro pour l\'historique complet.',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
