import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/requests_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_overlay.dart';

final _vehiclesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(apiClientProvider);
  final data = await supabase.from('vehicles').select().eq('is_active', true).order('plate_number');
  return (data as List).map((v) => {
        'id': v['id'] as String,
        'plate': v['plate_number'] as String,
        'display': '${v['plate_number']} — ${v['make']} ${v['model']}',
      }).toList();
});

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  String? _selectedVehicleId;
  XFile? _odometerImage;
  bool _uploadingImage = false;
  final _picker = ImagePicker();

  // Estimation state
  double? _recommendedLiters;
  double? _estimatedDistanceKm;
  bool _loadingEstimate = false;

  @override
  void initState() {
    super.initState();
    _litersCtrl.addListener(_onLitersChanged);
  }

  @override
  void dispose() {
    _litersCtrl.removeListener(_onLitersChanged);
    _litersCtrl.dispose();
    _purposeCtrl.dispose();
    _odometerCtrl.dispose();
    super.dispose();
  }

  void _onLitersChanged() => setState(() {});

  Future<void> _loadEstimation(String vehicleId) async {
    setState(() {
      _loadingEstimate = true;
      _recommendedLiters = null;
      _estimatedDistanceKm = null;
    });
    final estimate = await ref.read(requestsRepositoryProvider).getEstimate(vehicleId);
    if (mounted) {
      setState(() {
        _loadingEstimate = false;
        if (estimate != null) {
          _recommendedLiters = (estimate['expectedFuel'] as num?)?.toDouble();
          _estimatedDistanceKm = (estimate['distanceKm'] as num?)?.toDouble();
        }
      });
    }
  }

  // Returns color based on how much the entered liters deviates from recommendation
  Color _varianceColor() {
    if (_recommendedLiters == null) return AppColors.info;
    final entered = double.tryParse(_litersCtrl.text) ?? 0;
    if (entered == 0) return AppColors.info;
    final ratio = entered / _recommendedLiters!;
    if (ratio <= 1.2) return Colors.green;
    if (ratio <= 1.5) return Colors.orange;
    return AppColors.error;
  }

  String _varianceLabel() {
    if (_recommendedLiters == null) return '';
    final entered = double.tryParse(_litersCtrl.text) ?? 0;
    if (entered == 0) return '';
    final ratio = entered / _recommendedLiters!;
    if (ratio <= 1.2) return 'Within expected range';
    if (ratio <= 1.5) return 'Slightly above expected — will be noted';
    return 'Significantly above expected — will be flagged for review';
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (file != null) setState(() => _odometerImage = file);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    String? imageUrl;
    if (_odometerImage != null) {
      setState(() => _uploadingImage = true);
      try {
        imageUrl = await ref
            .read(requestsRepositoryProvider)
            .uploadOdometerImage(_odometerImage!.path);
      } catch (_) {
        // Non-blocking — continue without image if upload fails
      } finally {
        if (mounted) setState(() => _uploadingImage = false);
      }
    }

    final result = await ref.read(createRequestProvider.notifier).submit(
          vehicleId: _selectedVehicleId!,
          liters: double.parse(_litersCtrl.text),
          purpose: _purposeCtrl.text.trim(),
          odometerBefore: double.parse(_odometerCtrl.text),
          odometerImageUrl: imageUrl,
        );

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/requests');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRequestProvider);
    final vehiclesAsync = ref.watch(_vehiclesProvider);
    final isLoading = state.isLoading || _uploadingImage;

    ref.listen(createRequestProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/requests')),
          title: const Text('New Fuel Request'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                vehiclesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load vehicles: $e',
                      style: const TextStyle(color: AppColors.error)),
                  data: (vehicles) => DropdownButtonFormField<String>(
                    value: _selectedVehicleId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select vehicle',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                    items: vehicles
                        .map((v) => DropdownMenuItem<String>(
                              value: v['id'],
                              child: Text(v['display'], overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedVehicleId = v);
                      if (v != null) _loadEstimation(v);
                    },
                    validator: (v) => v == null ? 'Select a vehicle' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Fuel Estimation Card ──────────────────────────
                if (_loadingEstimate)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Calculating recommendation...'),
                      ],
                    ),
                  ),

                if (!_loadingEstimate && _recommendedLiters != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.info.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_gas_station_outlined,
                            color: AppColors.info, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended: ${_recommendedLiters!.toStringAsFixed(1)}L',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.info,
                                ),
                              ),
                              if (_estimatedDistanceKm != null)
                                Text(
                                  'Based on ${_estimatedDistanceKm!.toStringAsFixed(1)}km round trip',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // ─────────────────────────────────────────────────

                TextFormField(
                  controller: _litersCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  decoration: const InputDecoration(
                    labelText: 'Requested Liters',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                    suffixText: 'L',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter valid liters';
                    if (n > 200) return 'Max 200L per request';
                    return null;
                  },
                ),

                // ── Variance warning below liters field ──────────
                if (_recommendedLiters != null && _litersCtrl.text.isNotEmpty)
                  Builder(builder: (_) {
                    final label = _varianceLabel();
                    if (label.isEmpty) return const SizedBox.shrink();
                    final color = _varianceColor();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          Icon(
                            color == Colors.green
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(fontSize: 12, color: color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                // ─────────────────────────────────────────────────

                const SizedBox(height: 16),
                TextFormField(
                  controller: _odometerCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Current Odometer (km)',
                    prefixIcon: Icon(Icons.speed_outlined),
                    suffixText: 'km',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 0) return 'Enter valid reading';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Odometer Photo (Optional)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_odometerImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_odometerImage!.path),
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                      ),
                    ),
                    if (_odometerImage != null) ...[
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => setState(() => _odometerImage = null),
                        icon: const Icon(Icons.close, color: AppColors.error),
                        tooltip: 'Remove photo',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purposeCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Purpose / Trip Description',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 10) return 'Be more descriptive (min 10 chars)';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: const Text('Submit Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
