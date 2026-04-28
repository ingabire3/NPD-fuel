import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vehicle_model.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(child: Text('No vehicles registered'));
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(vehiclesListProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VehicleCard(vehicle: vehicles[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, WidgetRef ref) {
    final plateCtrl = TextEditingController();
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    final tankCtrl = TextEditingController();
    final kmCtrl = TextEditingController();
    String fuelType = 'DIESEL';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Vehicle'),
          scrollable: true,
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(ctrl: plateCtrl, label: 'Plate Number'),
                const SizedBox(height: 12),
                _DialogField(ctrl: makeCtrl, label: 'Make (e.g. Toyota)'),
                const SizedBox(height: 12),
                _DialogField(ctrl: modelCtrl, label: 'Model (e.g. Land Cruiser)'),
                const SizedBox(height: 12),
                _DialogField(ctrl: yearCtrl, label: 'Year', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: fuelType,
                  decoration: const InputDecoration(labelText: 'Fuel Type', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                    DropdownMenuItem(value: 'PETROL', child: Text('Petrol')),
                  ],
                  onChanged: (v) => setLocal(() => fuelType = v!),
                ),
                const SizedBox(height: 12),
                _DialogField(ctrl: tankCtrl, label: 'Tank Capacity (L)', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _DialogField(ctrl: kmCtrl, label: 'Avg km/L (optional)', keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (plateCtrl.text.isEmpty || makeCtrl.text.isEmpty || modelCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plate, make, and model are required')),
                        );
                        return;
                      }
                      setLocal(() => isSubmitting = true);
                      try {
                        await ref.read(vehicleActionProvider.notifier).create(
                              plateNumber: plateCtrl.text.trim().toUpperCase(),
                              make: makeCtrl.text.trim(),
                              model: modelCtrl.text.trim(),
                              year: int.tryParse(yearCtrl.text) ?? DateTime.now().year,
                              fuelType: fuelType,
                              tankCapacity: double.tryParse(tankCtrl.text) ?? 60,
                              averageKmPerL: double.tryParse(kmCtrl.text) ?? 0,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vehicle added successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setLocal(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceFirst('Exception: ', '')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.plateNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${vehicle.make} ${vehicle.model} (${vehicle.year})',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(label: vehicle.fuelType, color: AppColors.primary),
                    const SizedBox(width: 6),
                    _Chip(label: '${vehicle.tankCapacity.toStringAsFixed(0)}L tank', color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (vehicle.assignedDriverName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vehicle.assignedDriverName!.split(' ').first,
                    style: const TextStyle(fontSize: 11, color: AppColors.success),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _showAssignDialog(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Assign',
                        style: TextStyle(fontSize: 11, color: AppColors.warning)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref) {
    String? selectedDriverId;
    final driversAsync = ref.read(driversListProvider);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign Driver'),
        content: driversAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (drivers) => StatefulBuilder(
            builder: (ctx, setLocal) => DropdownButtonFormField<String>(
              value: selectedDriverId,
              hint: const Text('Select driver'),
              items: drivers
                  .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                  .toList(),
              onChanged: (v) => setLocal(() => selectedDriverId = v),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (selectedDriverId != null) {
                ref.read(vehicleActionProvider.notifier).assignDriver(vehicle.id, selectedDriverId!);
                Navigator.pop(context);
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboardType;
  const _DialogField({required this.ctrl, required this.label, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
