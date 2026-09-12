// lib/screens/auth/tenant_login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/pin_service.dart';
import '../../widgets/app_button.dart';

class TenantLoginScreen extends StatefulWidget {
  const TenantLoginScreen({super.key});

  @override
  State<TenantLoginScreen> createState() => _TenantLoginScreenState();
}

class _TenantLoginScreenState extends State<TenantLoginScreen> {
  final _authService = AuthService();
  final _apiService = ApiService();
  final _pinService = PinService();
  final _phoneCtrl = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String _otp = '';
  String _errorMsg = '';
  int _resendCountdown = 0;
  String _countryCode = '+226';

  String get _fullPhone => '$_countryCode${_phoneCtrl.text.trim()}';

  Future<void> _requestOTP() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Entrez votre numéro de téléphone');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = '';
    });
    try {
      await _authService.tenantLoginRequestOTP(_fullPhone);
      setState(() {
        _otpSent = true;
        _resendCountdown = 60;
      });
      _startCountdown();
    } catch (e) {
      setState(() {
        _errorMsg = _parseError(e);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otp.length < 6) return;
    setState(() {
      _loading = true;
      _errorMsg = '';
    });
    try {
      final data = await _authService.tenantLoginVerify(
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

      final route = await _authService.getPostLoginRoute('tenant');
      if (mounted) context.go(route);
    } catch (e) {
      setState(() {
        _errorMsg = _parseError(e);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
      });
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
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/welcome')),
        title: const Text('Connexion gérant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              _otpSent ? 'Entrez votre code' : 'Votre numéro',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _otpSent
                  ? 'Si ce numéro est enregistré, vous avez reçu un code.'
                  : 'Connectez-vous avec votre numéro de téléphone',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!_otpSent) ...[
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
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
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
                label: 'Se connecter',
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
                onPressed: () => context.go('/auth/tenant/register'),
                child: const Text(
                  'Pas encore de compte ? Créer un compte',
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
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_errorMsg,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ],
        ),
      );
}
