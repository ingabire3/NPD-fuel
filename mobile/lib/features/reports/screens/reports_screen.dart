import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

final _reportDataProvider = FutureProvider<List<_DriverReport>>((ref) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();

  final requests = await supabase
      .from('fuel_requests')
      .select('driver_id, requested_liters, expected_fuel, fuel_variance, driver:users!driver_id(name), vehicle:vehicles!vehicle_id(plate_number)')
      .gte('created_at', DateTime(now.year, now.month, 1).toIso8601String())
      .lt('created_at', DateTime(now.year, now.month + 1, 1).toIso8601String())
      .neq('status', 'REJECTED');

  final Map<String, _DriverReport> byDriver = {};

  for (final r in (requests as List)) {
    final driverId = r['driver_id'] as String;
    final name = r['driver']?['name'] as String? ?? 'Unknown';
    final plate = r['vehicle']?['plate_number'] as String? ?? '-';
    final requested = (r['requested_liters'] as num?)?.toDouble() ?? 0;
    final expected = (r['expected_fuel'] as num?)?.toDouble() ?? 0;
    final variance = r['fuel_variance'] as String? ?? 'NORMAL';

    if (!byDriver.containsKey(driverId)) {
      byDriver[driverId] = _DriverReport(
        name: name,
        plate: plate,
        totalRequested: 0,
        totalExpected: 0,
        worstVariance: 'NORMAL',
        requestCount: 0,
      );
    }
    final existing = byDriver[driverId]!;
    byDriver[driverId] = _DriverReport(
      name: existing.name,
      plate: existing.plate,
      totalRequested: existing.totalRequested + requested,
      totalExpected: existing.totalExpected + expected,
      worstVariance: _worstOf(existing.worstVariance, variance),
      requestCount: existing.requestCount + 1,
    );
  }

  final list = byDriver.values.toList();
  list.sort((a, b) => b.deviationPct.abs().compareTo(a.deviationPct.abs()));
  return list;
});

String _worstOf(String a, String b) {
  const order = {'NORMAL': 0, 'WARNING': 1, 'SUSPICIOUS': 2};
  return (order[a] ?? 0) >= (order[b] ?? 0) ? a : b;
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dataAsync = ref.watch(_reportDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Monthly Report — ${monthNames[now.month]} ${now.year}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_reportDataProvider),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No requests this month', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return Column(
            children: [
              _LegendRow(),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(_reportDataProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _ReportRow(report: list[i]),
                  ),
                ),
              ),
              _SummaryFooter(reports: list),
            ],
          );
        },
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Driver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Expected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Actual', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Deviation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final _DriverReport report;
  const _ReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    Color varColor;
    switch (report.worstVariance) {
      case 'SUSPICIOUS': varColor = AppColors.error; break;
      case 'WARNING':    varColor = Colors.orange;   break;
      default:           varColor = AppColors.success;
    }

    final dev = report.deviationPct;
    final devStr = '${dev >= 0 ? '+' : ''}${dev.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(report.plate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${report.totalExpected.toStringAsFixed(0)}L',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text('${report.totalRequested.toStringAsFixed(0)}L',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text(devStr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: report.totalExpected > 0 ? varColor : AppColors.textSecondary,
                )),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: varColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                report.worstVariance,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: varColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  final List<_DriverReport> reports;
  const _SummaryFooter({required this.reports});

  @override
  Widget build(BuildContext context) {
    final totalExpected = reports.fold(0.0, (s, r) => s + r.totalExpected);
    final totalActual = reports.fold(0.0, (s, r) => s + r.totalRequested);
    final suspicious = reports.where((r) => r.worstVariance == 'SUSPICIOUS').length;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FooterStat(label: 'Total Expected', value: '${totalExpected.toStringAsFixed(0)}L'),
          _FooterStat(label: 'Total Used', value: '${totalActual.toStringAsFixed(0)}L'),
          _FooterStat(
            label: 'Flagged',
            value: '$suspicious driver${suspicious == 1 ? '' : 's'}',
            color: suspicious > 0 ? AppColors.error : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _FooterStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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

class _DriverReport {
  final String name;
  final String plate;
  final double totalRequested;
  final double totalExpected;
  final String worstVariance;
  final int requestCount;

  const _DriverReport({
    required this.name,
    required this.plate,
    required this.totalRequested,
    required this.totalExpected,
    required this.worstVariance,
    required this.requestCount,
  });

  double get deviationPct =>
      totalExpected > 0 ? ((totalRequested - totalExpected) / totalExpected * 100) : 0;
}
