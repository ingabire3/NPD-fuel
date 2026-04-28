import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/receipts_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/loading_overlay.dart';

class UploadReceiptScreen extends ConsumerStatefulWidget {
  final String requestId;
  const UploadReceiptScreen({super.key, required this.requestId});

  @override
  ConsumerState<UploadReceiptScreen> createState() => _UploadReceiptScreenState();
}

class _UploadReceiptScreenState extends ConsumerState<UploadReceiptScreen> {
  File? _image;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a receipt photo')),
      );
      return;
    }

    final success = await ref.read(uploadReceiptProvider.notifier).upload(
          requestId: widget.requestId,
          filePath: _image!.path,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt uploaded! AI will process it shortly.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/receipts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadReceiptProvider);

    ref.listen(uploadReceiptProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/receipts')),
          title: const Text('Upload Receipt'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Our AI will automatically extract station name, liters, and amount from the photo.',
                        style: TextStyle(color: AppColors.info, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Image picker
              GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _image != null ? AppColors.success : AppColors.divider,
                      width: _image != null ? 2 : 1,
                    ),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 56, color: AppColors.textHint),
                            SizedBox(height: 12),
                            Text('Tap to add receipt photo',
                                style: TextStyle(
                                    fontSize: 16, color: AppColors.textSecondary)),
                            SizedBox(height: 4),
                            Text('Take a clear photo of the fuel receipt',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textHint)),
                          ],
                        ),
                ),
              ),
              if (_image != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showImagePicker,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Change Photo'),
                ),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : _submit,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Receipt'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
