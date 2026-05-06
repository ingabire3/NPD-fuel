import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/users/new'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add User'),
      ),
      body: usersAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final pending  = users.where((u) => u.status == 'PENDING').toList();
          final active   = users.where((u) => u.status == 'ACTIVE').toList();
          final inactive = <UserModel>[];

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(usersListProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(label: 'Pending Approval (${pending.length})', color: AppColors.warning),
                  ...pending.map((u) => _UserCard(user: u)),
                  const SizedBox(height: 8),
                ],
                if (active.isNotEmpty) ...[
                  _SectionHeader(label: 'Active Users (${active.length})', color: AppColors.success),
                  ...active.map((u) => _UserCard(user: u)),
                  const SizedBox(height: 8),
                ],
                if (inactive.isNotEmpty) ...[
                  _SectionHeader(label: 'Inactive / Rejected (${inactive.length})', color: AppColors.textSecondary),
                  ...inactive.map((u) => _UserCard(user: u)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = _roleColor(user.role);
    final isPending = user.isPending;
    final isActive  = user.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        border: isPending ? Border.all(color: AppColors.warning.withOpacity(0.5)) : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Badge(label: user.role.replaceAll('_', ' '), color: roleColor),
                        _Badge(
                          label: isPending ? 'PENDING' : 'ACTIVE',
                          color: isPending ? AppColors.warning : AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action icons
              if (isPending) ...[
                _IconAction(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  tooltip: 'Approve',
                  onTap: () => _confirm(
                    context, ref,
                    title: 'Approve User',
                    message: 'Approve ${user.name}? They will be able to log in.',
                    confirmLabel: 'Approve',
                    confirmColor: Colors.green,
                    onConfirm: () => ref.read(createUserProvider.notifier).approve(user.id),
                  ),
                ),
                const SizedBox(width: 4),
                _IconAction(
                  icon: Icons.cancel,
                  color: Colors.red,
                  tooltip: 'Reject',
                  onTap: () => _confirm(
                    context, ref,
                    title: 'Reject User',
                    message: 'Reject ${user.name}? They will not be able to log in.',
                    confirmLabel: 'Reject',
                    confirmColor: Colors.red,
                    onConfirm: () => ref.read(createUserProvider.notifier).reject(user.id),
                  ),
                ),
              ] else if (isActive)
                _IconAction(
                  icon: Icons.person_off_outlined,
                  color: Colors.red,
                  tooltip: 'Deactivate',
                  onTap: () => _confirm(
                    context, ref,
                    title: 'Deactivate User',
                    message: 'Deactivate ${user.name}? They will lose app access.',
                    confirmLabel: 'Deactivate',
                    confirmColor: Colors.red,
                    onConfirm: () => ref.read(createUserProvider.notifier).deactivate(user.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin': return AppColors.primary;
      case 'driver':      return AppColors.success;
      case 'finance':     return AppColors.info;
      default:            return AppColors.textSecondary;
    }
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
