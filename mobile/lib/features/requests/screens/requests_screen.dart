import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/requests_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/fuel_request_model.dart';
import '../../../core/widgets/status_badge.dart';
import 'package:intl/intl.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  String? _statusFilter;
  final _tabs = ['All', 'Pending', 'Approved', 'Fulfilled', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final requestsAsync = ref.watch(requestsListProvider(_statusFilter));
    final canCreate = user?.isDriver == true || user?.isSuperAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Requests'),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Request'),
              onPressed: () => context.go('/requests/new'),
            )
          : null,
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final tab = _tabs[i];
                final value = i == 0 ? null : tab.toUpperCase();
                final selected = _statusFilter == value;
                return FilterChip(
                  label: Text(tab),
                  selected: selected,
                  onSelected: (_) => setState(() => _statusFilter = value),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                );
              },
            ),
          ),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 8),
                    Text(e.toString()),
                    TextButton(
                      onPressed: () => ref.invalidate(requestsListProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_gas_station_outlined,
                              size: 64, color: AppColors.textHint),
                          SizedBox(height: 8),
                          Text('No requests found', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(requestsListProvider(_statusFilter).future),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _RequestTile(request: list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FuelRequestModel request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/requests/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.vehiclePlate ?? request.vehicleId,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(request.purpose, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text('${request.requestedLiters.toStringAsFixed(0)}L requested',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM, HH:mm').format(request.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
              if (request.driverName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(request.driverName!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
