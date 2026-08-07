// lib/screens/gerant/edit_group_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../widgets/app_button.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;
  const EditGroupScreen({super.key, required this.groupId});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _groupService = GroupService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _frequencyValueCtrl = TextEditingController(text: '1');
  final _maxMembersCtrl = TextEditingController();

  String _frequencyUnit = 'MONTHS';
  String _currency = 'XOF';
  bool _loading = false;
  bool _loadingData = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final detail = await _groupService.getGroupDetail(widget.groupId);
      final group = Group.fromJson(detail);
      setState(() {
        _nameCtrl.text = group.name;
        _amountCtrl.text = group.amount.toStringAsFixed(0);
        _currency = group.currency;
        _maxMembersCtrl.text = group.maxMembers?.toString() ?? '';
        _frequencyValueCtrl.text = group.frequencyValue.toString();
        _frequencyUnit = group.frequencyUnit;
        _descCtrl.text = group.description ?? '';
        _loadingData = false;
      });
    } catch (_) {
      setState(() => _loadingData = false);
    }
  }

  String get _frequencyLabel {
    final val = _frequencyValueCtrl.text.trim().isEmpty
        ? '1'
        : _frequencyValueCtrl.text.trim();
    final unit = {
      'DAYS': 'jour(s)',
      'WEEKS': 'semaine(s)',
      'MONTHS': 'mois',
    }[_frequencyUnit] ?? 'mois';
    return 'Tous les $val $unit';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = ''; });

    final userDesc = _descCtrl.text.trim();

    try {
      await _groupService.updateGroup(
        id: widget.groupId,
        name: _nameCtrl.text.trim(),
        frequencyValue: int.parse(_frequencyValueCtrl.text.trim()),
        frequencyUnit: _frequencyUnit,
        amount: double.parse(_amountCtrl.text.trim()),
        currency: _currency,
        description: userDesc.isEmpty ? null : userDesc,
        maxMembers: _maxMembersCtrl.text.trim().isEmpty
            ? null
            : int.parse(_maxMembersCtrl.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Groupe modifié avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/gerant/groups/${widget.groupId}');
      }
    } catch (e) {
      String msg = 'Erreur. Réessayez.';
      try { msg = (e as dynamic).response?.data?['message'] ?? msg; } catch (_) {}
      setState(() { _errorMsg = msg; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _frequencyValueCtrl.dispose();
    _maxMembersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
            onPressed: () => context.go('/gerant/groups/${widget.groupId}')),
        title: const Text('Modifier le groupe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom du groupe *',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Fréquence
              const Text('Fréquence de cotisation *', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text('Tous les', style: AppTextStyles.body),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 72,
                    child: TextFormField(
                      controller: _frequencyValueCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return '!';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _frequencyUnit,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'DAYS', child: Text('Jours')),
                        DropdownMenuItem(value: 'WEEKS', child: Text('Semaines')),
                        DropdownMenuItem(value: 'MONTHS', child: Text('Mois')),
                      ],
                      onChanged: (v) => setState(() => _frequencyUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(_frequencyLabel,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Montant + devise
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant de cotisation *',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        final parsed = double.tryParse(v);
                        if (parsed == null || parsed <= 0) return 'Invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Devise'),
                      items: const [
                        DropdownMenuItem(value: 'XOF', child: Text('XOF')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                      ],
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Max membres
              TextFormField(
                controller: _maxMembersCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre max de participants',
                  prefixIcon: Icon(Icons.people_outlined),
                  hintText: 'Laisser vide = illimité',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 2) return 'Minimum 2 participants';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_errorMsg.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_errorMsg,
                      style: const TextStyle(color: AppColors.error)),
                ),

              AppButton(
                label: 'Enregistrer les modifications',
                onPressed: _submit,
                isLoading: _loading,
                icon: Icons.save_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}