import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/anomalies_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/anomaly_model.dart';

class AnomaliesScreen extends ConsumerWidget {
  const AnomaliesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(anomalyStatusFilterProvider);
    final anomaliesAsync = ref.watch(anomaliesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Anomalies'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: filter,
              dropdownColor: AppColors.white,
              underline: const SizedBox(),
              style: const TextStyle(color: AppColors.white, fontSize: 13),
              icon: const Icon(Icons.filter_list, color: AppColors.white, size: 20),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All', style: TextStyle(color: AppColors.textPrimary))),
                DropdownMenuItem(value: 'OPEN', child: Text('Open', style: TextStyle(color: AppColors.textPrimary))),
                DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved', style: TextStyle(color: AppColors.textPrimary))),
              ],
              onChanged: (v) => ref.read(anomalyStatusFilterProvider.notifier).state = v!,
            ),
          ),
        ],
      ),
      body: anomaliesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 64,
                    color: filter == 'OPEN' ? AppColors.success : AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    filter == 'OPEN' ? 'No open anomalies' : 'No anomalies found',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(anomaliesListProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnomalyCard(anomaly: list[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnomalyCard extends ConsumerWidget {
  final AnomalyModel anomaly;
  const _AnomalyCard({required this.anomaly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = anomaly.isOpen;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: isOpen ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.errorLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOpen ? Icons.warning_amber : Icons.check_circle_outline,
                  color: isOpen ? AppColors.error : AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anomaly.type.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (anomaly.userName != null)
                      Text(anomaly.userName!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.errorLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  anomaly.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOpen ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(anomaly.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (!isOpen && anomaly.resolution != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      anomaly.resolution!,
                      style: const TextStyle(fontSize: 12, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isOpen) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () => _showResolveDialog(context, ref),
                    child: const Text('Resolve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: () => _showEscalateDialog(context),
                    child: const Text('Escalate'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resolve Anomaly'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter resolution notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(resolveAnomalyProvider.notifier).resolve(anomaly.id, ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showEscalateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escalate to Admin'),
        content: const Text('This anomaly will be flagged for Admin review.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );
  }
}
