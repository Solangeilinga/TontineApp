// lib/widgets/change_phone_sheet.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'app_button.dart';

/// Affiche la feuille de changement de numéro (2 étapes). Retourne le
/// nouveau numéro si le changement a réussi, ou `null` si l'utilisateur a
/// annulé. Le backend s'occupe de notifier gérant/membres concernés — cette
/// feuille se contente d'orchestrer les deux appels API et l'UI.
Future<String?> showChangePhoneSheet(
  BuildContext context, {
  required Future<void> Function(String newPhone) requestOtp,
  required Future<void> Function(String newPhone, String otp) verifyOtp,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ChangePhoneSheet(requestOtp: requestOtp, verifyOtp: verifyOtp),
  );
}

class _ChangePhoneSheet extends StatefulWidget {
  final Future<void> Function(String newPhone) requestOtp;
  final Future<void> Function(String newPhone, String otp) verifyOtp;

  const _ChangePhoneSheet({required this.requestOtp, required this.verifyOtp});

  @override
  State<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<_ChangePhoneSheet> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpStep = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _newPhone => _phoneCtrl.text.trim();

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.requestOtp(_newPhone);
      setState(() {
        _otpStep = true;
      });
    } catch (e) {
      setState(() {
        _error = _extractError(e);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_otpCtrl.text.trim().length < 4) {
      setState(() {
        _error = 'Code invalide';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.verifyOtp(_newPhone, _otpCtrl.text.trim());
      if (mounted) Navigator.pop(context, _newPhone);
    } catch (e) {
      setState(() {
        _error = _extractError(e);
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data is Map
          ? e.response?.data['message'] as String?
          : null;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return 'Une erreur est survenue. Réessayez.';
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _otpStep ? 'Confirmez le nouveau numéro' : 'Changer de numéro',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            if (!_otpStep) ...[
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Toutes les personnes concernées (gérant et/ou membres) seront informées automatiquement de ce changement.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nouveau numéro (avec indicatif) *',
                  hintText: 'Ex: +22961000000',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => (v == null || v.trim().length < 8)
                    ? 'Numéro invalide'
                    : null,
              ),
            ] else ...[
              Text(
                'Un code a été envoyé par SMS au $_newPhone.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Code reçu par SMS *',
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _otpStep = false;
                          _error = null;
                        }),
                child: const Text('Modifier le numéro'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: _otpStep ? 'Confirmer' : 'Envoyer le code',
                isLoading: _loading,
                onPressed: _loading ? null : (_otpStep ? _confirm : _sendOtp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
