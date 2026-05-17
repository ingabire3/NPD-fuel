import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_overlay.dart';

final _odometerRecordProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;
  final now = DateTime.now();
  final data = await supabase
      .from('odometer_records')
      .select()
      .eq('user_id', userId)
      .eq('month', now.month)
      .eq('year', now.year)
      .maybeSingle();
  return data as Map<String, dynamic>?;
});

class OdometerScreen extends ConsumerStatefulWidget {
  const OdometerScreen({super.key});

  @override
  ConsumerState<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends ConsumerState<OdometerScreen> {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _picker = ImagePicker();
  XFile? _startImage;
  XFile? _endImage;
  bool _saving = false;

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(XFile file, String label) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${label}_$ts.jpg';
    final bytes = await File(file.path).readAsBytes();
    await supabase.storage
        .from('odometers')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    return supabase.storage.from('odometers').getPublicUrl(path);
  }

  Future<void> _save(Map<String, dynamic>? existing) async {
    final startVal = double.tryParse(_startCtrl.text);
    final endVal = _endCtrl.text.isNotEmpty ? double.tryParse(_endCtrl.text) : null;

    if (startVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter start odometer reading')),
      );
      return;
    }
    if (endVal != null && endVal < startVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End reading must be ≥ start reading')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final now = DateTime.now();

      String? startImageUrl;
      String? endImageUrl;
      if (_startImage != null) startImageUrl = await _uploadImage(_startImage!, 'start');
      if (_endImage != null) endImageUrl = await _uploadImage(_endImage!, 'end');

      final vehicleData = await supabase
          .from('vehicles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      final vehicleId = vehicleData?['id'] as String?;

      final payload = <String, dynamic>{
        'user_id': userId,
        'month': now.month,
        'year': now.year,
        'start_reading': startVal,
        if (endVal != null) 'end_reading': endVal,
        if (startImageUrl != null) 'start_image_url': startImageUrl,
        if (endImageUrl != null) 'end_image_url': endImageUrl,
        if (vehicleId != null) 'vehicle_id': vehicleId,
      };

      if (existing == null) {
        await supabase.from('odometer_records').insert(payload);
      } else {
        await supabase.from('odometer_records').update(payload).eq('id', existing['id']);
      }

      if (!mounted) return;
      ref.invalidate(_odometerRecordProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Odometer readings saved'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pick(bool isStart) async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1280);
    if (file != null) setState(() => isStart ? _startImage = file : _endImage = file);
  }

  @override
  Widget build(BuildContext context) {
    final recordAsync = ref.watch(_odometerRecordProvider);
    final now = DateTime.now();
    final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthLabel = '${monthNames[now.month]} ${now.year}';

    return recordAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (existing) {
        if (existing != null) {
          _startCtrl.text = existing['start_reading']?.toString() ?? '';
          _endCtrl.text = existing['end_reading']?.toString() ?? '';
        }

        final startReading = (existing?['start_reading'] as num?)?.toDouble();
        final endReading = (existing?['end_reading'] as num?)?.toDouble();
        final distance = (startReading != null && endReading != null)
            ? endReading - startReading
            : null;

        return LoadingOverlay(
          isLoading: _saving,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.go('/allocations')),
              title: Text('Odometer — $monthLabel'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (distance != null)
                    _SummaryCard(distance: distance, startReading: startReading!, endReading: endReading!),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Start of Month', icon: Icons.flag_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _startCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Start Odometer (km)',
                      prefixIcon: Icon(Icons.speed_outlined),
                      suffixText: 'km',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ImagePicker(
                    label: 'Start Photo',
                    image: _startImage,
                    existingUrl: existing?['start_image_url'] as String?,
                    onPick: () => _pick(true),
                    onRemove: () => setState(() => _startImage = null),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(title: 'End of Month', icon: Icons.sports_score_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _endCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'End Odometer (km) — optional until month end',
                      prefixIcon: Icon(Icons.speed),
                      suffixText: 'km',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ImagePicker(
                    label: 'End Photo',
                    image: _endImage,
                    existingUrl: existing?['end_image_url'] as String?,
                    onPick: () => _pick(false),
                    onRemove: () => setState(() => _endImage = null),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(existing),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(existing == null ? 'Save Readings' : 'Update Readings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double distance;
  final double startReading;
  final double endReading;
  const _SummaryCard({required this.distance, required this.startReading, required this.endReading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Start', value: '${startReading.toStringAsFixed(0)} km'),
          _Stat(label: 'End', value: '${endReading.toStringAsFixed(0)} km'),
          _Stat(label: 'Distance', value: '${distance.toStringAsFixed(0)} km', bold: true),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Stat({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.primary,
            )),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final String label;
  final XFile? image;
  final String? existingUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _ImagePicker({
    required this.label,
    required this.image,
    required this.existingUrl,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    Widget? preview;
    if (image != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(image!.path), height: 100, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (existingUrl != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(existingUrl!, height: 100, width: double.infinity, fit: BoxFit.cover),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preview != null) ...[
          preview,
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: Text(preview != null ? 'Retake $label' : 'Photo: $label'),
              ),
            ),
            if (image != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, color: AppColors.error),
                tooltip: 'Remove',
              ),
            ],
          ],
        ),
      ],
    );
  }
}
