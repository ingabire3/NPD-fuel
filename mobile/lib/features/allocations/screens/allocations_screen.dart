import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/allocations_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/allocation_model.dart';
import '../../../features/auth/providers/auth_provider.dart';

class AllocationsScreen extends ConsumerWidget {
  const AllocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isDriver = user?.isDriver ?? false;

    if (isDriver) return const _DriverAllocationView();
    return const _ManagerAllocationView();
  }
}

class _DriverAllocationView extends ConsumerWidget {
  const _DriverAllocationView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlloc = ref.watch(myCurrentAllocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Fuel Allocation')),
      body: asyncAlloc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alloc) {
          if (alloc == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No allocation for this month',
                      style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('Contact your manager to create one',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _AllocationCard(alloc: alloc, showUser: false),
                const SizedBox(height: 16),
                _AllocationDetailsCard(alloc: alloc),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ManagerAllocationView extends ConsumerWidget {
  const _ManagerAllocationView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(allocationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Fuel Allocations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/allocations/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Allocation'),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No allocations yet',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(allocationsListProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AllocationCard(alloc: list[i], showUser: true),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final AllocationModel alloc;
  final bool showUser;

  const _AllocationCard({required this.alloc, required this.showUser});

  @override
  Widget build(BuildContext context) {
    final pct = alloc.usagePercent;
    final progressColor = pct > 0.85
        ? AppColors.error
        : pct > 0.6
            ? AppColors.warning
            : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showUser && alloc.userName != null)
                      Text(alloc.userName!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(alloc.vehiclePlate ?? 'Vehicle',
                        style: TextStyle(
                          color: showUser ? AppColors.textSecondary : AppColors.textPrimary,
                          fontWeight: showUser ? FontWeight.normal : FontWeight.bold,
                          fontSize: showUser ? 13 : 15,
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alloc.monthLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AllocationStat(label: 'Allocated', value: '${alloc.allocatedLiters.toStringAsFixed(0)} L'),
              _AllocationStat(label: 'Used', value: '${alloc.usedLiters.toStringAsFixed(1)} L'),
              _AllocationStat(
                label: 'Remaining',
                value: '${alloc.remainingLiters.toStringAsFixed(1)} L',
                valueColor: progressColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.divider,
              color: progressColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).toStringAsFixed(0)}% used',
            style: TextStyle(fontSize: 11, color: progressColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _AllocationStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _AllocationStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}

class _AllocationDetailsCard extends StatelessWidget {
  final AllocationModel alloc;
  const _AllocationDetailsCard({required this.alloc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Budget Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          const Divider(),
          _DetailRow(
            label: 'Allocated Budget',
            value: 'RWF ${alloc.allocatedAmount.toStringAsFixed(0)}',
          ),
          _DetailRow(
            label: 'Month / Year',
            value: alloc.monthLabel,
          ),
          _DetailRow(
            label: 'Vehicle',
            value: alloc.vehiclePlate ?? '-',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
