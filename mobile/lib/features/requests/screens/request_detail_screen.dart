import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/requests_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/fuel_request_model.dart';
import '../../../core/widgets/status_badge.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String id;
  const RequestDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestDetailProvider(id));
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/requests')),
        title: const Text('Request Detail'),
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (request) => _DetailBody(request: request, user: user),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  final FuelRequestModel request;
  final dynamic user;
  const _DetailBody({required this.request, required this.user});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  final _rejectionCtrl = TextEditingController();
  bool _isActing = false;

  @override
  void dispose() {
    _rejectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() => _isActing = true);
    try {
      await ref.read(requestsRepositoryProvider).approveRequest(widget.request.id);
      if (!mounted) return;
      ref.invalidate(requestDetailProvider(widget.request.id));
      ref.invalidate(requestsListProvider);
      ref.invalidate(dashboardStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _reject() async {
    final reason = _rejectionCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter rejection reason')),
      );
      return;
    }
    setState(() => _isActing = true);
    try {
      await ref.read(requestsRepositoryProvider).rejectRequest(widget.request.id, reason);
      if (!mounted) return;
      ref.invalidate(requestDetailProvider(widget.request.id));
      ref.invalidate(requestsListProvider);
      ref.invalidate(dashboardStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected'), backgroundColor: AppColors.warning),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _fulfill() async {
    // Ask for odometer after reading
    final odometerCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Fulfilled'),
        content: TextField(
          controller: odometerCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Odometer after refuel (km)',
            suffixText: 'km',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final odo = double.tryParse(odometerCtrl.text);
    if (odo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid odometer reading')),
      );
      return;
    }

    setState(() => _isActing = true);
    try {
      await ref.read(requestsRepositoryProvider).fulfillRequest(widget.request.id, odo);
      if (!mounted) return;
      ref.invalidate(requestDetailProvider(widget.request.id));
      ref.invalidate(requestsListProvider);
      ref.invalidate(dashboardStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as fulfilled'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final user = widget.user;
    final canApproveReject =
        req.status == 'PENDING' && (user?.isSuperAdmin == true || user?.isFinance == true);
    final canFulfill =
        req.status == 'APPROVED' && (user?.isSuperAdmin == true || user?.isManager == true);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.vehiclePlate ?? req.vehicleId,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        if (req.driverName != null)
                          Text('by ${req.driverName}',
                              style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge(status: req.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (req.fuelVariance != null && req.expectedFuel != null)
            _AiAnalysisCard(request: req),
          if (req.fuelVariance != null && req.expectedFuel != null)
            const SizedBox(height: 12),
          _InfoCard(children: [
            _InfoRow(label: 'Purpose', value: req.purpose),
            _InfoRow(
                label: 'Requested',
                value: '${req.requestedLiters.toStringAsFixed(1)} L'),
            if (req.odometerBefore != null)
              _InfoRow(
                  label: 'Odometer (before)',
                  value: '${req.odometerBefore!.toStringAsFixed(0)} km'),
            if (req.odometerAfter != null)
              _InfoRow(
                  label: 'Odometer (after)',
                  value: '${req.odometerAfter!.toStringAsFixed(0)} km'),
            _InfoRow(
                label: 'Submitted',
                value: DateFormat('dd MMM yyyy, HH:mm').format(req.createdAt)),
            if (req.approvedAt != null)
              _InfoRow(
                  label: 'Approved',
                  value: DateFormat('dd MMM yyyy, HH:mm').format(req.approvedAt!)),
            if (req.fulfilledAt != null)
              _InfoRow(
                  label: 'Fulfilled',
                  value: DateFormat('dd MMM yyyy, HH:mm').format(req.fulfilledAt!)),
            if (req.rejectionReason != null)
              _InfoRow(
                  label: 'Rejection',
                  value: req.rejectionReason!,
                  valueColor: AppColors.error),
          ]),
          if (canApproveReject) ...[
            const SizedBox(height: 16),
            Text('Finance Action', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rejectionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (required only when rejecting)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: _isActing ? null : _approve,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: _isActing ? null : _reject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
          if (canFulfill) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: _isActing ? null : _fulfill,
              icon: const Icon(Icons.local_gas_station),
              label: const Text('Mark as Fulfilled'),
            ),
          ],
          // Upload receipt button for fulfilled requests
          if (req.status == 'FULFILLED' &&
              (user?.isDriver == true || user?.isSuperAdmin == true)) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/receipts/upload/${req.id}'),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Receipt'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiAnalysisCard extends StatelessWidget {
  final FuelRequestModel request;
  const _AiAnalysisCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final variance = request.fuelVariance ?? 'FAIR';
    final expected = request.expectedFuel ?? 0;
    final requested = request.requestedLiters;
    final deviation = expected > 0 ? ((requested - expected) / expected * 100) : 0.0;

    Color color;
    IconData icon;
    switch (variance) {
      case 'SUSPICIOUS':
        color = AppColors.error;
        icon = Icons.warning_rounded;
        break;
      case 'WARNING':
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = AppColors.success;
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Analysis — $variance',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AnalysisStat(label: 'Expected', value: '${expected.toStringAsFixed(1)} L'),
              _AnalysisStat(label: 'Requested', value: '${requested.toStringAsFixed(1)} L'),
              _AnalysisStat(
                label: 'Deviation',
                value: '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}%',
                color: color,
              ),
            ],
          ),
          if (request.estimatedDistance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Based on ${request.estimatedDistance!.toStringAsFixed(1)} km round trip',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnalysisStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _AnalysisStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
