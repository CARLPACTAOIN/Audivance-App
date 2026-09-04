import 'package:flutter/material.dart';

import '../../../app/ui/app_ui.dart';

/// A live visual preview of the 4 official signature blocks
/// (Treasurer, Auditor, Organization Head, Adviser) as rendered on official
/// USM OSA F46 Liquidation Reports and COA audit packages.
class SignatureBlockPreview extends StatelessWidget {
  const SignatureBlockPreview({
    super.key,
    required this.treasurerName,
    required this.auditorName,
    required this.headName,
    required this.adviserName,
    this.compact = false,
  });

  final String treasurerName;
  final String auditorName;
  final String headName;
  final String adviserName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderSm,
                ),
                child: const Icon(
                  Icons.draw_outlined,
                  size: 16,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official F46 Report Signature Preview',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'How signature blocks appear on generated reports',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 280
                  ? 1
                  : (constraints.maxWidth < 560 ? 2 : 4);
              final width = (constraints.maxWidth -
                      (crossAxisCount - 1) * AppSpacing.sm) /
                  crossAxisCount;

              final cells = [
                _SignatureCell(
                  title: 'Prepared by:',
                  name: treasurerName,
                  caption: 'Organization Treasurer',
                  roleTag: 'Treasurer',
                  isValid: treasurerName.trim().isNotEmpty,
                ),
                _SignatureCell(
                  title: 'Audited by:',
                  name: auditorName,
                  caption: 'Organization Auditor',
                  roleTag: 'Auditor',
                  isValid: auditorName.trim().isNotEmpty,
                ),
                _SignatureCell(
                  title: 'Submitted by:',
                  name: headName,
                  caption: 'Organization Head',
                  roleTag: 'Org Head',
                  isValid: headName.trim().isNotEmpty,
                ),
                _SignatureCell(
                  title: 'Noted:',
                  name: adviserName,
                  caption: 'Adviser',
                  roleTag: 'Adviser',
                  isValid: adviserName.trim().isNotEmpty,
                ),
              ];

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final cell in cells)
                    SizedBox(
                      width: width,
                      child: cell,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SignatureCell extends StatelessWidget {
  const _SignatureCell({
    required this.title,
    required this.name,
    required this.caption,
    required this.roleTag,
    required this.isValid,
  });

  final String title;
  final String name;
  final String caption;
  final String roleTag;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = name.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: isValid
              ? AppColors.borderSubtle
              : AppColors.warning.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: isValid
                      ? AppColors.brand.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  roleTag,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: isValid ? AppColors.brand : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              displayName.isNotEmpty ? displayName : '(Missing name)',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: displayName.isNotEmpty
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontSize: 10.5,
                color: displayName.isNotEmpty
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontStyle: displayName.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Divider(height: 1, color: AppColors.textPrimary),
          const SizedBox(height: 2),
          Center(
            child: Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 8.5,
                color: AppColors.textSecondary,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
