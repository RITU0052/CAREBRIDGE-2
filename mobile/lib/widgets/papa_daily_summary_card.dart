import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PapaDailySummaryCard extends StatelessWidget {
  final String parentName;
  final int takenMeds;
  final int totalMeds;
  final int reportsCount;
  final int appointmentsCount;
  final bool hasActiveEmergency;

  const PapaDailySummaryCard({
    super.key,
    this.parentName = "Papa",
    required this.takenMeds,
    required this.totalMeds,
    required this.reportsCount,
    required this.appointmentsCount,
    required this.hasActiveEmergency,
  });

  @override
  Widget build(BuildContext context) {
    final allMedsTaken = totalMeds > 0 && takenMeds == totalMeds;
    final isEverythingOkay = (totalMeds == 0 || allMedsTaken) && !hasActiveEmergency;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.emergency, size: 24),
              const SizedBox(width: 8),
              Text(
                "❤️ $parentName's Daily Summary",
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RowItem(
            icon: Icons.medication_rounded,
            iconColor: AppColors.primary,
            title: "Medicine",
            subtitle: totalMeds > 0 ? "✅ $takenMeds/$totalMeds Taken" : "None Today",
            badgeColor: allMedsTaken ? AppColors.successLight : AppColors.warningLight,
            textColor: allMedsTaken ? AppColors.success : AppColors.warning,
          ),
          const Divider(height: 20),
          _RowItem(
            icon: Icons.description_rounded,
            iconColor: AppColors.info,
            title: "Reports",
            subtitle: reportsCount > 0 ? "$reportsCount new report(s)" : "No new reports",
            badgeColor: AppColors.surfaceVariant,
            textColor: AppColors.textSecondary,
          ),
          const Divider(height: 20),
          _RowItem(
            icon: Icons.calendar_month_rounded,
            iconColor: AppColors.bpColor,
            title: "Appointments",
            subtitle: appointmentsCount > 0 ? "$appointmentsCount scheduled" : "None",
            badgeColor: AppColors.surfaceVariant,
            textColor: AppColors.textSecondary,
          ),
          const Divider(height: 20),
          _RowItem(
            icon: Icons.shield_rounded,
            iconColor: AppColors.emergency,
            title: "Emergency",
            subtitle: hasActiveEmergency ? "🚨 Active Alert!" : "None",
            badgeColor: hasActiveEmergency ? AppColors.emergencyLight : AppColors.successLight,
            textColor: hasActiveEmergency ? AppColors.emergency : AppColors.success,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEverythingOkay ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(isEverythingOkay ? "🟢" : "⚠️", style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEverythingOkay ? "Everything looks okay today." : "Papa missed a medicine or vital check.",
                    style: TextStyle(
                      color: isEverythingOkay ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is your "peace of mind" feature.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color badgeColor;
  final Color textColor;

  const _RowItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
          child: Text(
            subtitle,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
