import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../../core/constants/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final unreadCount = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo in AppBar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'lib/assets/logo.jpeg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${user?.name.split(' ').first ?? 'User'}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user?.role.replaceAll('_', ' ') ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
                onPressed: () => context.go('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orange summary banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Text(
                  'Overview',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statsAsync.when(
                      loading: () => const _StatsLoading(),
                      error: (e, _) => _ErrorCard(message: e.toString()),
                      data: (stats) => _StatsGrid(stats: stats, role: user?.role ?? ''),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _QuickActions(role: user?.role ?? ''),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String role;
  const _StatsGrid({required this.stats, required this.role});

  @override
  Widget build(BuildContext context) {
    final cards = <_StatCard>[];

    if (role == 'SUPER_ADMIN' || role == 'MANAGER') {
      cards.addAll([
        _StatCard(
          label: 'Pending Requests',
          value: '${stats['pendingRequests'] ?? 0}',
          icon: Icons.pending_actions,
          color: AppColors.warning,
          bg: AppColors.warningLight,
        ),
        _StatCard(
          label: 'Total Vehicles',
          value: '${stats['totalVehicles'] ?? 0}',
          icon: Icons.directions_car,
          color: AppColors.primary,
          bg: AppColors.primaryContainer,
        ),
        _StatCard(
          label: 'Anomalies',
          value: '${stats['anomalyCount'] ?? 0}',
          icon: Icons.warning_amber,
          color: AppColors.error,
          bg: AppColors.errorLight,
        ),
        _StatCard(
          label: 'Fulfilled Today',
          value: '${stats['fulfilledToday'] ?? 0}',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          bg: AppColors.successLight,
        ),
      ]);
    } else if (role == 'DRIVER') {
      cards.addAll([
        _StatCard(
          label: 'My Requests',
          value: '${stats['myRequests'] ?? 0}',
          icon: Icons.local_gas_station,
          color: AppColors.primary,
          bg: AppColors.primaryContainer,
        ),
        _StatCard(
          label: 'Pending',
          value: '${stats['myPending'] ?? 0}',
          icon: Icons.pending_actions,
          color: AppColors.warning,
          bg: AppColors.warningLight,
        ),
        _StatCard(
          label: 'Allocation (L)',
          value: '${stats['remainingLiters'] ?? 0}',
          icon: Icons.water_drop_outlined,
          color: AppColors.primary,
          bg: AppColors.primaryContainer,
        ),
        _StatCard(
          label: 'Fulfilled',
          value: '${stats['myFulfilled'] ?? 0}',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          bg: AppColors.successLight,
        ),
      ]);
    } else if (role == 'FINANCE') {
      final budget = (stats['totalBudget'] as num?)?.toDouble() ?? 0;
      final usedL = (stats['totalUsedLiters'] as num?)?.toDouble() ?? 0;
      final allocL = (stats['totalAllocatedLiters'] as num?)?.toDouble() ?? 0;
      cards.addAll([
        _StatCard(
          label: 'Monthly Budget (RWF)',
          value: budget >= 1000000
              ? '${(budget / 1000000).toStringAsFixed(1)}M'
              : '${(budget / 1000).toStringAsFixed(0)}K',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.primary,
          bg: AppColors.primaryContainer,
        ),
        _StatCard(
          label: 'Allocated (L)',
          value: allocL.toStringAsFixed(0),
          icon: Icons.water_drop_outlined,
          color: AppColors.info,
          bg: AppColors.infoLight,
        ),
        _StatCard(
          label: 'Used (L)',
          value: usedL.toStringAsFixed(0),
          icon: Icons.local_gas_station,
          color: AppColors.warning,
          bg: AppColors.warningLight,
        ),
        _StatCard(
          label: 'Open Anomalies',
          value: '${stats['openAnomalies'] ?? 0}',
          icon: Icons.warning_amber,
          color: AppColors.error,
          bg: AppColors.errorLight,
        ),
      ]);
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: cards,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final String role;
  const _QuickActions({required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (role == 'DRIVER' || role == 'SUPER_ADMIN')
          _ActionTile(
            icon: Icons.add_circle_outline,
            label: 'New Fuel Request',
            subtitle: 'Submit a request for fuel',
            color: AppColors.primary,
            onTap: () => context.go('/requests/new'),
          ),
        if (role == 'FINANCE') ...[
          _ActionTile(
            icon: Icons.approval_outlined,
            label: 'Review Requests',
            subtitle: 'Approve or reject pending fuel requests',
            color: AppColors.primary,
            onTap: () => context.go('/requests'),
          ),
        ],
        if (role == 'SUPER_ADMIN')
          _ActionTile(
            icon: Icons.list_alt,
            label: 'Review Requests',
            subtitle: 'Approve, reject or manage all fuel requests',
            color: AppColors.primary,
            onTap: () => context.go('/requests'),
          ),
        if (role == 'MANAGER')
          _ActionTile(
            icon: Icons.list_alt,
            label: 'Team Requests',
            subtitle: 'Monitor your team\'s fuel requests',
            color: AppColors.primary,
            onTap: () => context.go('/requests'),
          ),
        _ActionTile(
          icon: Icons.receipt_long_outlined,
          label: 'View Receipts',
          subtitle: 'Browse uploaded fuel receipts',
          color: AppColors.primary,
          onTap: () => context.go('/receipts'),
        ),
        if (role == 'DRIVER')
          _ActionTile(
            icon: Icons.water_drop_outlined,
            label: 'My Allocation',
            subtitle: 'View remaining fuel allocation',
            color: AppColors.primary,
            onTap: () => context.go('/allocations'),
          ),
        if (role == 'FINANCE') ...[
          _ActionTile(
            icon: Icons.assignment_outlined,
            label: 'View Allocations',
            subtitle: 'Track monthly fuel budgets',
            color: AppColors.primary,
            onTap: () => context.go('/allocations'),
          ),
          _ActionTile(
            icon: Icons.warning_amber_outlined,
            label: 'Review Anomalies',
            subtitle: 'Check flagged transactions',
            color: AppColors.warning,
            onTap: () => context.go('/anomalies'),
          ),
        ],
        if (role == 'SUPER_ADMIN') ...[
          _ActionTile(
            icon: Icons.people_outlined,
            label: 'User Management',
            subtitle: 'Create and manage system users',
            color: AppColors.info,
            onTap: () => context.go('/admin/users'),
          ),
          _ActionTile(
            icon: Icons.directions_car_outlined,
            label: 'Vehicle Management',
            subtitle: 'Add vehicles and assign drivers',
            color: AppColors.info,
            onTap: () => context.go('/admin/vehicles'),
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}
