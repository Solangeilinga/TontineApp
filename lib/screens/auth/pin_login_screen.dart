// lib/screens/auth/pin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_theme.dart';
import '../../services/pin_service.dart';
import '../../services/api_service.dart';

class PinLoginScreen extends StatefulWidget {
  final String userType;
  const PinLoginScreen({super.key, required this.userType});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final _pinService = PinService();
  final _apiService = ApiService();
  String _errorMsg = '';
  int _attempts = 0;
  static const _maxAttempts = 5;

  Future<void> _verifyPin(String pin) async {
    setState(() { _errorMsg = ''; });

    // Utiliser l'endpoint verrouillé — pas besoin de token
    final result = await _pinService.verifyPinLocked(pin, widget.userType);

    if (result != null) {
      // PIN valide — sauvegarder les nouveaux tokens
      final data = result;
      await _apiService.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        userType: widget.userType,
      );
      setState(() { _attempts = 0; });
      if (mounted) {
        if (widget.userType == 'tenant') {
          context.go('/gerant/home');
        } else {
          context.go('/membre/home');
        }
      }
    } else {
      _attempts++;
      if (_attempts >= _maxAttempts) {
        await _pinService.clearPinCache();
        await _apiService.clearTokens();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trop de tentatives. Reconnectez-vous par SMS.'),
              backgroundColor: AppColors.error,
            ),
          );
          context.go('/welcome');
        }
      } else {
        setState(() {
          _errorMsg =
              'Code incorrect — ${_maxAttempts - _attempts} tentative(s) restante(s)';
        });
      }
    }
  }

  Future<void> _forgotPin() async {
    await _pinService.clearPinCache();
    await _apiService.clearTokens();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xl,
                        AppSpacing.lg, AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Bienvenue !',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Entrez votre code PIN pour continuer',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const Text('Votre code PIN', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('4 chiffres', style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xl),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: PinCodeTextField(
                      appContext: context,
                      length: 4,
                      obscureText: true,
                      obscuringCharacter: '●',
                      onChanged: (_) {
                        if (_errorMsg.isNotEmpty) {
                          setState(() => _errorMsg = '');
                        }
                      },
                      onCompleted: _verifyPin,
                      keyboardType: TextInputType.number,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(14),
                        fieldHeight: 60,
                        fieldWidth: 60,
                        activeFillColor: AppColors.primarySurface,
                        selectedFillColor: AppColors.primarySurface,
                        inactiveFillColor: AppColors.surfaceAlt,
                        activeColor: AppColors.primary,
                        selectedColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                      ),
                      enableActiveFill: true,
                      cursorColor: AppColors.primary,
                      textStyle: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  if (_errorMsg.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.2)),
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

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Column(
                      children: [
                        const Divider(color: AppColors.border),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: _forgotPin,
                          icon: const Icon(Icons.sms_outlined,
                              size: 18, color: AppColors.textSecondary),
                          label: const Text(
                            'Code oublié ? Se reconnecter par SMS',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}