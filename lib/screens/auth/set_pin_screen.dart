// lib/screens/auth/set_pin_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_theme.dart';
import '../../services/pin_service.dart';

class SetPinScreen extends StatefulWidget {
  final String userType;
  const SetPinScreen({super.key, required this.userType});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _pinService = PinService();
  String _pin = '';
  bool _confirming = false;
  bool _loading = false;
  String _errorMsg = '';

  void _onPinComplete(String pin) {
    if (!_confirming) {
      setState(() {
        _pin = pin;
        _confirming = true;
        _errorMsg = '';
      });
    } else {
      if (pin == _pin) {
        _savePin(pin);
      } else {
        setState(() {
          _errorMsg = 'Les codes ne correspondent pas. Réessayez.';
          _confirming = false;
          _pin = '';
        });
      }
    }
  }

  Future<void> _savePin(String pin) async {
    setState(() { _loading = true; _errorMsg = ''; });
    try {
      await _pinService.savePin(pin, widget.userType);
      if (mounted) {
        if (widget.userType == 'tenant') {
          context.go('/gerant/home');
        } else {
          context.go('/membre/home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Erreur lors de la sauvegarde. Réessayez.';
        _confirming = false;
        _pin = '';
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  // ── Header vert
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
                        Text(
                          _confirming
                              ? 'Confirmez votre PIN'
                              : 'Créez votre PIN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _confirming
                              ? 'Saisissez à nouveau le même code'
                              : 'Ce code remplacera le SMS\npour vos prochaines connexions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Indicateur étape
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepDot(active: !_confirming),
                      const SizedBox(width: 8),
                      _buildStepDot(active: _confirming),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    _confirming ? 'Confirmez le code' : 'Choisissez un code',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    '4 chiffres — mémorisez-le bien',
                    style: AppTextStyles.caption,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Saisie PIN
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: _loading
                        ? const SizedBox(
                            height: 60,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : PinCodeTextField(
                            key: ValueKey(_confirming),
                            appContext: context,
                            length: 4,
                            obscureText: true,
                            obscuringCharacter: '●',
                            onChanged: (_) {},
                            onCompleted: _onPinComplete,
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

                  // ── Erreur
                  if (_errorMsg.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md,
                          AppSpacing.lg, 0),
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
                            child: Text(
                              _errorMsg,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}