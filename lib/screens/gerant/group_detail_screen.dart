// lib/screens/gerant/group_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import '../../models/contribution.dart';
import '../../services/group_service.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_button.dart';
import '../../widgets/skeleton_loader.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final _groupService = GroupService();
  final _apiService = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() { _loading = true; });
    try {
      final detail = await _groupService.getGroupDetail(widget.groupId);
      setState(() { _detail = detail; });
    } catch (_) {
    } finally {
      setState(() { _loading = false; });
    }
  }

  Group? get _group {
    if (_detail == null) return null;
    return Group.fromJson(_detail!);
  }

  List<GroupMember> get _members {
    final list = _detail?['groupMembers'] as List? ?? [];
    return list.map((j) => GroupMember.fromJson(j)).toList();
  }

  Future<void> _copyInviteCode() async {
    final code = _group?.inviteCode ?? '';
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copié !'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareOnWhatsApp() async {
    final group = _group;
    if (group == null) return;

    final message = Uri.encodeComponent(
      'Rejoignez ma tontine "${group.name}" sur MaTontine !\n\n'
      'Cotisation : ${Formatters.amount(group.amount, group.currency)}\n'
      'Frequence : ${group.frequencyLabel}\n'
      '${group.maxMembers != null ? 'Membres : ${group.memberCount ?? 0}/${group.maxMembers}\n' : ''}'
      '\nCode d\'invitation : ${group.inviteCode}\n\n'
      'Utilisez ce code pour rejoindre le groupe sur MaTontine.',
    );

    final whatsappUrl = Uri.parse('whatsapp://send?text=$message');
    final webUrl = Uri.parse('https://wa.me/?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(
        text: 'Rejoignez ${group.name} ! Code : ${group.inviteCode}',
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code copié — WhatsApp non détecté')),
        );
      }
    }
  }

  Future<void> _shareRecapOnWhatsApp(Map<String, dynamic> recap) async {
    final group = _group;
    if (group == null) return;

    final contribs = recap['contributions'] as List? ?? [];
    final recapData = recap['recap'];

    final StringBuffer msg = StringBuffer();
    msg.writeln('Recapitulatif — ${group.name}');
    msg.writeln('Date : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    msg.writeln('');
    msg.writeln('Montant/membre : ${Formatters.amount(group.amount, group.currency)}');
    msg.writeln('Recues : ${recapData['receivedCount']}/${recapData['totalMembers']}');
    msg.writeln('En attente : ${recapData['pendingCount']}');
    msg.writeln('En retard : ${recapData['lateCount']}');
    msg.writeln('Collecte : ${Formatters.amount((recapData['totalReceived'] as num).toDouble(), group.currency)}');
    msg.writeln('');
    msg.writeln('Detail par membre :');

    for (final c in contribs) {
      final name = c['user']?['name'] ?? 'Inconnu';
      final status = c['status'];
      final label = status == 'RECEIVED' ? '[Paye]'
          : status == 'LATE' ? '[Retard]' : '[Attente]';
      msg.writeln('$label $name');
    }

    msg.writeln('');
    msg.writeln('Envoye via MaTontine');

    final encoded = Uri.encodeComponent(msg.toString());
    final whatsappUrl = Uri.parse('whatsapp://send?text=$encoded');
    final webUrl = Uri.parse('https://wa.me/?text=$encoded');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: msg.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recap copie dans le presse-papiers')),
        );
      }
    }
  }

  Future<void> _archiveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archiver le groupe ?'),
        content: const Text('Le groupe ne sera plus actif. Les données sont conservées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _groupService.archiveGroup(widget.groupId);
      if (mounted) context.go('/gerant/home');
    }
  }

  Future<void> _unarchiveGroup() async {
    await _groupService.unarchiveGroup(widget.groupId);
    _loadDetail();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Groupe reactivé !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Groupe')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonLoader(height: 80, borderRadius: 12),
              SizedBox(height: AppSpacing.md),
              MemberListSkeleton(count: 5),
            ],
          ),
        ),
      );
    }

    final group = _group;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Groupe')),
        body: const Center(child: Text('Groupe introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/gerant/home')),
        title: Text(group.name),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ]),
              ),
              if (group.isActive)
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(children: [
                    Icon(Icons.archive_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Archiver'),
                  ]),
                )
              else
                const PopupMenuItem(
                  value: 'unarchive',
                  child: Row(children: [
                    Icon(Icons.unarchive_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Reactiver'),
                  ]),
                ),
            ],
            onSelected: (v) {
              if (v == 'edit') context.go('/gerant/groups/${widget.groupId}/edit');
              if (v == 'archive') _archiveGroup();
              if (v == 'unarchive') _unarchiveGroup();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Membres'),
            Tab(text: 'Cotisations'),
            Tab(text: 'Tours'),
            Tab(text: 'Activite'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      _chip(group.typeLabel, AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.frequencyLabel,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.amount(group.amount, group.currency),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          const Text('Code d\'invitation', style: AppTextStyles.label),
                          const Spacer(),
                          if (group.isFull)
                            _statusBadge('Complet', AppColors.error),
                          if (!group.isActive)
                            _statusBadge('Archive', AppColors.textHint),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            group.inviteCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 22,
                              letterSpacing: 4,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined, size: 20),
                            color: AppColors.primary,
                            onPressed: _copyInviteCode,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _shareOnWhatsApp,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.share, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('WhatsApp',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (group.maxMembers != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((group.memberCount ?? 0) / group.maxMembers!)
                                .clamp(0.0, 1.0),
                            backgroundColor: AppColors.border,
                            color: group.isFull ? AppColors.error : AppColors.primary,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.memberCount ?? 0} / ${group.maxMembers} participants',
                          style: TextStyle(
                            fontSize: 12,
                            color: group.isFull
                                ? AppColors.error
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(
                  members: _members,
                  groupId: widget.groupId,
                  group: group,
                  onRefresh: _loadDetail,
                  groupService: _groupService,
                ),
                _ContributionsTab(
                  groupId: widget.groupId,
                  groupService: _groupService,
                  onShareRecap: _shareRecapOnWhatsApp,
                ),
                _TurnsTab(
                  groupId: widget.groupId,
                  apiService: _apiService,
                ),
                _ActivityTab(
                  groupId: widget.groupId,
                  apiService: _apiService,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 && group.isActive
          ? group.isFull
              ? FloatingActionButton.extended(
                  onPressed: () => _showGroupFullDialog(context),
                  backgroundColor: AppColors.error,
                  icon: const Icon(Icons.lock),
                  label: const Text('Groupe complet'),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _showAddMemberSheet(context),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter'),
                )
          : null,
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      );

  void _showGroupFullDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Groupe complet'),
        content: Text(
          'Ce groupe a atteint sa capacite maximale de ${_group?.maxMembers} participants.\n\nPour ajouter des membres, modifiez le groupe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/gerant/groups/${widget.groupId}/edit');
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String countryCode = '+226';
    bool loading = false;
    String errorMsg = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajouter un membre', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: countryCode,
                      items: const [
                        DropdownMenuItem(value: '+226', child: Text('BF +226')),
                        DropdownMenuItem(value: '+225', child: Text('CI +225')),
                        DropdownMenuItem(value: '+229', child: Text('BJ +229')),
                        DropdownMenuItem(value: '+221', child: Text('SN +221')),
                        DropdownMenuItem(value: '+223', child: Text('ML +223')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => countryCode = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '70 00 00 01'),
                    ),
                  ),
                ],
              ),
              if (errorMsg.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(errorMsg,
                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Ajouter le membre',
                isLoading: loading,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      phoneCtrl.text.trim().isEmpty) {
                    setModalState(() => errorMsg = 'Nom et telephone requis');
                    return;
                  }
                  setModalState(() { loading = true; errorMsg = ''; });
                  try {
                    await _groupService.addMember(
                      groupId: widget.groupId,
                      name: nameCtrl.text.trim(),
                      phone: '$countryCode${phoneCtrl.text.trim()}',
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadDetail();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membre ajoute !'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    String msg = 'Erreur. Reessayez.';
                    try {
                      msg = (e as dynamic).response?.data?['message'] ?? msg;
                    } catch (_) {}
                    setModalState(() { loading = false; errorMsg = msg; });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab Membres
class _MembersTab extends StatelessWidget {
  final List<GroupMember> members;
  final String groupId;
  final Group group;
  final VoidCallback onRefresh;
  final GroupService groupService;

  const _MembersTab({
    required this.members,
    required this.groupId,
    required this.group,
    required this.onRefresh,
    required this.groupService,
  });

  void _showEditMemberSheet(BuildContext context, GroupMember m) {
    final nameCtrl = TextEditingController(text: m.user.name);
    final phoneCtrl = TextEditingController(
        text: m.user.phone.replaceAll('+226', ''));
    String countryCode = '+226';
    bool loading = false;
    String errorMsg = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modifier le membre', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: countryCode,
                      items: const [
                        DropdownMenuItem(value: '+226', child: Text('BF +226')),
                        DropdownMenuItem(value: '+225', child: Text('CI +225')),
                        DropdownMenuItem(value: '+229', child: Text('BJ +229')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => countryCode = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '70 00 00 01'),
                    ),
                  ),
                ],
              ),
              if (errorMsg.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(errorMsg,
                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Enregistrer',
                isLoading: loading,
                onPressed: () async {
                  setModalState(() { loading = true; errorMsg = ''; });
                  try {
                    await groupService.updateMember(
                      groupId: groupId,
                      userId: m.userId,
                      name: nameCtrl.text.trim().isEmpty
                          ? null : nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty
                          ? null
                          : '$countryCode${phoneCtrl.text.trim()}',
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      onRefresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membre modifie !'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    String msg = 'Erreur. Reessayez.';
                    try {
                      msg = (e as dynamic).response?.data?['message'] ?? msg;
                    } catch (_) {}
                    setModalState(() { loading = false; errorMsg = msg; });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            const Text('Aucun membre pour l\'instant', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Partagez le code d\'invitation pour ajouter des membres',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final m = members[i];
          return ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySurface,
              child: Text(
                '${m.orderTurn}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(m.user.name, style: AppTextStyles.bodyMedium),
            subtitle: Text(
                Formatters.phone(m.user.phone), style: AppTextStyles.caption),
            trailing: PopupMenuButton(
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(children: [
                    Icon(Icons.remove_circle_outline,
                        color: AppColors.error, size: 16),
                    SizedBox(width: 8),
                    Text('Retirer',
                        style: TextStyle(color: AppColors.error)),
                  ]),
                ),
              ],
              onSelected: (v) async {
                if (v == 'edit') {
                  _showEditMemberSheet(ctx, m);
                } else if (v == 'remove') {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (d) => AlertDialog(
                      title: const Text('Retirer ce membre ?'),
                      content: Text('Retirer ${m.user.name} du groupe ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(d, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          child: const Text('Retirer'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await groupService.removeMember(
                        groupId: groupId, userId: m.userId);
                    onRefresh();
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Tab Cotisations
class _ContributionsTab extends StatefulWidget {
  final String groupId;
  final GroupService groupService;
  final Function(Map<String, dynamic>) onShareRecap;

  const _ContributionsTab({
    required this.groupId,
    required this.groupService,
    required this.onShareRecap,
  });

  @override
  State<_ContributionsTab> createState() => _ContributionsTabState();
}

class _ContributionsTabState extends State<_ContributionsTab> {
  List<Contribution> _contribs = [];
  Map<String, dynamic>? _recap;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final list =
          await widget.groupService.getContributions(widget.groupId);
      final recap =
          await widget.groupService.getCycleRecap(widget.groupId);
      setState(() { _contribs = list; _recap = recap; });
    } catch (_) {
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _markReceived(Contribution c) async {
    await widget.groupService.markReceived(c.id);
    _load();
  }

  Future<void> _markLate(Contribution c) async {
    await widget.groupService.markLate(c.id);
    _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'RECEIVED': return AppColors.success;
      case 'LATE': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: ContributionSkeleton(count: 5),
      );
    }

    if (_contribs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payments_outlined,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            const Text('Aucune cotisation', style: AppTextStyles.h4),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Creez un cycle de cotisations pour commencer',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppButton(
                label: 'Creer un cycle',
                onPressed: () => _showCreateCycleSheet(context),
                icon: Icons.add,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Nouveau cycle',
                  onPressed: () => _showCreateCycleSheet(context),
                  icon: Icons.add,
                ),
              ),
              if (_recap != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => widget.onShareRecap(_recap!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.share, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Recap',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (_recap != null && _recap!['recap'] != null) ...[
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
                  const Text('Recapitulatif', style: AppTextStyles.h4),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _RecapStat(
                        label: 'Recues',
                        value: '${_recap!['recap']['receivedCount']}',
                        color: AppColors.success,
                        icon: Icons.check_circle_outline,
                      ),
                      _RecapStat(
                        label: 'En attente',
                        value: '${_recap!['recap']['pendingCount']}',
                        color: AppColors.warning,
                        icon: Icons.hourglass_empty,
                      ),
                      _RecapStat(
                        label: 'En retard',
                        value: '${_recap!['recap']['lateCount']}',
                        color: AppColors.error,
                        icon: Icons.warning_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_recap!['recap']['completionRate'] as num) / 100,
                      backgroundColor: AppColors.border,
                      color: AppColors.success,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collecte : ${Formatters.amount(
                          (_recap!['recap']['totalReceived'] as num).toDouble(),
                          _recap!['group']['currency'],
                        )}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${_recap!['recap']['completionRate']}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if ((_recap!['recap']['remaining'] as num) > 0)
                    Text(
                      'Reste : ${Formatters.amount(
                        (_recap!['recap']['remaining'] as num).toDouble(),
                        _recap!['group']['currency'],
                      )}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          ..._contribs.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(c.user?.name ?? '',
                      style: AppTextStyles.bodyMedium),
                  subtitle: Text(
                    'Echeance : ${Formatters.date(c.dueDate)}',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
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
                      if (c.isPending) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton(
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'received',
                              child: Row(children: [
                                Icon(Icons.check_circle_outline,
                                    color: AppColors.success, size: 18),
                                SizedBox(width: 8),
                                Text('Marquer recue'),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'late',
                              child: Row(children: [
                                Icon(Icons.warning_outlined,
                                    color: AppColors.warning, size: 18),
                                SizedBox(width: 8),
                                Text('Marquer en retard'),
                              ]),
                            ),
                          ],
                          onSelected: (v) {
                            if (v == 'received') _markReceived(c);
                            if (v == 'late') _markLate(c);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showCreateCycleSheet(BuildContext context) {
    DateTime selected = DateTime.now().add(const Duration(days: 7));
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouveau cycle de cotisations',
                  style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Une cotisation sera creee pour chaque membre du groupe.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(Icons.calendar_today,
                    color: AppColors.primary),
                title: const Text('Date d\'echeance'),
                subtitle: Text(
                  Formatters.date(selected),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selected,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => selected = picked);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Creer les cotisations',
                isLoading: loading,
                onPressed: () async {
                  setModalState(() => loading = true);
                  try {
                    await widget.groupService.createCycle(
                      groupId: widget.groupId,
                      dueDate: selected,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      _load();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cotisations creees avec succes !'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    setModalState(() => loading = false);
                    String msg = 'Erreur. Reessayez.';
                    try {
                      msg = (e as dynamic).response?.data?['message'] ?? msg;
                    } catch (_) {}
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab Tours — CORRIGE null safety
class _TurnsTab extends StatefulWidget {
  final String groupId;
  final ApiService apiService;

  const _TurnsTab({required this.groupId, required this.apiService});

  @override
  State<_TurnsTab> createState() => _TurnsTabState();
}

class _TurnsTabState extends State<_TurnsTab> {
  Map<String, dynamic>? _data;
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
      final res = await widget.apiService.dio
          .get('/groups/${widget.groupId}/turns');
      final data = res.data['data'];
      if (data != null) {
        setState(() { _data = data; });
      } else {
        setState(() { _error = 'Aucune donnée reçue'; });
      }
    } catch (e) {
      setState(() { _error = 'Erreur de chargement'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _markReceived(
      Map<String, dynamic> member, int turnNumber) async {
    try {
      await widget.apiService.dio.post(
        '/groups/${widget.groupId}/turns/received',
        data: {
          'userId': member['userId'],
          'turnNumber': turnNumber,
        },
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${member['user']['name']} a recu sa mise !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      String msg = 'Erreur. Reessayez.';
      try {
        msg = (e as dynamic).response?.data?['message'] ?? msg;
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _showConfirmDialog(Map<String, dynamic> member, int turnNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la remise'),
        content: Text(
          '${member['user']['name']} a bien recu la mise du tour N°$turnNumber ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markReceived(member, turnNumber);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: MemberListSkeleton(count: 4),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Reessayer',
              onPressed: _load,
              outlined: true,
            ),
          ],
        ),
      );
    }

    // Null safety — cast sécurisé
    final turns = (_data?['turns'] as List?) ?? [];
    final pendingMembers = (_data?['pendingMembers'] as List?) ?? [];
    final receivedCount = (_data?['receivedCount'] as int?) ?? 0;
    final totalMembers = (_data?['totalMembers'] as int?) ?? 0;

    if (totalMembers == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 56, color: AppColors.textHint),
            SizedBox(height: AppSpacing.md),
            Text('Aucun membre dans ce groupe',
                style: AppTextStyles.h4),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Résumé
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_outlined,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Remises effectuees',
                          style: AppTextStyles.h4),
                      Text(
                        '$receivedCount / $totalMembers membres ont recu leur mise',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // En attente de recevoir
          if (pendingMembers.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.hourglass_empty,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 6),
                const Text('En attente de recevoir',
                    style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...pendingMembers.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value as Map<String, dynamic>;
              final turnNumber = receivedCount + i + 1;
              final isNext = i == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isNext
                      ? AppColors.accent.withOpacity(0.06)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNext
                        ? AppColors.accent.withOpacity(0.3)
                        : AppColors.border,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isNext
                        ? AppColors.accent.withOpacity(0.15)
                        : AppColors.surfaceAlt,
                    child: Text(
                      '$turnNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isNext
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  title: Text(
                    (m['user'] as Map<String, dynamic>?)?['name'] ?? '',
                    style: TextStyle(
                      fontWeight:
                          isNext ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    isNext ? 'Prochain a recevoir' : 'Tour N°$turnNumber',
                    style: TextStyle(
                      color: isNext
                          ? AppColors.accent
                          : AppColors.textHint,
                      fontSize: 12,
                      fontWeight: isNext
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isNext
    ? ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 100),
        child: ElevatedButton(
          onPressed: () =>
              _showConfirmDialog(m, turnNumber),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text(
            'Marquer reçu',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      )
    : null,
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],

          // Ont deja recu
          if (turns.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 6),
                const Text('Ont deja recu', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...turns
                .where((t) => (t as Map<String, dynamic>)['status'] == 'DONE')
                .map((t) {
              final turn = t as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (turn['user'] as Map<String, dynamic>?)?['name'] ?? '',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            'Tour N°${turn['turnNumber']}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Recu',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Tab Activite
class _ActivityTab extends StatefulWidget {
  final String groupId;
  final ApiService apiService;

  const _ActivityTab({required this.groupId, required this.apiService});

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  List<dynamic> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final res = await widget.apiService.dio
          .get('/groups/${widget.groupId}/activity');
      setState(() {
        _activities = (res.data['data'] as List?) ?? [];
      });
    } catch (_) {
      setState(() { _activities = []; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  String _timeAgo(String dateStr) {
    final date = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'a l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: MemberListSkeleton(count: 5),
      );
    }

    if (_activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline_outlined,
                size: 56, color: AppColors.textHint),
            SizedBox(height: AppSpacing.md),
            Text('Aucune activite pour l\'instant',
                style: AppTextStyles.h4),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Les actions dans ce groupe apparaitront ici',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _activities.length,
        itemBuilder: (ctx, i) {
          final a = _activities[i] as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _ActivityIcon(type: a['type'] as String? ?? 'GENERAL'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['text'] as String? ?? '',
                          style: AppTextStyles.bodyMedium),
                      Text(
                        _timeAgo(a['date'] as String),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Icone activite — sans emojis
class _ActivityIcon extends StatelessWidget {
  final String type;
  const _ActivityIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case 'CONTRIBUTION_RECEIVED':
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        break;
      case 'CONTRIBUTION_LATE':
        icon = Icons.warning_outlined;
        color = AppColors.error;
        break;
      case 'CONTRIBUTION_PENDING':
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        break;
      case 'MEMBER_JOINED':
        icon = Icons.person_add_outlined;
        color = AppColors.primary;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.textSecondary;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ── Widgets helpers
class _RecapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _RecapStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}