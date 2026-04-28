import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/receipts_provider.dart';
import '../../../core/constants/app_colors.dart';

class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Receipts')),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 8),
              Text(e.toString()),
              TextButton(
                onPressed: () => ref.invalidate(receiptsListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('No receipts uploaded yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      SizedBox(height: 8),
                      Text(
                        'Receipts appear here after a fuel request is fulfilled and you upload the station receipt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textHint, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(receiptsListProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReceiptTile(receipt: list[i]),
                ),
              ),
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final Map<String, dynamic> receipt;
  const _ReceiptTile({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(receipt['createdAt']);
    final liters = receipt['litersDispensed'] != null
        ? (receipt['litersDispensed'] as num).toDouble()
        : null;
    final amount = receipt['amountPaid'] != null
        ? (receipt['amountPaid'] as num).toDouble()
        : null;
    final station = receipt['stationName'] ?? 'Receipt uploaded';
    final isFlagged = receipt['verificationStatus'] == 'FLAGGED';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isFlagged ? AppColors.errorLight : AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isFlagged ? Icons.warning_amber : Icons.receipt_long,
                color: isFlagged ? AppColors.error : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (liters != null || amount != null)
                    Text(
                      [
                        if (liters != null) '${liters.toStringAsFixed(1)}L',
                        if (amount != null) '${NumberFormat('#,###').format(amount)} RWF',
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    )
                  else
                    const Text('Pending OCR processing',
                        style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('dd MMM').format(createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                if (isFlagged)
                  const Text('Flagged',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
