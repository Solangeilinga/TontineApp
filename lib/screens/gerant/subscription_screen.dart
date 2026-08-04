// lib/screens/gerant/subscription_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../widgets/app_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subService = SubscriptionService();

  TenantSubscription? _subscription;
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
      final sub = await _subService.getMySubscription();
      setState(() { _subscription = sub; });
    } catch (_) {
      setState(() { _error = 'Impossible de charger votre abonnement.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _openPaymentSheet(PlanInfo plan) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentSheet(plan: plan, subService: _subService),
    );
    if (result == true) _load();
  }

  Future<void> _confirmCancel() async {
    bool immediate = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Annuler l\'abonnement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vous pouvez garder l\'accès jusqu\'à la fin de votre période payée, ou revenir au plan Gratuit immédiatement.'),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: immediate,
                onChanged: (v) => setDialogState(() => immediate = v ?? false),
                title: const Text('Revenir au plan Gratuit maintenant', style: TextStyle(fontSize: 14)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirmer', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final msg = await _subService.cancel(immediate: immediate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'annulation.')),
        );
      }
    }
  }

  Future<void> _reactivate() async {
    try {
      final msg = await _subService.reactivate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la réactivation.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _StatusCard(
                        subscription: _subscription!,
                        onCancel: _confirmCancel,
                        onReactivate: _reactivate,
                      ),
                      const SizedBox(height: 24),
                      Text('Nos forfaits', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      ...PlanInfo.all.map((plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PlanCard(
                              plan: plan,
                              isCurrent: plan.key == _subscription!.effectivePlan,
                              onSelect: plan.key == 'FREE'
                                  ? null
                                  : () => _openPaymentSheet(plan),
                            ),
                          )),
                      const SizedBox(height: 8),
                      Text(
                        'Paiement sécurisé par Mobile Money',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─── CARTE DE STATUT ACTUEL ────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final TenantSubscription subscription;
  final VoidCallback onCancel;
  final VoidCallback onReactivate;

  const _StatusCard({
    required this.subscription,
    required this.onCancel,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final plan = PlanInfo.all.firstWhere((p) => p.key == subscription.effectivePlan);
    final endDate = subscription.currentPeriodEnd;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white),
              const SizedBox(width: 8),
              Text('Plan ${plan.label}',
                  style: AppTextStyles.h3.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          if (subscription.isPastDue)
            const Text('Votre abonnement a expiré. Renouvelez pour retrouver l\'accès complet.',
                style: TextStyle(color: Colors.white))
          else if (subscription.isCanceledButActive && endDate != null)
            Text('Annulé — accès conservé jusqu\'au ${_formatDate(endDate)}.',
                style: const TextStyle(color: Colors.white))
          else if (endDate != null)
            Text('Actif jusqu\'au ${_formatDate(endDate)}.',
                style: const TextStyle(color: Colors.white))
          else
            const Text('Plan de base, sans expiration.',
                style: TextStyle(color: Colors.white70)),
          if (subscription.effectivePlan != 'FREE') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: subscription.canReactivate
                  ? OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: onReactivate,
                      child: const Text('Réactiver'),
                    )
                  : TextButton(
                      onPressed: onCancel,
                      child: const Text('Annuler l\'abonnement',
                          style: TextStyle(color: Colors.white)),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── CARTE D'UN PLAN ────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final bool isCurrent;
  final VoidCallback? onSelect;

  const _PlanCard({required this.plan, required this.isCurrent, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.highlighted ? AppColors.primary : AppColors.border,
          width: plan.highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.label, style: AppTextStyles.h3),
              const Spacer(),
              Text(
                plan.amount == 0 ? 'Gratuit' : '${plan.amount} FCFA/mois',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(child: Text(f, style: AppTextStyles.caption)),
                  ],
                ),
              )),
          if (onSelect != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Plan actuel'),
                    )
                  : AppButton(label: 'Choisir ce forfait', onPressed: onSelect),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── FEUILLE DE PAIEMENT (téléphone, opérateur, OTP éventuel) ─────────────
class _PaymentSheet extends StatefulWidget {
  final PlanInfo plan;
  final SubscriptionService subService;

  const _PaymentSheet({required this.plan, required this.subService});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

// Indicatifs téléphoniques de tous les pays africains, pour auto-préfixer
// le numéro à partir du pays choisi — l'utilisateur n'a JAMAIS besoin de le
// taper lui-même tant que SebPay reste sur le continent africain. La liste
// des PAYS proposés, elle, vient toujours des opérateurs réels renvoyés par
// SebPay (voir _loadOperators) — cette table sert uniquement à convertir un
// code ISO en indicatif, pas à restreindre les pays affichés.
const Map<String, String> _kDialCodes = {
  'DZ': '213', 'AO': '244', 'BJ': '229', 'BW': '267', 'BF': '226',
  'BI': '257', 'CV': '238', 'CM': '237', 'CF': '236', 'TD': '235',
  'KM': '269', 'CG': '242', 'CD': '243', 'CI': '225', 'DJ': '253',
  'EG': '20', 'GQ': '240', 'ER': '291', 'SZ': '268', 'ET': '251',
  'GA': '241', 'GM': '220', 'GH': '233', 'GN': '224', 'GW': '245',
  'KE': '254', 'LS': '266', 'LR': '231', 'LY': '218', 'MG': '261',
  'MW': '265', 'ML': '223', 'MR': '222', 'MU': '230', 'MA': '212',
  'MZ': '258', 'NA': '264', 'NE': '227', 'NG': '234', 'RW': '250',
  'ST': '239', 'SN': '221', 'SC': '248', 'SL': '232', 'SO': '252',
  'ZA': '27', 'SS': '211', 'SD': '249', 'TZ': '255', 'TG': '228',
  'TN': '216', 'UG': '256', 'ZM': '260', 'ZW': '263',
};

/// Construit l'emoji drapeau à partir d'un code ISO à 2 lettres (ex: "BF"
/// → 🇧🇫), sans avoir besoin d'une table de correspondance à maintenir.
String _flagFor(String iso) {
  if (iso.length != 2) return '🏳️';
  final code = iso.toUpperCase();
  return String.fromCharCodes(
    code.codeUnits.map((c) => 0x1F1E6 + (c - 0x41)),
  );
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // Tous les opérateurs autorisés (Orange/Moov), tous pays confondus —
  // récupérés une seule fois, puis filtrés localement par pays sélectionné
  // (évite un aller-retour réseau à chaque changement de pays).
  List<Map<String, dynamic>> _allOperators = [];
  List<Map<String, String>> _countries = []; // [{iso, name}]
  String? _selectedCountryIso;
  String? _selectedOperator; // valeur = op['code'], ex: "orange", "moov"
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  List<Map<String, dynamic>> get _operatorsForCountry => _allOperators
      .where((op) => _countryIsoOf(op) == _selectedCountryIso)
      .toList();

  String? get _dialCode =>
      _selectedCountryIso == null ? null : _kDialCodes[_selectedCountryIso];

  bool get _otpRequired {
    if (_selectedOperator == null) return false;
    final op = _operatorsForCountry.firstWhere(
      (o) => o['code'] == _selectedOperator,
      orElse: () => {},
    );
    return op['otp_required'] == true || op['otpRequired'] == true;
  }

  /// Le champ `country` renvoyé par SebPay peut être soit un objet, soit
  /// directement une chaîne — on gère les deux, en restant strict : un code
  /// ISO fait 2 ou 3 lettres, jamais un `id` numérique. Sans ça, un champ
  /// `id` inattendu (ex: un grand entier) pouvait se retrouver affiché tel
  /// quel comme "pays" dans le menu déroulant.
  String? _countryIsoOf(Map<String, dynamic> op) {
    final c = op['country'];
    String? candidate;
    if (c is Map) {
      candidate = (c['code'] ?? c['iso'] ?? c['iso_code'] ?? c['alpha2'] ?? c['country_code'])
          ?.toString();
    } else if (c is String) {
      candidate = c;
    }
    if (candidate == null) return null;
    final trimmed = candidate.trim();
    // Un code ISO pays fait 2 ou 3 lettres — tout le reste (id, timestamp,
    // nom complet...) est rejeté plutôt qu'affiché tel quel.
    final isPlausibleIso = RegExp(r'^[A-Za-z]{2,3}$').hasMatch(trimmed);
    return isPlausibleIso ? trimmed.toUpperCase() : null;
  }

  String _countryNameOf(Map<String, dynamic> op) {
    final c = op['country'];
    if (c is Map) {
      final name = (c['name'] ?? c['label'] ?? c['country_name'] ?? c['title'])?.toString();
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    // À défaut d'un vrai nom, on retombe sur le code ISO (déjà validé ci-
    // dessus, donc jamais un nombre à rallonge).
    return _countryIsoOf(op) ?? '?';
  }

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  /// Récupère tous les opérateurs autorisés (Orange/Moov) une seule fois,
  /// puis dérive la liste des pays disponibles à partir des vraies données
  /// — aucun pays codé en dur, donc aucun risque d'en oublier un que SebPay
  /// ajouterait plus tard.
  Future<void> _loadOperators() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ops = await widget.subService.getOperators();

      // DEBUG TEMPORAIRE — à retirer une fois le format de "country"
      // confirmé. Permet de voir la vraie structure JSON dans la console.
      if (ops.isNotEmpty) {
        // ignore: avoid_print
        print('🔍 RAW OPERATOR[0]: ${ops.first}');
      }

      final seen = <String>{};
      final countries = <Map<String, String>>[];
      for (final op in ops) {
        final iso = _countryIsoOf(op);
        if (iso == null || seen.contains(iso)) continue;
        seen.add(iso);
        countries.add({'iso': iso, 'name': _countryNameOf(op)});
      }
      countries.sort((a, b) => a['name']!.compareTo(b['name']!));

      setState(() {
        _allOperators = ops;
        _countries = countries;
        _selectedCountryIso = countries.isNotEmpty ? countries.first['iso'] : null;
      });
      _onCountryChanged(_selectedCountryIso);
    } catch (_) {
      setState(() {
        _allOperators = [];
        _countries = [];
        _error = 'Impossible de charger les opérateurs disponibles.';
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _onCountryChanged(String? iso) {
    setState(() {
      _selectedCountryIso = iso;
      final ops = _operatorsForCountry;
      _selectedOperator = ops.isNotEmpty ? ops.first['code']?.toString() : null;
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedOperator == null) return;
    setState(() { _submitting = true; _error = null; });
    try {
      // SebPay attend le numéro au format international SANS le "+".
      // Si on connaît l'indicatif du pays et que l'utilisateur n'a saisi
      // que le numéro local, on le préfixe ; sinon on part du principe
      // qu'il a saisi le numéro complet lui-même (voir hint du champ).
      final rawPhone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      final fullPhone = (_dialCode != null && !rawPhone.startsWith(_dialCode!))
          ? '$_dialCode$rawPhone'
          : rawPhone;

      await widget.subService.subscribe(
        plan: widget.plan.key,
        phone: fullPhone,
        operator: _selectedOperator!,
        country: _selectedCountryIso!,
        otpCode: _otpRequired ? _otpCtrl.text.trim() : null,
      );
      setState(() { _submitted = true; });
    } catch (e) {
      String msg = 'Erreur lors du paiement. Réessayez.';
      if (e is DioException) {
        final backendMsg = e.response?.data is Map
            ? (e.response?.data['message'] as String?)
            : null;
        if (backendMsg != null && backendMsg.isNotEmpty) msg = backendMsg;
      }
      setState(() { _error = msg; });
    } finally {
      setState(() { _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: _submitted ? _buildSuccessState(context) : _buildFormState(context),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.phone_android, size: 48, color: AppColors.primary),
        const SizedBox(height: 12),
        Text('Demande envoyée', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        const Text(
          'Composez le code de confirmation reçu sur votre téléphone pour valider le paiement Mobile Money. Votre abonnement s\'active automatiquement dès la confirmation.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'OK, j\'ai compris',
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );
  }

  Widget _buildFormState(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payer ${widget.plan.amount} FCFA — ${widget.plan.label}',
              style: AppTextStyles.h3),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_countries.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error ?? 'Aucun opérateur disponible pour le moment. Réessayez plus tard.',
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            )
          else ...[
            Text('Pays', style: AppTextStyles.caption),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryIso,
                  isExpanded: true,
                  items: _countries
                      .map((c) => DropdownMenuItem(
                            value: c['iso'],
                            child: Text('${_flagFor(c['iso']!)} ${c['name']}'),
                          ))
                      .toList(),
                  onChanged: _onCountryChanged,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro Mobile Money *',
                hintText: _dialCode != null
                    ? 'Numéro local (sans le +$_dialCode)'
                    : 'Numéro complet avec indicatif (sans le +)',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 6) return 'Numéro invalide';
                // Indicatif inconnu pour ce pays : on ne peut pas le
                // rajouter automatiquement, donc on exige un numéro assez
                // long pour être sûr que l'indicatif est bien inclus.
                if (_dialCode == null && digits.length < 10) {
                  return 'Incluez l\'indicatif du pays (ex: 22961000000)';
                }
                return null;
              },
            ),
            if (_dialCode == null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'N\'oubliez pas l\'indicatif de ce pays au début du numéro, sinon le paiement échouera.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _operatorsForCountry.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Orange Money et Moov Money ne sont pas encore disponibles pour ce pays.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedOperator,
                    decoration: const InputDecoration(
                      labelText: 'Opérateur *',
                      prefixIcon: Icon(Icons.sim_card_outlined),
                    ),
                    items: _operatorsForCountry.map((op) {
                      final code = op['code'].toString();
                      final name = (op['name'] ?? code).toString();
                      return DropdownMenuItem(value: code, child: Text(name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedOperator = v),
                    validator: (v) => v == null ? 'Choisissez un opérateur' : null,
                  ),
            if (_otpRequired) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Code OTP reçu par SMS *',
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
                validator: (v) => (_otpRequired && (v == null || v.trim().isEmpty))
                    ? 'Code requis pour cet opérateur'
                    : null,
              ),
            ],
          ],
          if (_error != null && _countries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Payer maintenant',
              isLoading: _submitting,
              onPressed: (_submitting || _operatorsForCountry.isEmpty) ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}