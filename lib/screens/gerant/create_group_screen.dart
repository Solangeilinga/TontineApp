// lib/screens/gerant/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/group_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/app_button.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupService = GroupService();
  final _subscriptionService = SubscriptionService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _frequencyValueCtrl = TextEditingController(text: '1');
  final _maxMembersCtrl = TextEditingController();

  final String _type = 'MONEY';
  String _frequencyUnit = 'MONTHS';
  String _currency = 'XOF';
  bool _loading = false;
  String _errorMsg = '';

  // Limite de membres/groupe du plan actuel — null tant que non chargée, ou
  // si le plan permet un nombre illimité. Récupérée une fois à l'ouverture
  // pour valider immédiatement côté client (le backend reste la source de
  // vérité et revalide de toute façon à la soumission).
  int? _planMaxMembers;

  @override
  void initState() {
    super.initState();
    _loadPlanLimit();
  }

  Future<void> _loadPlanLimit() async {
    try {
      final sub = await _subscriptionService.getMySubscription();
      final limit = sub.limits['maxMembersPerGroup'];
      setState(() {
        _planMaxMembers = limit is int ? limit : null;
      });
    } catch (_) {
      // Pas grave si ça échoue — le backend validera de toute façon à la
      // soumission, ceci n'est qu'un confort d'affichage immédiat.
    }
  }

  String get _frequencyLabel {
    final val = _frequencyValueCtrl.text.trim().isEmpty
        ? '1'
        : _frequencyValueCtrl.text.trim();
    final unit = {
          'DAYS': int.tryParse(val) == 1 ? 'jour' : 'jours',
          'WEEKS': int.tryParse(val) == 1 ? 'semaine' : 'semaines',
          'MONTHS': 'mois',
        }[_frequencyUnit] ??
        'mois';
    return 'Tous les $val $unit';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    final userDesc = _descCtrl.text.trim();

    try {
      final group = await _groupService.createGroup(
        name: _nameCtrl.text.trim(),
        type: _type,
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
            content: Text('✅ Groupe créé avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/gerant/groups/${group.id}');
      }
    } catch (e) {
      String msg = 'Erreur. Réessayez.';
      try {
        msg = (e as dynamic).response?.data?['message'] ?? msg;
      } catch (_) {}
      setState(() {
        _errorMsg = msg;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/gerant/home')),
        title: const Text('Nouveau groupe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nom du groupe
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom du groupe *',
                  prefixIcon: Icon(Icons.group_outlined),
                  hintText: 'Ex: Tontine Famille 2026',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Type — V1 Argent uniquement
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.savings_outlined,
                        color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tontine en argent',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Cotisation en espèces ou mobile money',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Fréquence personnalisable
              const Text('Fréquence de cotisation *',
                  style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text('Tous les', style: AppTextStyles.body),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _frequencyUnit,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'DAYS', child: Text('Jours')),
                        DropdownMenuItem(
                            value: 'WEEKS', child: Text('Semaines')),
                        DropdownMenuItem(value: 'MONTHS', child: Text('Mois')),
                      ],
                      onChanged: (v) => setState(() => _frequencyUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Aperçu fréquence
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      _frequencyLabel,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Montant + devise — CORRIGÉ overflow
              const Text('Montant de cotisation *', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Montant — prend tout l'espace disponible
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Ex: 10000',
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
                  const SizedBox(width: 8),
                  // Devise — largeur fixe réduite
                  SizedBox(
                    width: 90,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'XOF',
                          child: Text('F CFA', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'EUR',
                          child: Text('EUR', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: 'USD',
                          child: Text('USD', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Nombre max de participants
              TextFormField(
                controller: _maxMembersCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre max de participants',
                  prefixIcon: const Icon(Icons.people_outlined),
                  hintText: 'Laisser vide = illimité',
                  helperText: _planMaxMembers != null
                      ? 'Votre plan actuel autorise jusqu\'à $_planMaxMembers participants par groupe'
                      : 'Le groupe sera fermé une fois ce nombre atteint',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 2) return 'Minimum 2 participants';
                  if (_planMaxMembers != null && n > _planMaxMembers!) {
                    return 'Max $_planMaxMembers avec votre plan actuel — passez à un forfait supérieur pour plus';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Description optionnelle
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  hintText: 'Ex: Tontine mensuelle de la famille',
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
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "N'invitez que des personnes que vous connaissez et en qui "
                        "vous avez confiance. MaTontine suit les cotisations déclarées "
                        "mais ne détient ni ne garantit l'argent échangé entre membres.",
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),

              AppButton(
                label: 'Créer le groupe',
                onPressed: _submit,
                isLoading: _loading,
                icon: Icons.check,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
