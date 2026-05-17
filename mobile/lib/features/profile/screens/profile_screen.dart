import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    user.role.replaceAll('_', ' '),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  // Info card
                  Card(
                    child: Column(
                      children: [
                        _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                        const Divider(height: 1),
                        _ProfileRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: user.phone ?? 'Not set'),
                        const Divider(height: 1),
                        _ProfileRow(
                            icon: Icons.badge_outlined,
                            label: 'Role',
                            value: user.role.replaceAll('_', ' ')),
                        const Divider(height: 1),
                        _ProfileRow(
                            icon: Icons.check_circle_outline,
                            label: 'Status',
                            value: user.isActive ? 'Active' : 'Inactive',
                            valueColor: user.isActive ? AppColors.success : AppColors.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    onPressed: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LogoutDialog(ref: ref),
    );
  }
}

class _LogoutDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _LogoutDialog({required this.ref});

  @override
  ConsumerState<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends ConsumerState<_LogoutDialog> {
  bool _loading = false;

  Future<void> _doLogout() async {
    setState(() => _loading = true);
    // Pop dialog first, then sign out — avoids navigator lock race
    if (mounted) Navigator.of(context).pop();
    await widget.ref.read(authProvider.notifier).logout();
    // go_router redirect to /login is handled by _RouterNotifier listener
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sign Out'),
      content: _loading
          ? const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            )
          : const Text('Are you sure you want to sign out?'),
      actions: _loading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: _doLogout,
                child: const Text('Sign Out'),
              ),
            ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
