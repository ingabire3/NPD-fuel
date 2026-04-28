import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  (Color, Color, String) _resolve(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
        return (AppColors.warning, AppColors.warningLight, 'Pending');
      case 'APPROVED':
        return (AppColors.info, AppColors.infoLight, 'Approved');
      case 'REJECTED':
        return (AppColors.error, AppColors.errorLight, 'Rejected');
      case 'FULFILLED':
        return (AppColors.success, AppColors.successLight, 'Fulfilled');
      default:
        return (AppColors.textSecondary, AppColors.background, s);
    }
  }
}
