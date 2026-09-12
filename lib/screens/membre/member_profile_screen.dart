// lib/screens/membre/member_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/change_phone_sheet.dart';
import '../../widgets/delete_account_sheet.dart';
import '../../widgets/privacy_policy_link.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final _profileService = ProfileService();
  final _apiService = ApiService();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _phone = '';
  String _tenantName = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _profileService.getMemberProfile();
      setState(() {
        _nameCtrl.text = profile['name'] ?? '';
        _phone = profile['phone'] ?? '';
        _tenantName = profile['tenantName'] ?? '';
      });
    } catch (_) {
      setState(() {
        _error = 'Impossible de charger votre profil.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });
    try {
      await _profileService.updateMemberProfile(name: _nameCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')),
        );
      }
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _changePhone() async {
    final newPhone = await showChangePhoneSheet(
      context,
      requestOtp: _profileService.memberChangePhoneRequestOtp,
      verifyOtp: (phone, otp) => _profileService.memberChangePhoneVerify(
        newPhone: phone,
        otp: otp,
      ),
    );
    if (newPhone != null) {
      setState(() {
        _phone = newPhone;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Numéro mis à jour. Le gérant a été prévenu.')),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text(
            'Vous devrez vous reconnecter avec votre numéro et un code SMS.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _apiService.clearTokens();
      if (mounted) context.go('/welcome');
    }
  }

  Future<void> _deleteAccount() async {
    final result = await showDeleteAccountSheet(
      context,
      warningMessage:
          'Le gérant sera informé. Votre nom sera retiré des groupes, mais '
          'l\'historique des cotisations restera visible pour la gestion du groupe. '
          'Vos informations personnelles seront définitivement effacées.',
      onConfirm: (pin) => _profileService.deleteMemberAccount(pin),
    );
    if (result == true) {
      await _apiService.clearTokens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé.')),
        );
        context.go('/welcome');
      }
    }
  }

  String get _initials {
    final parts = _nameCtrl.text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts[0][0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (_tenantName.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Membre chez $_tenantName',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        const Text('Nom complet', style: AppTextStyles.caption),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'Nom invalide'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text('Téléphone', style: AppTextStyles.caption),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _changePhone,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(_phone,
                                        style: AppTextStyles.body)),
                                Text('Modifier',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Le gérant et vos co-équipiers seront prévenus automatiquement si vous changez de numéro.',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: 'Enregistrer',
                          isLoading: _saving,
                          onPressed: _saving ? null : _save,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Center(child: PrivacyPolicyLinkButton()),
                        Center(
                          child: TextButton.icon(
                            onPressed: _confirmLogout,
                            icon: const Icon(Icons.logout,
                                color: AppColors.error, size: 18),
                            label: const Text('Se déconnecter',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _deleteAccount,
                            child: Text('Supprimer mon compte',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.underline)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
