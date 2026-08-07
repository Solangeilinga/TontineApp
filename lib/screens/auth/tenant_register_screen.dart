// lib/screens/auth/tenant_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/pin_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/privacy_policy_link.dart';

class TenantRegisterScreen extends StatefulWidget {
  const TenantRegisterScreen({super.key});

  @override
  State<TenantRegisterScreen> createState() => _TenantRegisterScreenState();
}

class _TenantRegisterScreenState extends State<TenantRegisterScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  final _pinService = PinService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _loading = false;
  bool _acceptedTerms = false;
  String _otp = '';
  String _errorMsg = '';
  int _resendCountdown = 0;
  String _countryCode = '+226';

  String get _fullPhone => '$_countryCode${_phoneCtrl.text.trim()}';

  Future<void> _requestOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() {
        _errorMsg = "Veuillez accepter les conditions d'utilisation pour continuer";
      });
      return;
    }
    setState(() { _loading = true; _errorMsg = ''; });
    try {
      await _authService.tenantRequestOTP(
        phone: _fullPhone,
        name: _nameCtrl.text.trim(),
      );
      setState(() { _otpSent = true; _resendCountdown = 60; });
      _startCountdown();
    } catch (e) {
      setState(() { _errorMsg = _parseError(e); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otp.length < 6) return;
    setState(() { _loading = true; _errorMsg = ''; });
    try {
      final data = await _authService.tenantVerifyAndRegister(
        phone: _fullPhone,
        otp: _otp,
      );
      await _apiService.saveTokens(
        accessToken: data['data']['accessToken'],
        refreshToken: data['data']['refreshToken'],
        userType: 'tenant',
      );
      // ── Sauvegarder le numéro pour PIN verrouillé
      await _pinService.savePhone(_fullPhone);

      // ── Nouveau compte → toujours créer un PIN
      if (mounted) context.go('/set-pin/tenant');
    } catch (e) {
      setState(() { _errorMsg = _parseError(e); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() { _resendCountdown--; });
      return _resendCountdown > 0;
    });
  }

  String _parseError(dynamic e) {
    try {
      return e.response?.data?['message'] ?? 'Erreur réseau. Réessayez.';
    } catch (_) {
      return 'Erreur réseau. Réessayez.';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/welcome')),
        title: const Text('Créer un compte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                _otpSent ? 'Entrez le code reçu' : 'Vos informations',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _otpSent
                    ? 'Un code à 6 chiffres a été envoyé au $_fullPhone'
                    : 'Créez votre compte gérant MaTontine',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (!_otpSent) ...[
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Votre nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Entrez votre nom (min. 2 caractères)'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _countryCode,
                          isDense: true,
                          items: const [
                            DropdownMenuItem(
                                value: '+226', child: Text('🇧🇫 +226')),
                            DropdownMenuItem(
                                value: '+225', child: Text('🇨🇮 +225')),
                            DropdownMenuItem(
                                value: '+223', child: Text('🇲🇱 +223')),
                            DropdownMenuItem(
                                value: '+221', child: Text('🇸🇳 +221')),
                            DropdownMenuItem(
                                value: '+229', child: Text('🇧🇯 +229')),
                            DropdownMenuItem(
                                value: '+212', child: Text('🇲🇦 +212')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _countryCode = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          hintText: '70 00 00 01',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Entrez votre numéro'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (v) =>
                          setState(() => _acceptedTerms = v ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.caption,
                            children: [
                              const TextSpan(text: "J'ai lu et j'accepte les "),
                              TextSpan(
                                text: "conditions d'utilisation",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => context.push('/legal/terms'),
                              ),
                              const TextSpan(text: ' et la '),
                              privacyPolicyTextSpan(context),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_errorMsg.isNotEmpty) _errorBanner(),
                AppButton(
                  label: 'Recevoir le code SMS',
                  onPressed: _requestOTP,
                  isLoading: _loading,
                  icon: Icons.sms_outlined,
                ),
              ] else ...[
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  onChanged: (v) => _otp = v,
                  onCompleted: (_) => _verifyOTP(),
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 54,
                    fieldWidth: 46,
                    activeFillColor: AppColors.primarySurface,
                    selectedFillColor: AppColors.primarySurface,
                    inactiveFillColor: AppColors.surfaceAlt,
                    activeColor: AppColors.primary,
                    selectedColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                  ),
                  enableActiveFill: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_errorMsg.isNotEmpty) _errorBanner(),
                AppButton(
                  label: 'Confirmer',
                  onPressed: _verifyOTP,
                  isLoading: _loading,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          'Renvoyer dans $_resendCountdown s',
                          style: AppTextStyles.caption,
                        )
                      : TextButton(
                          onPressed: _requestOTP,
                          child: const Text('Renvoyer le code'),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBanner() => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
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
      );
}