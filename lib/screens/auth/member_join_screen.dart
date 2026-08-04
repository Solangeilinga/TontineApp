// lib/screens/auth/member_join_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/pin_service.dart';
import '../../widgets/app_button.dart';

class MemberJoinScreen extends StatefulWidget {
  const MemberJoinScreen({super.key});

  @override
  State<MemberJoinScreen> createState() => _MemberJoinScreenState();
}

class _MemberJoinScreenState extends State<MemberJoinScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  final _pinService = PinService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _loading = false;
  bool _acceptedTerms = false;
  String _otp = '';
  String _errorMsg = '';
  String _groupName = '';
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
      final data = await _authService.memberJoinRequestOTP(
        phone: _fullPhone,
        name: _nameCtrl.text.trim(),
        inviteCode: _inviteCodeCtrl.text.trim().toUpperCase(),
      );
      setState(() {
        _otpSent = true;
        _groupName = data['data']?['groupName'] ?? '';
        _resendCountdown = 60;
      });
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
      final data = await _authService.memberJoinVerify(
        phone: _fullPhone,
        otp: _otp,
      );
      await _apiService.saveTokens(
        accessToken: data['data']['accessToken'],
        refreshToken: data['data']['refreshToken'],
        userType: 'user',
      );
      // ── Sauvegarder le numéro ET l'identifiant du compte pour PIN verrouillé
      await _pinService.savePhone(_fullPhone);
      final userId = data['data']['user']?['id'] as String?;
      if (userId != null) await _pinService.saveUserId(userId);

      // ── Nouveau membre → toujours créer un PIN
      if (mounted) context.go('/set-pin/user');
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
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/welcome')),
        title: const Text('Rejoindre un groupe'),
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
                _otpSent ? 'Vérifiez votre identité' : 'Vos informations',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _otpSent
                    ? _groupName.isNotEmpty
                        ? 'Vous rejoignez : $_groupName'
                        : 'Un code a été envoyé à votre numéro.'
                    : 'Entrez votre nom, code d\'invitation et numéro',
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
                      ? 'Entrez votre nom'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _inviteCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code d\'invitation',
                    prefixIcon: Icon(Icons.link),
                    hintText: 'Ex: ABCD1234',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Entrez le code d\'invitation'
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
                          hintText: '70 00 00 01',
                          labelText: 'Téléphone',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Entrez votre numéro'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "MaTontine facilite le suivi de la tontine mais ne "
                          "détient ni ne garantit l'argent des cotisations. "
                          "Ne rejoignez un groupe qu'avec des personnes de confiance.",
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
                  label: 'Rejoindre le groupe',
                  onPressed: _verifyOTP,
                  isLoading: _loading,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: _resendCountdown > 0
                      ? Text('Renvoyer dans $_resendCountdown s',
                          style: AppTextStyles.caption)
                      : TextButton(
                          onPressed: _requestOTP,
                          child: const Text('Renvoyer le code'),
                        ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/auth/member/login'),
                  child: const Text(
                    'Déjà membre ? Se connecter',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
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
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
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