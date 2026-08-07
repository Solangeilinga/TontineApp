// lib/widgets/group_card.dart
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../config/app_theme.dart';
import '../utils/formatters.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;

  const GroupCard({super.key, required this.group, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icône
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: AppTextStyles.h4),
                        const SizedBox(height: 2),
                        Text(
                          group.frequencyLabel,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Badges statut
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Badge Complet
                      if (group.isFull)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Complet',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      // Badge Actif/Archivé
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: group.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.textHint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          group.isActive ? 'Actif' : 'Archivé',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: group.isActive
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Barre de progression si maxMembers défini
              if (group.maxMembers != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((group.memberCount ?? 0) / group.maxMembers!)
                        .clamp(0.0, 1.0),
                    backgroundColor: AppColors.border,
                    color: group.isFull ? AppColors.error : AppColors.primary,
                    minHeight: 4,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  // Membres
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        group.maxMembers != null
                            ? '${group.memberCount ?? 0}/${group.maxMembers} membres'
                            : '${group.memberCount ?? 0} membres',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Montant
                  Row(
                    children: [
                      const Icon(Icons.savings_outlined,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        Formatters.amount(group.amount, group.currency),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
