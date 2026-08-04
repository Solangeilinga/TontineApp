// lib/widgets/delete_account_sheet.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'app_button.dart';

/// Affiche la feuille de suppression de compte. Retourne `true` si la
/// suppression a réussi (l'appelant doit alors déconnecter et rediriger),
/// ou `false`/`null` si annulé.
///
/// Double friction volontaire pour une action irréversible :
/// 1. Taper le mot "SUPPRIMER" pour confirmer l'intention
/// 2. Saisir le PIN pour confirmer l'identité
Future<bool?> showDeleteAccountSheet(
  BuildContext context, {
  required String warningMessage,
  required Future<void> Function(String pin) onConfirm,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _DeleteAccountSheet(
      warningMessage: warningMessage,
      onConfirm: onConfirm,
    ),
  );
}

class _DeleteAccountSheet extends StatefulWidget {
  final String warningMessage;
  final Future<void> Function(String pin) onConfirm;

  const _DeleteAccountSheet({required this.warningMessage, required this.onConfirm});

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _confirmCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _typedConfirmed = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pinCtrl.text.trim().length != 4) {
      setState(() { _error = 'Entrez votre PIN à 4 chiffres'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onConfirm(_pinCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      String msg = 'Erreur. Réessayez.';
      if (e is DioException) {
        final backendMsg = e.response?.data is Map ? e.response?.data['message'] as String? : null;
        if (backendMsg != null && backendMsg.isNotEmpty) msg = backendMsg;
      }
      setState(() { _error = msg; });
    } finally {
      setState(() { _loading = false; });
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Text('Supprimer le compte', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.warningMessage,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Cette action est irréversible.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text('Tapez SUPPRIMER pour confirmer', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          TextField(
            controller: _confirmCtrl,
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) => setState(() {
              _typedConfirmed = v.trim().toUpperCase() == 'SUPPRIMER';
            }),
            decoration: const InputDecoration(hintText: 'SUPPRIMER'),
          ),
          if (_typedConfirmed) ...[
            const SizedBox(height: 16),
            Text('Confirmez avec votre PIN', style: AppTextStyles.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(counterText: '', hintText: '••••'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Supprimer définitivement',
              color: AppColors.error,
              isLoading: _loading,
              onPressed: (_typedConfirmed && !_loading) ? _submit : null,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}