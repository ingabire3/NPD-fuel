import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/allocations_provider.dart';
import '../../admin/providers/admin_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_overlay.dart';

class CreateAllocationScreen extends ConsumerStatefulWidget {
  const CreateAllocationScreen({super.key});

  @override
  ConsumerState<CreateAllocationScreen> createState() => _CreateAllocationScreenState();
}

class _CreateAllocationScreenState extends ConsumerState<CreateAllocationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUserId;
  String? _selectedVehicleId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final _litersCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void dispose() {
    _litersCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null || _selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select driver and vehicle')),
      );
      return;
    }
    ref.read(createAllocationProvider.notifier).create(
          userId: _selectedUserId!,
          vehicleId: _selectedVehicleId!,
          month: _selectedMonth,
          year: _selectedYear,
          allocatedLiters: double.parse(_litersCtrl.text),
          allocatedAmount: double.parse(_amountCtrl.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createAllocationProvider);
    final driversAsync = ref.watch(driversListProvider);
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    ref.listen(createAllocationProvider, (_, next) {
      if (next.success) {
        ref.invalidate(allocationsListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allocation created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Create Allocation')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Driver'),
                const SizedBox(height: 8),
                driversAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (drivers) => DropdownButtonFormField<String>(
                    value: _selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Select Driver',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    items: drivers
                        .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUserId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel('Vehicle'),
                const SizedBox(height: 8),
                vehiclesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (vehicles) => DropdownButtonFormField<String>(
                    value: _selectedVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Select Vehicle',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                    items: vehicles
                        .map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text('${v.plateNumber} — ${v.make} ${v.model}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedVehicleId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionLabel('Period'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(labelText: 'Month'),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i])),
                        ),
                        onChanged: (v) => setState(() => _selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(labelText: 'Year'),
                        items: [2024, 2025, 2026, 2027]
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel('Allocation'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _litersCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Allocated Liters',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                    suffixText: 'L',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter valid liters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount (RWF)',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                    suffixText: 'RWF',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: const Text('Create Allocation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
